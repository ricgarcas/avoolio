/* Importa los cortes desde "Bitácora de corte (RE-ACO-03)" (Monday 4077387130)
 * hacia public.corte. Idempotente por monday_item_id. Reversible: truncate.
 *
 *   node scripts/import-cortes.mjs
 */
import { readFileSync } from "node:fs";
import { createClient } from "@supabase/supabase-js";

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
const supabase = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY);
const BOARD = "4077387130";

// id de columna Monday → campo destino
const MAP = {
  date: "programado",
  dup__of_rg1__1: "huerto",
  texto7: "productor",
  dup__of_productor__1: "municipio",
  text_mm1kvxvt: "asnm",
  estado__1: "tipo_corte",
  dup__of_rg1_mkm05726: "floracion",
  men__desplegable_mkm1gwqr: "camion",
  status: "acopio",
  dup__of_municipio__1: "bascula",
  dup__of_bascula__1: "punto_reunion",
  estado_mkm0p748: "empresa_corte",
  n_meros3__1: "precio_pactado",
  estado_mkm1j2mq: "estado",
  color_mkzje1aj: "visita1",
  color_mkzjgdgk: "visita2",
};
const COLS = Object.keys(MAP);
const FRAG = `id column_values(ids:[${COLS.map((c) => `"${c}"`).join(",")}]){ id text }`;

const ESTADO = {
  Registrado: "registrado",
  "En espera": "en_espera",
  Confirmado: "confirmado",
  Cancelado: "cancelado",
};

/** Semana ISO 8601 a partir de una fecha YYYY-MM-DD. */
function semanaISO(iso) {
  if (!iso) return null;
  const d = new Date(iso + "T00:00:00Z");
  const day = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - day + 3);
  const firstThursday = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  const fday = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - fday + 3);
  return 1 + Math.round((d - firstThursday) / (7 * 864e5));
}

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

async function fetchAll() {
  const items = [];
  let page = await gql(`{ boards(ids:[${BOARD}]){ items_page(limit:100){ cursor items{ ${FRAG} } } } }`);
  let { cursor, items: batch } = page.boards[0].items_page;
  items.push(...batch);
  while (cursor) {
    page = await gql(`query($c:String!){ next_items_page(limit:100, cursor:$c){ cursor items{ ${FRAG} } } }`, { c: cursor });
    cursor = page.next_items_page.cursor;
    items.push(...page.next_items_page.items);
  }
  return items;
}

const intOrNull = (s) => {
  if (!s) return null;
  const m = String(s).match(/-?\d+/);
  return m ? parseInt(m[0], 10) : null;
};

async function main() {
  console.log("Jalando Bitácora de corte…");
  const items = await fetchAll();
  console.log(`  ${items.length} cortes`);

  const rows = items.map((it) => {
    const v = Object.fromEntries(it.column_values.map((c) => [MAP[c.id], (c.text || "").trim()]));
    const programado = v.programado || null;
    return {
      monday_item_id: Number(it.id),
      programado,
      semana: semanaISO(programado),
      huerto: v.huerto || "(sin nombre)",
      productor: v.productor || null,
      municipio: v.municipio || null,
      asnm: intOrNull(v.asnm),
      tipo_corte: v.tipo_corte || null,
      floracion: v.floracion || null,
      camion: v.camion || null,
      acopio: v.acopio || null,
      bascula: v.bascula || null,
      punto_reunion: v.punto_reunion || null,
      empresa_corte: v.empresa_corte || null,
      precio_pactado: v.precio_pactado ? Number(v.precio_pactado) : null,
      estado: ESTADO[v.estado] || "registrado",
      visita1: v.visita1 || null,
      visita2: v.visita2 || null,
    };
  });

  for (let i = 0; i < rows.length; i += 500) {
    const chunk = rows.slice(i, i + 500);
    const { error } = await supabase.from("corte").upsert(chunk, { onConflict: "monday_item_id" });
    if (error) throw new Error(`upsert corte: ${error.message}`);
  }

  const conAlerta = rows.filter((r) => r.asnm != null && r.asnm < 2100).length;
  const porEstado = rows.reduce((a, r) => ((a[r.estado] = (a[r.estado] || 0) + 1), a), {});
  console.log(`✓ ${rows.length} cortes · ${conAlerta} con alerta de altura · por estado:`, porEstado);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
