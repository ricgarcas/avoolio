-- Cortes (programación de corte) — aplanado a `public`. Refleja el board
-- "Bitácora de corte (RE-ACO-03)" (Monday 4077387130), 1:1 con el spec.
-- Denormalizado (huerto/productor/empresa como texto) porque la Bitácora no
-- carga el código HUE; el catálogo de huertas es la fuente para autollenar al
-- programar uno nuevo. RLS con política temporal abierta. Reversible.

create table if not exists public.corte (
  id              uuid primary key default gen_random_uuid(),
  monday_item_id  bigint unique,                         -- idempotencia del import
  programado      date,
  semana          integer,                               -- semana ISO derivada
  huerto          text not null,
  productor       text,
  municipio       text,
  asnm            integer,                               -- altura; <2100 = alerta
  tipo_corte      text,
  floracion       text,
  camion          text,
  acopio          text,                                  -- acopiador asignado
  bascula         text,
  punto_reunion   text,
  empresa_corte   text,                                  -- cuadrilla
  precio_pactado  numeric(10,2),
  estado          text not null default 'registrado'
                  check (estado in ('registrado', 'en_espera', 'confirmado', 'cancelado')),
  visita1         text,
  visita2         text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists corte_semana_idx on public.corte (semana);
create index if not exists corte_estado_idx on public.corte (estado);

alter table public.corte enable row level security;
drop policy if exists corte_all_tmp on public.corte;
create policy corte_all_tmp on public.corte for all using (true) with check (true);
