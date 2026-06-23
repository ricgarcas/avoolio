-- Reconciliación Monday ↔ SICOA para huertas.
--
-- Las claves SAGARPA de Monday (`public.huerta.hue`) vienen de imports
-- históricos: hay typos, sufijos "(copy)", claves outdated. La fuente de
-- verdad es SICOA (`sicoa_raw.huerta_listado_general`).
--
-- Esta tabla guarda la decisión por huerta (match/no match) para que la app
-- pueda mostrar "SICOA dice ALTA" o "huerta no aparece en SICOA" sin
-- recalcular cada vez.

create extension if not exists pg_trgm;
create extension if not exists fuzzystrmatch;

create table if not exists acopio.huerta_reconciliacion (
  monday_hue           text primary key references public.huerta(hue) on delete cascade,
  sicoa_clave_sagarpa  text,
  similarity_score     numeric(4,3),
  similarity_dim       text,                                -- 'name+municipio' | 'name+productor' | 'clave_prefix' | 'manual'
  status               text not null default 'pendiente',   -- 'pendiente' | 'auto_confirmado' | 'confirmado' | 'rechazado' | 'sin_match'
  reviewed_by          text,
  reviewed_at          timestamptz,
  notas                text,
  updated_at           timestamptz not null default now()
);

create index if not exists huerta_reconciliacion_sicoa_idx
  on acopio.huerta_reconciliacion (sicoa_clave_sagarpa);
create index if not exists huerta_reconciliacion_status_idx
  on acopio.huerta_reconciliacion (status);

-- ─── propuestas de match ──────────────────────────────────────────────────────
-- Para cada huerta Monday, top 5 candidatos SICOA ordenados por similitud
-- de nombre dentro del mismo municipio.
create or replace view acopio.huerta_match_candidatos as
with ranked as (
  select
    h.hue                          as monday_hue,
    h.nombre                       as monday_nombre,
    h.municipio                    as monday_municipio,
    s.clave_sagarpa                as sicoa_clave_sagarpa,
    s.nombre_huerta                as sicoa_nombre,
    s.status                       as sicoa_status,
    similarity(upper(s.nombre_huerta), upper(h.nombre))::numeric(4,3) as sim_nombre,
    -- Match exacto de clave (filtro contra typos: longitud distinta o 1-2 chars diff)
    (h.hue = s.clave_sagarpa)      as clave_exacta,
    levenshtein(h.hue, s.clave_sagarpa) as clave_distancia,
    row_number() over (
      partition by h.hue
      order by
        (h.hue = s.clave_sagarpa) desc,
        similarity(upper(s.nombre_huerta), upper(h.nombre)) desc,
        levenshtein(h.hue, s.clave_sagarpa) asc
    ) as rank
  from public.huerta h
  join sicoa_raw.huerta_listado_general s on s.municipio = h.municipio
)
select * from ranked where rank <= 5;

-- ─── vista del estado actual de reconciliación ────────────────────────────────
create or replace view acopio.huerta_estado_sicoa as
select
  h.hue                            as monday_hue,
  h.nombre                         as monday_nombre,
  h.municipio                      as monday_municipio,
  r.status                         as reconciliacion_status,
  r.sicoa_clave_sagarpa            as sicoa_clave,
  s.status                         as sicoa_status,
  s.nombre_huerta                  as sicoa_nombre
from public.huerta h
left join acopio.huerta_reconciliacion r on r.monday_hue = h.hue
left join sicoa_raw.huerta_listado_general s on s.clave_sagarpa = r.sicoa_clave_sagarpa
  and s.fetched_at = (select max(fetched_at) from sicoa_raw.huerta_listado_general
                      where clave_sagarpa = r.sicoa_clave_sagarpa);
