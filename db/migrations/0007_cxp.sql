-- Cuentas por pagar (CxP) — obligaciones que derivan del acopio, aplanadas a
-- `public`. Unifica 3 boards de Monday por `tipo`:
--   productor      ← "CXP Productores"             (4069160674)
--   servicio_corte ← "Servicios de corte de fruta" (4330832076)
--   acarreo        ← "Servicios de acarreo de fruta"(4345330832)
--
-- Candado de factura (regla del spec): una fila sin `factura` NO puede avanzar
-- a 'pagada'/'conciliada'. Se aplica en la server action (lib/cxp/actions).
-- RLS con política temporal abierta. Reversible.

create table if not exists public.cxp (
  id              uuid primary key default gen_random_uuid(),
  monday_item_id  bigint unique,
  origen          text,                              -- board de origen
  tipo            text not null
                  check (tipo in ('productor', 'servicio_corte', 'acarreo', 'comision_acopio')),
  beneficiario    text,
  huerta          text,
  lote            text,
  orden_compra    text,
  fecha           date,
  semana          integer,
  kilos           numeric(12,2),
  monto           numeric(14,2),
  factura         text,                              -- folio CFDI; null = sin factura
  estado          text not null default 'borrador'
                  check (estado in ('borrador', 'validada', 'autorizada', 'pagada', 'conciliada')),
  forma_pago      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists cxp_semana_idx on public.cxp (semana);
create index if not exists cxp_tipo_idx on public.cxp (tipo);
create index if not exists cxp_estado_idx on public.cxp (estado);

alter table public.cxp enable row level security;
drop policy if exists cxp_all_tmp on public.cxp;
create policy cxp_all_tmp on public.cxp for all using (true) with check (true);
