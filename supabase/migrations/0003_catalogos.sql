-- Catálogos maestros del acopio, aplanados a `public` (decisión 2026-06-03).
-- Base maestra: al programar un corte, los datos de la huerta se autollenan
-- desde aquí. Reflejan los catálogos del demo (_analisis/assets/demo-data.js)
-- y la terminología bloqueada del spec.
--
-- RLS habilitado con política temporal abierta (igual que public.pendiente_hitl)
-- hasta que exista auth/roles. Reversible: `drop table ... cascade`.

-- ── Productor ───────────────────────────────────────────────────────────────
create table if not exists public.productor (
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null,
  rfc           text unique,
  municipio     text,
  tel           text,
  correo        text,
  beneficiario  text,                                 -- payee para CxP
  dias_credito  integer,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ── Huerta ──────────────────────────────────────────────────────────────────
create table if not exists public.huerta (
  id             uuid primary key default gen_random_uuid(),
  hue            text unique not null,                 -- HUE00000002340
  nombre         text not null,
  productor_id   uuid references public.productor(id) on delete set null,
  municipio      text,
  altura         integer,                              -- msnm; <2100 = alerta
  punto_reunion  text,
  bascula        text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ── Acopiador ───────────────────────────────────────────────────────────────
create table if not exists public.acopiador (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null unique,
  whatsapp    text,
  zona        text,
  estatus     text not null default 'pendiente'
              check (estatus in ('autorizado', 'pendiente', 'suspendido', 'temporal')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── Cuadrilla / empresa de corte ────────────────────────────────────────────
create table if not exists public.cuadrilla (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null unique,
  tipo        text not null default 'externa'
              check (tipo in ('propia', 'externa')),
  tarifa_kg   numeric(10,2),                           -- $/kg
  tarifa_dia  numeric(12,2),                           -- $/día
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── Acarreador / proveedor de acarreo ───────────────────────────────────────
create table if not exists public.acarreador (
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null unique,
  tipo_unidad   text,                                  -- Torton, Rabón…
  tarifa_viaje  numeric(12,2),                         -- $/viaje
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ── RLS + política temporal abierta ─────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['productor','huerta','acopiador','cuadrilla','acarreador'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_all_tmp', t);
    execute format(
      'create policy %I on public.%I for all using (true) with check (true)',
      t || '_all_tmp', t
    );
  end loop;
end $$;
