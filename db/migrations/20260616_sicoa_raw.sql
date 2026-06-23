-- Esquema raw para datos extraídos del portal SICOA (APEAM/SENASICA).
-- Patrón "una fila por scrape": histórico completo, sin upsert.

create schema if not exists sicoa_raw;
create schema if not exists acopio;

create table if not exists sicoa_raw.huerta_listado_general (
  id              bigserial primary key,
  fetched_at      timestamptz not null default now(),
  estado          text not null,                 -- 'MICHOACAN'
  criterio        text not null,                 -- criterio enviado al server
  clave_sagarpa   text not null,                 -- 'HUE08160661012'
  nombre_huerta   text not null,
  status          text not null,                 -- 'ALTA EN PADRON CERTIFICADO', etc.
  localidad       text,
  municipio       text not null,
  payload         jsonb not null,                -- fila cruda completa de la grilla
  scraper_version text not null,
  cred_user       text not null,
  unique (clave_sagarpa, fetched_at)
);

create index if not exists huerta_listado_clave_idx
  on sicoa_raw.huerta_listado_general (clave_sagarpa, fetched_at desc);
create index if not exists huerta_listado_municipio_idx
  on sicoa_raw.huerta_listado_general (municipio);
create index if not exists huerta_listado_payload_gin
  on sicoa_raw.huerta_listado_general using gin (payload);

-- Bitácora de corridas del scraper.
create table if not exists sicoa_raw.scrape_log (
  id              bigserial primary key,
  scraper         text not null,                 -- 'listado-huertas'
  scraper_version text not null,
  cred_user       text not null,
  started_at      timestamptz not null default now(),
  finished_at     timestamptz,
  status          text,                          -- 'ok' | 'error'
  rows_inserted   integer,
  error_message   text,
  criterios       text[]
);

-- Vista normalizada con el snapshot más reciente por huerta.
create or replace view acopio.in_sicoa_huerta with (security_invoker = true) as
select distinct on (clave_sagarpa)
  clave_sagarpa,
  nombre_huerta,
  status,
  localidad,
  municipio,
  estado,
  fetched_at as snapshot_at
from sicoa_raw.huerta_listado_general
order by clave_sagarpa, fetched_at desc;

-- Vista de salud del scraper para el dashboard de operaciones.
create or replace view acopio.in_sicoa_health with (security_invoker = true) as
select
  scraper,
  scraper_version,
  cred_user,
  started_at,
  finished_at,
  status,
  rows_inserted,
  error_message,
  criterios
from sicoa_raw.scrape_log
order by started_at desc
limit 50;
