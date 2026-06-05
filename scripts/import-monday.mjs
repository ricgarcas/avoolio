/* Importa los catálogos maestros desde Monday.com hacia `public` en Supabase.
 *
 *   node scripts/import-monday.mjs
 *
 * Fuentes (workspace "Tableros colaborativos"):
 *   - productor + huerta  ← board "Catalogo Productores" (5791229454)
 *   - acopiador           ← labels de "Acopio" en Bitácora de corte (4077387130)
 *   - cuadrilla           ← labels de "Empresa de Corte" en Bitácora
 *   - acarreador          ← labels de "Proveedor Fletes" en Servicios de acarreo
 *
 * Idempotente: upsert por clave natural (hue / rfc / nombre). NO importa datos
 * bancarios ni otra PII innecesaria. Reversible: `truncate` de las tablas.
 */
import { readFileSync } from "node:fs";
import { createClient } from "@supabase/supabase-js";

// ── env (.env.local, sin depender de dotenv) ────────────────────────────────
const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n")
    .filter((l) => l.includes("=") && !l.trimStart().startsWith("#"))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    }),
);

const MONDAY = env.MONDAY_API_TOKEN;
const supabase = createClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
);

const PRODUCTORES_BOARD = "5791229454";
const BITACORA_BOARD = "4077387130";
const ACARREO_BOARD = "4345330832";

// ── Monday GraphQL ──────────────────────────────────────────────────────────
async function gql(query, variables = {}) {
  const res = await fetch("https://api.monday.com/v2", {
    method: "POST",
    headers: { Authorization: MONDAY, "Content-Type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const json = await res.json();
  if (json.errors) throw new Error(JSON.stringify(json.errors));
  return json.data;
}

/** Etiquetas (no vacías) de una columna status/dropdown. */
async function labels(boardId, columnId) {
  const d = await gql(
    `{ boards(ids:[${boardId}]){ columns(ids:["${columnId}"]){ settings_str } } }`,
  );
  const s = JSON.parse(d.boards[0].columns[0].settings_str);
  return [...new Set(Object.values(s.labels || {}).filter(Boolean))];
}

const COLS = ["texto", "texto9", "texto6", "tel_fono", "correo_electr_nico", "n_meros", "texto3", "texto5"];
const ITEM_FRAG = `name column_values(ids:[${COLS.map((c) => `"${c}"`).join(",")}]){ id text }`;

/** Pagina los 920 items del catálogo de productores. */
async function fetchProductoresBoard() {
  const items = [];
  let page = await gql(
    `{ boards(ids:[${PRODUCTORES_BOARD}]){ items_page(limit:100){ cursor items{ ${ITEM_FRAG} } } } }`,
  );
  let { cursor, items: batch } = page.boards[0].items_page;
  items.push(...batch);
  while (cursor) {
    page = await gql(
      `query($c:String!){ next_items_page(limit:100, cursor:$c){ cursor items{ ${ITEM_FRAG} } } }`,
      { c: cursor },
    );
    cursor = page.next_items_page.cursor;
    items.push(...page.next_items_page.items);
  }
  return items;
}

const val = (it, id) => (it.column_values.find((c) => c.id === id)?.text || "").trim();
const clean = (s) => (s ? s : null);

// ── main ────────────────────────────────────────────────────────────────────
async function main() {
  console.log("Jalando Catalogo Productores de Monday…");
  const raw = await fetchProductoresBoard();
  console.log(`  ${raw.length} items`);

  // Productores únicos (por RFC; fallback nombre).
  const prodByKey = new Map();
  for (const it of raw) {
    const nombre = val(it, "texto9");
    if (!nombre) continue;
    const rfc = val(it, "texto5") || null;
    const key = rfc || `nombre:${nombre.toUpperCase()}`;
    if (!prodByKey.has(key)) {
      prodByKey.set(key, {
        nombre,
        rfc,
        municipio: clean(val(it, "texto6")),
        tel: clean(val(it, "tel_fono")),
        correo: clean(val(it, "correo_electr_nico")),
        beneficiario: clean(val(it, "texto3")),
        dias_credito: val(it, "n_meros") ? parseInt(val(it, "n_meros"), 10) : null,
      });
    }
  }
  const productores = [...prodByKey.values()];
  const conRfc = productores.filter((p) => p.rfc);
  console.log(`  ${productores.length} productores únicos (${conRfc.length} con RFC)`);

  // Upsert productores con RFC (idempotente); sin RFC se insertan aparte.
  await upsert("productor", conRfc, "rfc");
  const sinRfc = productores.filter((p) => !p.rfc);
  if (sinRfc.length) await insertIgnore("productor", sinRfc);

  // Lookup id por rfc y por nombre para resolver FK de huerta.
  const { data: prodRows } = await supabase.from("productor").select("id,rfc,nombre");
  const byRfc = new Map(prodRows.filter((p) => p.rfc).map((p) => [p.rfc, p.id]));
  const byNombre = new Map(prodRows.map((p) => [p.nombre.toUpperCase(), p.id]));

  // Huertas (item name = HUE).
  const huertas = [];
  const vistos = new Set();
  for (const it of raw) {
    const hue = it.name?.trim();
    const nombre = val(it, "texto");
    if (!hue || !hue.startsWith("HUE") || !nombre || vistos.has(hue)) continue;
    vistos.add(hue);
    const rfc = val(it, "texto5");
    const prodNom = val(it, "texto9");
    huertas.push({
      hue,
      nombre,
      productor_id: byRfc.get(rfc) || byNombre.get(prodNom.toUpperCase()) || null,
      municipio: clean(val(it, "texto6")),
    });
  }
  console.log(`  ${huertas.length} huertas (HUE únicos)`);
  await upsert("huerta", huertas, "hue");

  // Catálogos por etiquetas.
  console.log("Jalando etiquetas (acopiador / cuadrilla / acarreador)…");
  const acopiadores = (await labels(BITACORA_BOARD, "status")).map((n) => ({
    nombre: n,
    estatus: "autorizado",
  }));
  const cuadrillas = (await labels(BITACORA_BOARD, "estado_mkm0p748")).map((n) => ({
    nombre: n,
  }));
  const acarreadores = (await labels(ACARREO_BOARD, "label")).map((n) => ({ nombre: n }));

  await upsert("acopiador", acopiadores, "nombre");
  await upsert("cuadrilla", cuadrillas, "nombre");
  await upsert("acarreador", acarreadores, "nombre");

  console.log(
    `\n✓ Listo: ${conRfc.length + sinRfc.length} productores · ${huertas.length} huertas · ` +
      `${acopiadores.length} acopiadores · ${cuadrillas.length} cuadrillas · ${acarreadores.length} acarreadores`,
  );
}

async function upsert(table, rows, onConflict) {
  for (let i = 0; i < rows.length; i += 500) {
    const chunk = rows.slice(i, i + 500);
    const { error } = await supabase.from(table).upsert(chunk, { onConflict, ignoreDuplicates: false });
    if (error) throw new Error(`upsert ${table}: ${error.message}`);
  }
}

async function insertIgnore(table, rows) {
  const { error } = await supabase.from(table).insert(rows);
  if (error) console.warn(`insert ${table} (sin clave): ${error.message}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
