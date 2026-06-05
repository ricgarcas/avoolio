-- =============================================================================
-- 0001_acopio_pendientes.sql
-- Slice de acopio para la cola de Pendientes (HITL) en el schema `public`.
--
-- CONTEXTO: el modelo actual vive en schemas separados (ops/core/agent/…). La
-- decisión acordada es APLANAR todo a `public` (una sola app, no microservicios).
-- Esto es el primer paso en esa dirección: una tabla aplanada que refleja la
-- vista `ops.v_negociaciones_pendientes_hitl` + los campos de display del spec.
--
-- Es NO destructivo (public estaba vacía) y reversible — ver el bloque DROP al
-- final. Cuando exista el modelo aplanado completo, esta tabla se reemplaza por
-- una vista sobre las tablas normalizadas de public.
-- =============================================================================

create table if not exists public.pendiente_hitl (
  id                       uuid primary key default gen_random_uuid(),
  created_at               timestamptz not null default now(),

  -- Identidad de la negociación (de ops.v_negociaciones_pendientes_hitl)
  codigo_hue               text not null,
  huerta                   text not null,   -- nombre de la huerta (display)
  empacadora               text not null,
  productor                text not null,
  acopio                   text,            -- centro de acopio
  acopiador                text,            -- comprador de campo (HITL lo escala)
  variedad                 text not null,

  -- Cifras de la negociación
  calibre                  int,
  banda                    int,             -- banda de precio en la que cayó
  precio_propuesto_mxn_kg  numeric(10,2) not null,
  precio_banda_max_mxn_kg  numeric(10,2),   -- techo de banda (para el delta)
  volumen_acordado_kg      numeric(12,2),
  margen_pct               numeric(5,2),    -- margen calculado (negativo = pérdida)

  -- Por qué requirió decisión humana
  tipo                     text not null
                            check (tipo in ('fuera_margen','coyote','modificacion')),
  razon_hitl               text not null
);

comment on table public.pendiente_hitl is
  'Cola de aprobaciones HITL del Supervisor de Compras. Aplanado del slice de acopio (ops.negociacion + joins). Provisional hasta el modelo public completo.';

-- RLS: habilitado. Política temporal de lectura abierta mientras no hay auth.
-- TODO(auth): reemplazar por políticas por rol (supervisor/admin) cuando exista.
alter table public.pendiente_hitl enable row level security;

drop policy if exists pendiente_hitl_read_tmp on public.pendiente_hitl;
create policy pendiente_hitl_read_tmp
  on public.pendiente_hitl for select
  using (true);

-- Índice para ordenar la cola por antigüedad.
create index if not exists pendiente_hitl_created_at_idx
  on public.pendiente_hitl (created_at);

-- =============================================================================
-- Reversa:
--   drop table if exists public.pendiente_hitl cascade;
-- =============================================================================
