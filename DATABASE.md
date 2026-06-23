# Base de datos — AvoOlio

**Stack:** Postgres 18 corriendo localmente vía Herd Pro Services.
**Host:** `127.0.0.1:5432` · **User:** `root` (sin password) · **DB:** `avoolio`

Las migraciones SQL viven en `db/migrations/` y se aplican con `psql` directo.

```bash
# Conectarse
psql -h 127.0.0.1 -U root -p 5432 -d avoolio

# Aplicar todas las migraciones (idempotente)
./db/apply-all.sh

# Apuntar a otra DB (ej. Railway)
PGHOST=... PGUSER=... PGPORT=... DB=avoolio ./db/apply-all.sh
```

## Schemas

DB `avoolio`:
- `public` — 11 tablas operativas (productor, huerta, acopiador, cuadrilla,
  acarreador, corte, pendiente_hitl, resultado_lote, lote_fuera_norma,
  precio_calc, cxp)
- `acopio` — vistas del boundary (in_sicoa_*, etc.)
- `sicoa_raw` — datos crudos del portal SICOA (huerta_listado_general, scrape_log)

DB `agromesh` (proyecto separado por contrato — boundary contable Ricardo):
- `public` — 31 tablas operativas del blueprint AgroMesh
  (`agromesh/fixtures/10_operational_schema.sql`)
- `contabilidad` — schema AGR-13: 10 tablas + 6 vistas `out_*` (contrato
  con plataforma) + 5 vistas `in_*` (inputs desde public)

## Legacy: Supabase

El proyecto **arrancó en Supabase** (ref `sfkhmlaaohidmotdnmlh`) y partes del
frontend todavía usan `@supabase/ssr` (`lib/supabase/server.ts`, `lib/db.ts`,
`createClient()` en server actions y queries).

**Inventario de Supabase (snapshot 2026-06-16):**

| Schema | Tablas | Vistas | Estado |
|---|---|---|---|
| `public` | 11 | 0 | **Data viva** — 5,395 filas (productores, huertas, cortes, lotes, cxp). Ya está en `avoolio` local. |
| `core` | 13 | 1 | Diseño en frío, sin filas. DDL archivado en `db/legacy-supabase-schemas.sql` |
| `ops` | 8 | 2 | Diseño en frío, sin filas |
| `sales` | 11 | 0 | Diseño en frío, sin filas |
| `agent` | 11 | 5 | Diseño en frío, sin filas |
| `comms` | 4 | 0 | Diseño en frío, sin filas |

Migración a Postgres local está en curso:

- ✅ DDL de `public` ya replicado vía `db/migrations/0001..0007`.
- ✅ Data de `public` cargada en `avoolio` local desde Supabase.
- 📄 DDL de los 5 schemas vacíos archivado en `db/legacy-supabase-schemas.sql`
  como referencia de diseño (no se aplica — son tablas que jamás recibieron
  data; cuando definamos el modelo unificado, sirve como punto de partida).
- ⏳ El código de la app aún apunta a Supabase para reads/writes del runtime.
  Refactor del cliente `lib/supabase/*` → cliente Postgres genérico = ticket aparte.
