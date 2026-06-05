/* Importa CxP unificando 3 boards de Monday → public.cxp. Idempotente por
 * monday_item_id. Deriva estado desde factura/estado de pago. Montos: los
 * formula de Monday salen vacíos, así que se usan los numbers crudos disponibles
 * (Total TTS productores, Total acarreo); servicio_corte guarda kilos (monto se
 * costeará luego con tarifa de cuadrilla).
 *
 *   node scripts/import-cxp.mjs
 */
import { readFileSync } from "node:fs";
import { createClient } from "@supabase/supabase-js";

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n").filter((l) => l.includes("=") && !l.trimStart().startsWith("#"))
    .map((l) => { const i = l.indexOf("="); return [l.slice(0, i).trim(), l.slice(i + 1).trim()]; }),
);
const MONDAY = env.MONDAY_API_TOKEN;
const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);

async function gql(query, variables = {}) {
  const res = await fetch("https://api.monday.com/v2", {
    method: "POST",
    headers: { Authorization: MONDAY, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const j = await res.json();
  if (j.errors) throw new Error(JSON.stringify(j.errors));
  return j.data;
}
async function fetchBoard(boardId, colIds) {
  // ... on FormulaValue { display_value } expone el valor calculado de fórmulas.
  const frag = `id name column_values(ids:[${colIds.map((c) => `"${c}"`).join(",")}]){ id text ... on FormulaValue { display_value } }`;
  const items = [];
  let page = await gql(`{ boards(ids:[${boardId}]){ items_page(limit:100){ cursor items{ ${frag} } } } }`);
  let { cursor, items: batch } = page.boards[0].items_page;
  items.push(...batch);
  while (cursor) {
    page = await gql(`query($c:String!){ next_items_page(limit:100, cursor:$c){ cursor items{ ${frag} } } }`, { c: cursor });
    cursor = page.next_items_page.cursor;
    items.push(...page.next_items_page.items);
  }
  return items;
}
const num = (s) => { if (s == null || s === "") return null; const v = Number(String(s).replace(/,/g, "")); return Number.isFinite(v) ? v : null; };
const txt = (s) => (s && s.trim() ? s.trim() : null);
function semanaISO(iso) {
  if (!iso) return null;
  const d = new Date(iso + "T00:00:00Z");
  const day = (d.getUTCDay() + 6) % 7; d.setUTCDate(d.getUTCDate() - day + 3);
  const ft = new Date(Date.UTC(d.getUTCFullYear(), 0, 4)); const fd = (ft.getUTCDay() + 6) % 7;
  ft.setUTCDate(ft.getUTCDate() - fd + 3);
  return 1 + Math.round((d - ft) / (7 * 864e5));
}
/** Deriva el estado CxP. El candado: sin factura nunca llega a pagada. */
function derivaEstado(factura, estadoPago) {
  if (estadoPago && /realizado/i.test(estadoPago)) return factura ? "pagada" : "validada";
  if (factura) return "validada";
  return "borrador";
}
// Prefiere display_value (fórmulas) sobre text.
const v = (it, map) =>
  Object.fromEntries(it.column_values.map((c) => [map[c.id], c.display_value || c.text]));

async function main() {
  const all = [];

  // ── Productores ─────────────────────────────────────────────────────────
  const Cp = { men__desplegable3: "prod", texto49: "benef", dup__of_productor: "huerta", texto: "lote",
    fecha76: "fecha", n_meros5: "total", texto22: "factura", estado: "epago", estado1: "forma" };
  for (const it of await fetchBoard("4069160674", Object.keys(Cp))) {
    const r = v(it, Cp); const factura = txt(r.factura); const fecha = txt(r.fecha);
    all.push({
      monday_item_id: Number(it.id), origen: "CXP Productores", tipo: "productor",
      beneficiario: txt(r.benef) || txt(r.prod), huerta: txt(r.huerta), lote: txt(r.lote),
      orden_compra: null, fecha, semana: semanaISO(fecha), kilos: null, monto: num(r.total),
      factura, estado: derivaEstado(factura, r.epago), forma_pago: txt(r.forma),
    });
  }

  // ── Servicio de corte ──────────────────────────────────────────────────
  const Cc = { status: "emp", texto: "huerta", dup__of_orden_de_corte_mkm159ma: "lote",
    n_meros1: "kilos", f_rmula44: "subtotal", texto6: "factura", date: "fecha", texto4: "oc" };
  for (const it of await fetchBoard("4330832076", Object.keys(Cc))) {
    const r = v(it, Cc); const factura = txt(r.factura); const fecha = txt(r.fecha);
    all.push({
      monday_item_id: Number(it.id), origen: "Servicios de corte", tipo: "servicio_corte",
      beneficiario: txt(r.emp), huerta: txt(r.huerta), lote: txt(r.lote), orden_compra: txt(r.oc),
      fecha, semana: semanaISO(fecha), kilos: num(r.kilos), monto: num(r.subtotal), // Subtotal (formula) vía display_value
      factura, estado: derivaEstado(factura, null), forma_pago: null,
    });
  }

  // ── Acarreo ─────────────────────────────────────────────────────────────
  const Ca = { label: "prov", texto: "huerta", numeric_mm34gvmk: "total", texto65: "factura", date: "fecha", texto2: "oc" };
  for (const it of await fetchBoard("4345330832", Object.keys(Ca))) {
    const r = v(it, Ca); const factura = txt(r.factura); const fecha = txt(r.fecha);
    all.push({
      monday_item_id: Number(it.id), origen: "Servicios de acarreo", tipo: "acarreo",
      beneficiario: txt(r.prov), huerta: txt(r.huerta), lote: null, orden_compra: txt(r.oc),
      fecha, semana: semanaISO(fecha), kilos: null, monto: num(r.total),
      factura, estado: derivaEstado(factura, null), forma_pago: null,
    });
  }

  for (let i = 0; i < all.length; i += 500) {
    const { error } = await supabase.from("cxp").upsert(all.slice(i, i + 500), { onConflict: "monday_item_id" });
    if (error) throw new Error(`upsert cxp: ${error.message}`);
  }

  const porTipo = all.reduce((a, r) => ((a[r.tipo] = (a[r.tipo] || 0) + 1), a), {});
  const sinFactura = all.filter((r) => !r.factura).length;
  console.log(`✓ ${all.length} obligaciones · por tipo:`, porTipo, `· ${sinFactura} sin factura (bloqueadas)`);
}
main().catch((e) => { console.error(e); process.exit(1); });
