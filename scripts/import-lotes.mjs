/* Importa el núcleo del acopio desde Monday hacia public:
 *   resultado_lote   ← "Análisis Lotes Acopio"      (8332495640)
 *   lote_fuera_norma ← "Análisis Lotes Fuera Norma" (9148689798)
 *   precio_calc      ← "Calculadora Precio Fruta"   (9414707454)
 * Idempotente por monday_item_id. Fórmulas de Monday recomputadas en código.
 *
 *   node scripts/import-lotes.mjs
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

const num = (s) => {
  if (s == null || s === "") return null;
  const v = Number(String(s).replace(/,/g, ""));
  return Number.isFinite(v) ? v : null;
};
const txt = (s) => (s && s.trim() ? s.trim() : null);
function semanaISO(iso) {
  if (!iso) return null;
  const d = new Date(iso + "T00:00:00Z");
  const day = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - day + 3);
  const ft = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  const fd = (ft.getUTCDay() + 6) % 7;
  ft.setUTCDate(ft.getUTCDate() - fd + 3);
  return 1 + Math.round((d - ft) / (7 * 864e5));
}
const roundup = (v, dec = 2) => { const f = 10 ** dec; return Math.ceil(v * f) / f; };

async function upsert(table, rows, onConflict = "monday_item_id") {
  for (let i = 0; i < rows.length; i += 500) {
    const { error } = await supabase.from(table).upsert(rows.slice(i, i + 500), { onConflict });
    if (error) throw new Error(`upsert ${table}: ${error.message}`);
  }
}

async function main() {
  // ── resultado_lote ────────────────────────────────────────────────────────
  console.log("Análisis Lotes Acopio…");
  const C1 = {
    date: "fr", dup__of_fecha_mkmkcqt: "fc", texto_mkmk948t: "huerta", texto_mkmkw8ch: "productor",
    n_meros_mkmkzaz5: "kg", status: "jefe", tipo_de_corte_mkn9xv8g: "tipo",
    n_meros_mkmk6pat: "nac", n_meros_mkmkn67a: "cat1", n_meros_mkmkf56h: "cat2", n_meros_mkmke0k1: "merma",
    ajuste_por_volumen_mkn9escd: "ajv", estado_mkn9exbq: "ajd", estado_mknbf2fk: "aut", estado_mkn9wnjd: "com",
  };
  const a1 = await fetchBoard("8332495640", Object.keys(C1));
  const r1 = a1.map((it) => {
    const v = Object.fromEntries(it.column_values.map((c) => [C1[c.id], c.text]));
    return {
      monday_item_id: Number(it.id), fecha_recepcion: txt(v.fr), fecha_cosecha: txt(v.fc),
      semana: semanaISO(txt(v.fr) || txt(v.fc)), huerta: txt(v.huerta), productor: txt(v.productor),
      kilogramos: num(v.kg), jefe_acopio: txt(v.jefe), tipo_corte: txt(v.tipo),
      nacional: num(v.nac), cat1: num(v.cat1), cat2: num(v.cat2), merma: num(v.merma),
      ajuste_volumen: txt(v.ajv), ajuste_desviacion: txt(v.ajd), autorizado: txt(v.aut), comision: txt(v.com),
    };
  }).filter((r) => r.monday_item_id);
  await upsert("resultado_lote", r1);
  console.log(`  ${r1.length} lotes`);

  // ── lote_fuera_norma ──────────────────────────────────────────────────────
  console.log("Análisis Lotes Fuera Norma…");
  const C2 = {
    date_mkqypy0k: "fc", text_mkqynsae: "huerta", text_mkqys78b: "productor", color_mkr4srw0: "tipo",
    color_mkr4pvz3: "jefe", dropdown_mkr47bjq: "cuad", numeric_mkqy9px: "peso", numeric_mkqybsxj: "kgfn",
    numeric_mkr4n4fc: "pctp", numeric_mkv9tn8n: "pen", numeric_mkr45nnd: "preal", numeric_mkr4xcp0: "pest",
    text_mkr41m1j: "notas", status: "estado",
  };
  const a2 = await fetchBoard("9148689798", Object.keys(C2));
  let seq = 0;
  const r2 = a2.map((it) => {
    const v = Object.fromEntries(it.column_values.map((c) => [C2[c.id], c.text]));
    return {
      monday_item_id: Number(it.id),
      fecha_cosecha: txt(v.fc), semana: semanaISO(txt(v.fc)), huerta: txt(v.huerta), productor: txt(v.productor),
      tipo_corte: txt(v.tipo), jefe_acopio: txt(v.jefe), jefe_cuadrilla: txt(v.cuad),
      peso_neto: num(v.peso), kg_fuera_norma: num(v.kgfn), pct_permitido: num(v.pctp),
      penalizacion_kg: num(v.pen), p_kg_real: num(v.preal), p_kg_estimado: num(v.pest),
      notas: txt(v.notas), estado: txt(v.estado),
    };
  });
  await upsert("lote_fuera_norma", r2);
  console.log(`  ${r2.length} lotes fuera de norma`);

  // ── precio_calc (recomputa precio_pagar_kg) ───────────────────────────────
  console.log("Calculadora Precio Fruta…");
  const C3 = {
    date_mks2cbpb: "fecha", numeric_mks2r0h5: "pv", numeric_mks24497: "util",
    numeric_mks2v79r: "pctc", numeric_mks2tyqv: "rend", numeric_mks2wzps: "tc",
    formula_mks2a7gy: "precio_dv", status: "estado",
  };
  const a3 = await fetchBoard("9414707454", Object.keys(C3));
  const r3 = a3.map((it) => {
    const v = Object.fromEntries(it.column_values.map((c) => [C3[c.id], c.display_value || c.text]));
    const pv = num(v.pv), util = num(v.util), pctc = num(v.pctc), rend = num(v.rend), tc = num(v.tc);
    // Autoritativo: el valor calculado por Monday (display_value). Recompute = respaldo.
    let precio = num(v.precio_dv);
    if (precio == null && pv != null && util != null && pctc != null && rend && tc != null) {
      const antes = pv - pv * (util / 100);
      const costoMax = antes * (pctc / 100);
      const precioMax = roundup(costoMax / rend, 2);
      precio = roundup(precioMax * tc, 2);
    }
    return {
      monday_item_id: Number(it.id), fecha_calculo: txt(v.fecha),
      precio_venta: pv, utilidad: util, porcentaje_costo: pctc, rendimiento: rend, tipo_cambio: tc,
      precio_pagar_kg: precio, estado: txt(v.estado),
    };
  }).filter((r) => r.monday_item_id);
  await upsert("precio_calc", r3);
  console.log(`  ${r3.length} cálculos de precio`);

  console.log("✓ Listo");
}

main().catch((e) => { console.error(e); process.exit(1); });
