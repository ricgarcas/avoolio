# AgroMesh / Avoolio — Handoff

**Última sesión:** 2026-06-03 · **Retomar:** 2026-06-04
Plataforma de operaciones para la cadena del aguacate. Producto = **AgroMesh**, primer cliente = **Avoolio** (empacadora San José, Michoacán). Stack: Next.js 15 (App Router, TS) · Tailwind v4 · shadcn (base-nova/Base UI) · Geist Sans + JetBrains Mono · Phosphor icons · Supabase (`@supabase/ssr`).

---

## Estado: qué está hecho

**Pantallas en vivo** (todas con data real de Monday, bajo el shell `app/(app)/`):
- **Inicio** (`/`) — dashboard: 6 KPIs reales + cola de pendientes.
- **Pendientes** (`/pendientes`) — cola HITL (aprobar con PIN). *Aprobar es optimista, aún sin escritura.*
- **Catálogos** (`/catalogos`) — CRUD real de 5 catálogos (huertas, productores, acopiadores, cuadrillas, acarreadores). Modales con zod+RHF.
- **Cortes** (`/cortes`) — vista agrupada (alerta altura <2100 manda) + filtros + modal "Programar corte" con autollenado desde huertas. Escribe a `public.corte`.
- **CxP** (`/cxp`) — obligaciones con **candado de factura** (sin CFDI no avanza a pagada, enforced en form + action). Montos reales + acarreo estimado por tarifa.
- Placeholders: `/facturas`, `/pagos`, `/costeo`.
- `/design` — showcase del design system (fuera del shell).

**Data en `public`** (Supabase ref `sfkhmlaaohidmotdnmlh`, toda real de Monday):

| Tabla | Filas | Fuente / script |
|---|--:|---|
| `huerta` | 918 | `import-monday.mjs` |
| `productor` | 693 | `import-monday.mjs` |
| `acopiador` / `cuadrilla` / `acarreador` | 14 / 15 / 10 | `import-monday.mjs` |
| `corte` | 446 | `import-cortes.mjs` (Bitácora) |
| `resultado_lote` | 2,356 | `import-lotes.mjs` (=resultado_seleccion: kg + CAT1/CAT2/Nacional/Merma) |
| `lote_fuera_norma` | 661 | `import-lotes.mjs` (penalizaciones) |
| `precio_calc` | 17 | `import-lotes.mjs` (precio_banda; ~$14/kg vigente) |
| `cxp` | 292 | `import-cxp.mjs` (142 productor · 80 corte · 70 acarreo) |
| `pendiente_hitl` | 6 | seed (migr 0001/0002) — *aún mock* |

Migrations: `supabase/migrations/0001..0007`. **Falta `0004` (era seed demo inventado, eliminado a propósito).**

---

## Próximos pasos (prioridad sugerida)

1. **Costeo** (`/costeo`) — el reporte cumbre: costo por kilo con servicios, por curva de calibre. Ya hay insumos: `resultado_lote` (kg + calidad) + `cxp` (montos reales). El "¿cuánto costó comprar un kilo esta semana?" sale de sumar CxP por semana + prorrateo.
2. **Resultados de selección** (pantalla nueva) — `resultado_lote` no tiene UI aún; es el centro del acopio (kg, CAT1/CAT2/Nacional/Merma, %s, ajustes). Base para Costeo.
3. **Conectar Pendientes al `precio_calc`** — hoy la lógica "fuera de margen" usa la tabla mock `pendiente_hitl`. Conectarla al `precio_banda` real (`precio_calc.precio_pagar_kg`) y a las negociaciones reales.
4. **Persistencia real del Aprobar** en Pendientes (hoy optimista, sin DB) + PIN/auth de verdad.
5. **Facturas / Pagos** — el ledger real de pagos vive en Monday `CXP Egresos Empaque` (3431208411): factura, forma de pago, banco, fecha de pago. Importable.
6. **Cerrar acarreo por zona** (opcional) — la tarifa $2,720/viaje es uniforme/aprox; AVOOLIO real varía 2,100/4,850 por zona. Si importa, modelar tarifa por zona.

---

## Deudas técnicas / caveats (leer antes de seguir)

- **RLS abierta:** todas las tablas tienen política temporal `*_all_tmp for all using(true) with check(true)`. Cualquiera con la publishable key escribe. **Cerrar con auth/roles** antes de producción.
- **Aplanar a `public`:** decisión acordada — Ricardo abogará con **Mariano (Owner)** por mover todos los schemas (`core/ops/agent/...`) a `public` y darle acceso Owner a Ricardo. Hoy avanzamos en `public` (era staging vacío). La base es de Mariano; **debe enterarse** de las tablas creadas (reversibles).
- **Import one-way:** Monday → Supabase. Lo que se crea/edita en la app NO regresa a Monday (`monday_item_id` null en altas de la app).
- **Montos estimados en CxP:** acarreo externo = $2,720/viaje (derivado de egresos, marcado con `~`). Servicio de corte usa Subtotal real (`display_value`). Productor usa Total TTS.
- **Pendientes = mock:** `pendiente_hitl` es seed, no datos reales de negociación.
- **Postgres directo solo para inspección/migrations** (`SUPABASE_DB_PASSWORD` en `.env.local`); la app SIEMPRE usa supabase-js.

---

## Cómo correr

```bash
npm run dev                       # localhost:3000
npm run build                     # verifica tipos + build

# Imports de Monday (idempotentes, re-ejecutables):
node scripts/import-monday.mjs    # catálogos
node scripts/import-cortes.mjs    # cortes (Bitácora)
node scripts/import-lotes.mjs     # resultado_lote + fuera_norma + precio_calc
node scripts/import-cxp.mjs       # cuentas por pagar
node scripts/scan-monday.mjs      # explorador de relaciones/boards

# Aplicar una migration (psql directo, lee .env.local):
#   PGPASSWORD=$SUPABASE_DB_PASSWORD psql "sslmode=require host=db.<ref>.supabase.co ..." -f supabase/migrations/000X.sql
```

**Monday API:** token en `.env.local` (`MONDAY_API_TOKEN`). Clave: las columnas fórmula salen vacías en `text` → usar `column_values { ... on FormulaValue { display_value } }`. Upsert por `it.id` (no `it.name`). Dashboards NO los expone la API.

---

## Seguridad / pendientes administrativos

- **Rotar el password de Monday** que se pegó en el chat (el API token basta).
- `.env.local` es gitignored — NUNCA commitear. `SUPABASE_SECRET_KEY`, `SUPABASE_DB_PASSWORD`, `MONDAY_API_TOKEN` son locales.
- Informar a Mariano de las tablas creadas en su DB.

---

## Mapa de archivos clave

```
app/(app)/{layout,page}.tsx           shell + Inicio
app/(app)/{catalogos,cortes,cxp,...}  rutas
components/app/app-shell.tsx           sidebar + topbar
components/{catalogos,cortes,cxp}/     vistas + modales
lib/{catalogos,cortes,cxp}/{schema,queries,actions}.ts   zod + queries(server-only) + actions("use server")
lib/format.ts                          mxn/usd/delta/fecha/hace
lib/supabase/{client,server,middleware}.ts
scripts/import-*.mjs                   ETL Monday→public
supabase/migrations/000X_*.sql
_analisis/                             maqueta/spec original (app.html, modelo.html, assets/avoolio.js)
```

Memoria persistente (cross-sesión): `avoolio-frontend-stack`, `avoolio-supabase-access`, `avoolio-monday-import`, `avoolio-doc-framing`.
