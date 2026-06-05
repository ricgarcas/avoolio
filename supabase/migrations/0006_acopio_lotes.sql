-- Núcleo del acopio aplanado a `public` (3 boards de Monday, decisión 2026-06-03).
-- Las columnas calculadas en Monday son fórmulas (la API las devuelve vacías),
-- así que guardamos los NÚMEROS CRUDOS y derivamos %/montos en queries o código.
-- RLS con política temporal abierta. Reversible: drop/truncate.

-- ── Resultado de selección por lote ← "Análisis Lotes Acopio" (2356) ─────────
create table if not exists public.resultado_lote (
  id              uuid primary key default gen_random_uuid(),
  monday_item_id  bigint unique,
  fecha_recepcion date,
  fecha_cosecha   date,
  semana          integer,
  huerta          text,
  productor       text,
  kilogramos      numeric(12,2),
  jefe_acopio     text,
  tipo_corte      text,
  nacional        numeric(12,2),                 -- kg categoría nacional
  cat1            numeric(12,2),                 -- kg CAT 1
  cat2            numeric(12,2),                 -- kg CAT 2
  merma           numeric(12,2),                 -- kg merma (suele negativo)
  ajuste_volumen      text,
  ajuste_desviacion   text,
  autorizado      text,
  comision        text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists resultado_lote_semana_idx on public.resultado_lote (semana);
create index if not exists resultado_lote_huerta_idx on public.resultado_lote (huerta);

-- ── Penalizaciones / ajustes ← "Análisis Lotes Fuera Norma" (661) ────────────
create table if not exists public.lote_fuera_norma (
  id              uuid primary key default gen_random_uuid(),
  monday_item_id  bigint unique,
  fecha_cosecha   date,
  semana          integer,
  huerta          text,
  productor       text,
  responsable     text,
  tipo_corte      text,
  jefe_acopio     text,
  jefe_cuadrilla  text,
  peso_neto       numeric(12,2),
  kg_fuera_norma  numeric(12,2),
  pct_permitido   numeric(8,4),                  -- fracción permitida
  penalizacion_kg numeric(10,2),                 -- $/kg de penalización
  p_kg_real       numeric(10,2),
  p_kg_estimado   numeric(10,2),
  notas           text,
  estado          text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists lote_fuera_norma_semana_idx on public.lote_fuera_norma (semana);

-- ── Calculadora de precio ← "Calculadora Precio Fruta" (17) ──────────────────
-- precio_pagar_kg recomputado de la cadena de fórmulas de Monday:
--   antes_util = PV - PV*Util ; costo_max = antes_util * %costo
--   precio_max = roundup(costo_max / rendimiento, 2)
--   precio_pagar = roundup(precio_max * tipo_cambio, 2)
-- (interpretación % vs fracción POR VERIFICAR contra Monday.)
create table if not exists public.precio_calc (
  id               uuid primary key default gen_random_uuid(),
  monday_item_id   bigint unique,
  fecha_calculo    date,
  precio_venta     numeric(12,4),
  utilidad         numeric(8,4),
  porcentaje_costo numeric(8,4),
  rendimiento      numeric(8,4),
  tipo_cambio      numeric(8,4),
  precio_pagar_kg  numeric(10,2),                -- recomputado en el import
  estado           text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ── RLS + política temporal abierta ─────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['resultado_lote','lote_fuera_norma','precio_calc'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_all_tmp', t);
    execute format('create policy %I on public.%I for all using (true) with check (true)', t || '_all_tmp', t);
  end loop;
end $$;
