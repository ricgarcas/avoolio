#!/usr/bin/env node
// Helper read-only de Supabase para AvoOlio — sin dependencias (usa fetch de Node 22+).
// Lee .env.local. Solo hace GETs vía PostgREST. No escribe nada.
//
// Uso:
//   node scripts/supa.mjs tables            # lista tablas/vistas del schema public
//   node scripts/supa.mjs cols <tabla>      # columnas de una tabla
//   node scripts/supa.mjs get <tabla> [n]   # primeras n filas (default 10)

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const env = Object.fromEntries(
  readFileSync(join(root, '.env.local'), 'utf8')
    .split('\n')
    .filter((l) => l && !l.startsWith('#') && l.includes('='))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    })
);

const URL = env.SUPABASE_URL;
const KEY = env.SUPABASE_SECRET_KEY;
if (!URL || !KEY) {
  console.error('Falta SUPABASE_URL o SUPABASE_SECRET_KEY en .env.local');
  process.exit(1);
}

const headers = { apikey: KEY, Authorization: `Bearer ${KEY}` };

async function spec() {
  const r = await fetch(`${URL}/rest/v1/`, { headers });
  if (!r.ok) throw new Error(`${r.status} ${await r.text()}`);
  return r.json();
}

const [cmd, arg, arg2] = process.argv.slice(2);

if (cmd === 'tables') {
  const d = await spec();
  const defs = d.definitions || {};
  const tables = Object.keys(d.paths || {})
    .map((p) => p.replace(/^\//, ''))
    .filter((p) => p && !p.startsWith('rpc/'));
  if (!tables.length) {
    console.log('Sin tablas en el schema public (proyecto vacío o tablas en otro schema).');
  } else {
    console.log(`Tablas/vistas (${tables.length}):`);
    for (const t of tables.sort()) {
      console.log(`  ${t} (${Object.keys(defs[t]?.properties || {}).length} cols)`);
    }
  }
} else if (cmd === 'cols') {
  if (!arg) { console.error('Uso: cols <tabla>'); process.exit(1); }
  const d = await spec();
  const props = d.definitions?.[arg]?.properties;
  if (!props) { console.error(`Tabla "${arg}" no encontrada.`); process.exit(1); }
  console.log(`${arg}:`);
  for (const [c, m] of Object.entries(props)) {
    console.log(`  ${c}  ${m.format || m.type || ''}${m.description ? '  // ' + m.description : ''}`);
  }
} else if (cmd === 'get') {
  if (!arg) { console.error('Uso: get <tabla> [n]'); process.exit(1); }
  const n = arg2 || 10;
  const r = await fetch(`${URL}/rest/v1/${arg}?limit=${n}`, { headers });
  if (!r.ok) { console.error(`${r.status} ${await r.text()}`); process.exit(1); }
  console.log(JSON.stringify(await r.json(), null, 2));
} else {
  console.log('Comandos: tables | cols <tabla> | get <tabla> [n]');
}
