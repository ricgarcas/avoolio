/* Exploración: mapea tablas enlazadas (connect_boards / mirror / dependency) y
 * dashboards en Monday, para descubrir relaciones importantes. Solo lectura. */
import { readFileSync } from "node:fs";

const env = Object.fromEntries(
  readFileSync(new URL("../.env.local", import.meta.url), "utf8")
    .split("\n").filter((l) => l.includes("=") && !l.trimStart().startsWith("#"))
    .map((l) => { const i = l.indexOf("="); return [l.slice(0, i).trim(), l.slice(i + 1).trim()]; }),
);
const MONDAY = env.MONDAY_API_TOKEN;

async function gql(query) {
  const res = await fetch("https://api.monday.com/v2", {
    method: "POST",
    headers: { Authorization: MONDAY, "Content-Type": "application/json", "API-Version": "2024-10" },
    body: JSON.stringify({ query }),
  });
  const j = await res.json();
  if (j.errors) throw new Error(JSON.stringify(j.errors));
  return j.data;
}

// 1) Todos los boards (id,name) — paginado.
const boards = [];
for (let page = 1; ; page++) {
  const d = await gql(`{ boards(limit:100, page:${page}, state:active){ id name board_kind items_count workspace{ name } } }`);
  if (!d.boards.length) break;
  boards.push(...d.boards);
  if (d.boards.length < 100) break;
}
const real = boards.filter((b) => !b.name.startsWith("Subelementos") && b.board_kind !== "subitems");
const nameById = Object.fromEntries(boards.map((b) => [b.id, b.name]));
console.log(`Boards activos: ${boards.length} (no-subitem: ${real.length})\n`);

// 2) Columnas relacionales por board (en lotes).
const REL = new Set(["board_relation", "mirror", "dependency"]);
const links = [];
for (let i = 0; i < real.length; i += 10) {
  const ids = real.slice(i, i + 10).map((b) => b.id).join(",");
  const d = await gql(`{ boards(ids:[${ids}]){ id name columns{ id title type settings_str } } }`);
  for (const b of d.boards) {
    for (const c of b.columns) {
      if (!REL.has(c.type)) continue;
      let targets = [];
      try {
        const s = JSON.parse(c.settings_str || "{}");
        const tids = s.boardIds || s.boards_ids || (s.boardId ? [s.boardId] : []);
        targets = (tids || []).map((t) => nameById[t] || `#${t}`);
      } catch {}
      links.push({ board: b.name, col: c.title, type: c.type, targets });
    }
  }
}

console.log("=== TABLAS ENLAZADAS (connect / mirror / dependency) ===");
const byBoard = {};
for (const l of links) (byBoard[l.board] ||= []).push(l);
for (const [board, ls] of Object.entries(byBoard)) {
  console.log(`\n▸ ${board}`);
  for (const l of ls) {
    const tag = l.type === "mirror" ? "mirror" : l.type === "dependency" ? "dep" : "→";
    console.log(`    ${tag} "${l.col}"  ${l.targets.length ? "⟶ " + l.targets.join(", ") : ""}`);
  }
}

// 3) Dashboards (best-effort).
console.log("\n=== DASHBOARDS ===");
try {
  const d = await gql(`{ docs(limit:1){ id } }`); // calienta
  const dd = await gql(`{ dashboards(limit:50){ id name workspace_id } }`);
  for (const x of dd.dashboards || []) console.log(`  ${x.id}  ${x.name}`);
} catch (e) {
  console.log("  (la API no expone dashboards directamente:", String(e).slice(0, 80), ")");
}
