-- =====================================================================
-- AGR-13 · Schema contabilidad — AgroMesh accounting module
-- Owner: Ricardo (contractor boundary). Contrato vinculante:
--   blueprint/30_integrations/ACCOUNTING_REQUIREMENTS.md
-- Spec: docs/superpowers/specs/2026-06-10-accounting-data-model-design.md
-- PREREQUISITO: blueprint schema.sql aplicado en el mismo database (public).
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS contabilidad;

-- Todo lo que sigue (tipos, tablas, índices, funciones, vistas) se crea en
-- `contabilidad`; las FKs a tablas operacionales resuelven a `public`.
SET search_path = contabilidad, public;

-- =====================================================================
-- AgroMesh — Accounting schema (PostgreSQL)
-- Generated from ACCOUNTING_DATA_MODEL.md v1.0 · 2026-06-06
-- 11 entities (10 tables + 1 materialized view) in Domain 10.
--
-- PREREQUISITE: schema.sql must be applied first.
--   This file references the following operational tables defined there:
--     empacadora, corte, acuerdo_compra_venta, orden_venta,
--     embarque, importador, productor, cuadrilla
--
-- Conventions (matching schema.sql):
--   * UUID PKs via gen_random_uuid() (pgcrypto — already loaded by schema.sql).
--   * created_at / updated_at TIMESTAMPTZ NOT NULL DEFAULT now() on every table.
--   * Money columns name their unit (_mxn / _usd).
--   * ENUMs are named types defined below.
--   * empacadora_id on every table for multi-tenant RLS.
--   * ON DELETE RESTRICT by default; SET NULL for nullable/optional links.
-- =====================================================================

-- pgcrypto is already enabled by schema.sql; included here for standalone runs.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================================
-- ENUMERATED TYPES — Accounting domain
-- =====================================================================

CREATE TYPE cuenta_tipo           AS ENUM ('activo','pasivo','capital','ingreso','egreso');
CREATE TYPE cuenta_naturaleza     AS ENUM ('deudora','acreedora');
CREATE TYPE asiento_tipo          AS ENUM (
    'compra_fruta','venta','costo_operativo',
    'pago_cxc','pago_cxp','ajuste_fx',
    'cierre_periodo','ajuste_manual'
);
CREATE TYPE asiento_estado        AS ENUM ('borrador','confirmado','revertido');
CREATE TYPE costo_tipo            AS ENUM (
    'acarreo','corte_cuadrilla','costo_fijo_empaque',
    'empaque_materiales','comision_acopio','otro'
);
CREATE TYPE moneda                AS ENUM ('MXN','USD');
CREATE TYPE cxc_estado            AS ENUM ('pendiente','parcial','pagada','vencida','cancelada');
CREATE TYPE cxp_estado            AS ENUM ('pendiente','parcial','pagada','vencida','cancelada');
CREATE TYPE pago_metodo           AS ENUM ('transferencia','cheque','efectivo','compensacion');
CREATE TYPE pago_aplicado_a       AS ENUM ('cxc','cxp');
CREATE TYPE cfdi_estatus          AS ENUM ('vigente','cancelado');
CREATE TYPE cfdi_tipo_comprobante AS ENUM ('ingreso','egreso','traslado','nomina','pago');
CREATE TYPE periodo_estado        AS ENUM ('abierto','cerrado');

-- =====================================================================
-- DOMAIN 10 — Accounting (Contabilidad)
-- Table creation order respects FK dependencies.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Periodo_Contable
--    Must come before Cuenta_Contable (Config_Contable references both,
--    but we defer Config_Contable until after all account tables exist).
-- ---------------------------------------------------------------------
CREATE TABLE periodo_contable (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id  UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    anio           INT         NOT NULL CHECK (anio BETWEEN 2020 AND 2099),
    mes            INT         NOT NULL CHECK (mes BETWEEN 1 AND 12),
    fecha_inicio   DATE        NOT NULL,
    fecha_fin      DATE        NOT NULL,
    estado         periodo_estado NOT NULL DEFAULT 'abierto',
    fecha_cierre   TIMESTAMPTZ,
    cerrado_por    UUID,                   -- intended FK → usuario; no FK until usuario table exists (Design note §5)
    notas          TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_periodo_emp_anio_mes UNIQUE (empacadora_id, anio, mes),
    CONSTRAINT ck_periodo_fechas CHECK (fecha_fin >= fecha_inicio)
);

-- ---------------------------------------------------------------------
-- 2. Cuenta_Contable (Chart of Accounts)
--    Self-referencing via cuenta_padre_id — FK deferred to after CREATE.
-- ---------------------------------------------------------------------
CREATE TABLE cuenta_contable (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id   UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    codigo          VARCHAR(20) NOT NULL,
    nombre          VARCHAR(200) NOT NULL,
    tipo            cuenta_tipo NOT NULL,
    naturaleza      cuenta_naturaleza NOT NULL,
    cuenta_padre_id UUID        REFERENCES cuenta_contable(id) ON DELETE RESTRICT,  -- self-ref; NULL = root
    es_hoja         BOOLEAN     NOT NULL DEFAULT TRUE,   -- FALSE = summary/group account
    activa          BOOLEAN     NOT NULL DEFAULT TRUE,
    descripcion     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_cuenta_emp_codigo UNIQUE (empacadora_id, codigo)
);

-- ---------------------------------------------------------------------
-- 3. Factura_CFDI
--    Defined early because Config_Contable, Asiento_Contable,
--    Cuenta_Por_Cobrar, Cuenta_Por_Pagar, and Pago all reference it.
--    Operational links (orden_venta_id, acuerdo_id) are FKs to
--    operational tables already defined in schema.sql.
-- ---------------------------------------------------------------------
CREATE TABLE factura_cfdi (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,

    -- SAT mandatory fields (CFDI 4.0)
    uuid_fiscal         UUID        UNIQUE,              -- NULL until stamped by PAC; set on timbrado
    serie               VARCHAR(10),
    folio               VARCHAR(20),
    tipo_comprobante    cfdi_tipo_comprobante NOT NULL,
    rfc_emisor          VARCHAR(13) NOT NULL,
    nombre_emisor       VARCHAR(300) NOT NULL,
    rfc_receptor        VARCHAR(13) NOT NULL,
    nombre_receptor     VARCHAR(300) NOT NULL,
    uso_cfdi            VARCHAR(10),                     -- SAT code e.g. "G01", "G03"
    forma_pago          VARCHAR(5),                      -- SAT code e.g. "03"
    metodo_pago         VARCHAR(5),                      -- "PUE" or "PPD"
    condiciones_pago    VARCHAR(100),

    -- Amounts
    subtotal_mxn        DECIMAL(14,2) NOT NULL DEFAULT 0,
    iva_mxn             DECIMAL(14,2) NOT NULL DEFAULT 0,   -- 0 for 0-rate export invoices
    ieps_mxn            DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_mxn           DECIMAL(14,2) NOT NULL DEFAULT 0,
    subtotal_usd        DECIMAL(14,2),                   -- populated for USD export invoices
    total_usd           DECIMAL(14,2),
    tipo_cambio         DECIMAL(8,4),                    -- FX rate at invoice date
    moneda_cfdi         VARCHAR(5)  NOT NULL DEFAULT 'MXN', -- "MXN" or "USD"

    -- Dates
    fecha_emision       TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_timbrado      TIMESTAMPTZ,                     -- set by PAC on stamping

    -- Status
    estatus             cfdi_estatus NOT NULL DEFAULT 'vigente',
    fecha_cancelacion   TIMESTAMPTZ,
    motivo_cancelacion  VARCHAR(10),                     -- SAT codes "01"–"04"
    uuid_sustitucion    UUID,                            -- replacement CFDI UUID

    -- Storage (Supabase Storage / S3 post-MVP)
    xml_url             VARCHAR(500),
    pdf_url             VARCHAR(500),
    cadena_original     TEXT,                            -- large; for audit
    sello_digital       TEXT,

    -- Operational links (both nullable; at least one typically set)
    orden_venta_id      UUID        REFERENCES orden_venta(id) ON DELETE SET NULL,
    acuerdo_id          UUID        REFERENCES acuerdo_compra_venta(id) ON DELETE SET NULL,

    -- Complementos / addenda (CFDI extensibility)
    addenda             JSONB,                           -- customer-specific addenda
    complementos        JSONB,                           -- e.g. carta porte, comercio exterior

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 4. Config_Contable (per-tenant accounting configuration)
--    References cuenta_contable (default account mapping).
--    Must come after cuenta_contable and factura_cfdi.
-- ---------------------------------------------------------------------
CREATE TABLE config_contable (
    id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id               UUID        NOT NULL UNIQUE REFERENCES empacadora(id) ON DELETE RESTRICT,
    regimen_fiscal              VARCHAR(100),
    rfc_empacadora              VARCHAR(13),
    razon_social                VARCHAR(300),
    uso_cfdi_venta_default      VARCHAR(10),
    forma_pago_default          VARCHAR(5),
    metodo_pago_default         VARCHAR(5),

    -- Default account mappings (nullable until chart of accounts seeded)
    cuenta_cxc_id               UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,
    cuenta_cxp_id               UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,
    cuenta_ingresos_venta_id    UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,
    cuenta_costos_compra_id     UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,
    cuenta_bancos_mxn_id        UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,
    cuenta_bancos_usd_id        UUID        REFERENCES cuenta_contable(id) ON DELETE SET NULL,

    -- Collection / payment terms
    dias_vencimiento_cxc        INT         NOT NULL DEFAULT 21,  -- typical 21-25 days
    dias_vencimiento_cxp        INT         NOT NULL DEFAULT 10,

    -- PAC integration (Design note §1)
    pac_proveedor               VARCHAR(100),            -- e.g. "finkok", "sw_sapiens"
    pac_config                  JSONB,                   -- encrypted at application layer

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 5. Asiento_Contable (Journal Entry header)
--    References: empacadora, periodo_contable, and operational tables.
--    Self-reference for reversals added via ALTER after table creation.
-- ---------------------------------------------------------------------
CREATE TABLE asiento_contable (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    periodo_id          UUID        NOT NULL REFERENCES periodo_contable(id) ON DELETE RESTRICT,
    fecha               DATE        NOT NULL,
    tipo                asiento_tipo NOT NULL,
    estado              asiento_estado NOT NULL DEFAULT 'borrador',
    descripcion         VARCHAR(500),
    referencia          VARCHAR(100),

    -- Operational links (all nullable — set based on entry type)
    corte_id            UUID        REFERENCES corte(id) ON DELETE SET NULL,
    acuerdo_id          UUID        REFERENCES acuerdo_compra_venta(id) ON DELETE SET NULL,
    orden_venta_id      UUID        REFERENCES orden_venta(id) ON DELETE SET NULL,
    embarque_id         UUID        REFERENCES embarque(id) ON DELETE SET NULL,

    -- Accounting module links (circular with CxC/CxP — resolved via nullable FKs)
    cxc_id              UUID,                            -- FK → cuenta_por_cobrar added via ALTER below
    cxp_id              UUID,                            -- FK → cuenta_por_pagar added via ALTER below
    factura_cfdi_id     UUID        REFERENCES factura_cfdi(id) ON DELETE SET NULL,

    -- Reversal reference (self-referential)
    asiento_revertido_id UUID,                           -- FK → asiento_contable added via ALTER below

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 6. Linea_Asiento (Journal Entry lines — debit/credit legs)
-- ---------------------------------------------------------------------
CREATE TABLE linea_asiento (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    asiento_id      UUID        NOT NULL REFERENCES asiento_contable(id) ON DELETE CASCADE,
    empacadora_id   UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    cuenta_id       UUID        NOT NULL REFERENCES cuenta_contable(id) ON DELETE RESTRICT,
    descripcion     VARCHAR(300),

    -- MXN amounts (always populated)
    debe_mxn        DECIMAL(14,2) NOT NULL DEFAULT 0,
    haber_mxn       DECIMAL(14,2) NOT NULL DEFAULT 0,

    -- USD amounts (populated for USD-currency transactions)
    debe_usd        DECIMAL(14,2) NOT NULL DEFAULT 0,
    haber_usd       DECIMAL(14,2) NOT NULL DEFAULT 0,

    -- FX rate used to convert USD → MXN for this line
    tipo_cambio     DECIMAL(8,4),

    orden           INT         NOT NULL DEFAULT 0,     -- display order within entry

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_linea_debe_haber CHECK (
        (debe_mxn >= 0) AND (haber_mxn >= 0) AND
        (debe_usd >= 0) AND (haber_usd >= 0) AND
        -- Each line is either a debit or a credit, not both (in MXN)
        NOT (debe_mxn > 0 AND haber_mxn > 0)
    )
);

-- ---------------------------------------------------------------------
-- 7. Costo_Operativo (Operational cost capture)
-- ---------------------------------------------------------------------
CREATE TABLE costo_operativo (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id   UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    tipo_costo      costo_tipo  NOT NULL,

    -- Operational links (at least one should be set; enforced at API layer)
    corte_id        UUID        REFERENCES corte(id) ON DELETE SET NULL,
    acuerdo_id      UUID        REFERENCES acuerdo_compra_venta(id) ON DELETE SET NULL,

    -- Amount
    monto_mxn       DECIMAL(14,2) NOT NULL DEFAULT 0,
    monto_usd       DECIMAL(10,2) NOT NULL DEFAULT 0,   -- for USD-denominated costs
    moneda          moneda      NOT NULL DEFAULT 'MXN',
    tipo_cambio     DECIMAL(8,4),                       -- FX rate if moneda = USD

    -- Per-kg allocation
    volumen_kg      DECIMAL(10,2),                      -- kg this cost covers
    costo_por_kg_mxn DECIMAL(8,4),                      -- derived: monto_mxn / volumen_kg (see Design note §3)

    -- Detail
    fecha           DATE        NOT NULL DEFAULT CURRENT_DATE,
    proveedor       VARCHAR(200),
    descripcion     TEXT,

    -- Accounting link
    asiento_id      UUID        REFERENCES asiento_contable(id) ON DELETE SET NULL,
    periodo_id      UUID        REFERENCES periodo_contable(id) ON DELETE RESTRICT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 8. Cuenta_Por_Cobrar (Accounts Receivable)
-- ---------------------------------------------------------------------
CREATE TABLE cuenta_por_cobrar (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id         UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    orden_venta_id        UUID        NOT NULL REFERENCES orden_venta(id) ON DELETE RESTRICT,
    importador_id         UUID        NOT NULL REFERENCES importador(id) ON DELETE RESTRICT,
    factura_cfdi_id       UUID        REFERENCES factura_cfdi(id) ON DELETE SET NULL,

    -- Amounts
    monto_usd             DECIMAL(14,2) NOT NULL,
    monto_mxn             DECIMAL(14,2) NOT NULL,       -- MXN equivalent at invoice date
    tipo_cambio_factura   DECIMAL(8,4),                 -- FX rate at invoice date
    saldo_pendiente_usd   DECIMAL(14,2) NOT NULL,       -- decrements as payments arrive
    moneda                moneda      NOT NULL DEFAULT 'USD',

    -- Dates
    fecha_emision         DATE        NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento     DATE        NOT NULL,          -- emision + dias_vencimiento_cxc
    fecha_pago_real       DATE,                         -- set when fully paid

    -- Status
    estado                cxc_estado  NOT NULL DEFAULT 'pendiente',

    -- Accounting
    asiento_id            UUID        REFERENCES asiento_contable(id) ON DELETE SET NULL,
    periodo_id            UUID        NOT NULL REFERENCES periodo_contable(id) ON DELETE RESTRICT,
    notas                 TEXT,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_cxc_saldo CHECK (saldo_pendiente_usd >= 0),
    CONSTRAINT ck_cxc_monto  CHECK (monto_usd > 0)
);

-- ---------------------------------------------------------------------
-- 9. Cuenta_Por_Pagar (Accounts Payable)
-- ---------------------------------------------------------------------
CREATE TABLE cuenta_por_pagar (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id         UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,

    -- Creditor (one of acuerdo_id or corte_id should be set)
    acuerdo_id            UUID        REFERENCES acuerdo_compra_venta(id) ON DELETE SET NULL,
    corte_id              UUID        REFERENCES corte(id) ON DELETE SET NULL,
    productor_id          UUID        REFERENCES productor(id) ON DELETE SET NULL,
    cuadrilla_id          UUID        REFERENCES cuadrilla(id) ON DELETE SET NULL,
    factura_cfdi_id       UUID        REFERENCES factura_cfdi(id) ON DELETE SET NULL,

    -- Amounts
    monto_mxn             DECIMAL(14,2) NOT NULL,
    saldo_pendiente_mxn   DECIMAL(14,2) NOT NULL,       -- decrements as payments go out
    moneda                moneda      NOT NULL DEFAULT 'MXN',

    -- Dates
    fecha_emision         DATE        NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento     DATE        NOT NULL,
    fecha_pago_real       DATE,

    -- Status
    estado                cxp_estado  NOT NULL DEFAULT 'pendiente',

    -- Accounting
    asiento_id            UUID        REFERENCES asiento_contable(id) ON DELETE SET NULL,
    periodo_id            UUID        NOT NULL REFERENCES periodo_contable(id) ON DELETE RESTRICT,
    notas                 TEXT,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_cxp_saldo CHECK (saldo_pendiente_mxn >= 0),
    CONSTRAINT ck_cxp_monto  CHECK (monto_mxn > 0)
);

-- ---------------------------------------------------------------------
-- 10. Pago (Payment)
-- ---------------------------------------------------------------------
CREATE TABLE pago (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID        NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    aplicado_a          pago_aplicado_a NOT NULL,

    -- Applied to (exactly one should be set, matching aplicado_a)
    cxc_id              UUID        REFERENCES cuenta_por_cobrar(id) ON DELETE SET NULL,
    cxp_id              UUID        REFERENCES cuenta_por_pagar(id) ON DELETE SET NULL,

    -- Amount
    monto_mxn           DECIMAL(14,2) NOT NULL DEFAULT 0,
    monto_usd           DECIMAL(14,2) NOT NULL DEFAULT 0,
    moneda              moneda      NOT NULL,
    tipo_cambio         DECIMAL(8,4),                   -- FX rate at payment date

    -- Details
    fecha_pago          DATE        NOT NULL DEFAULT CURRENT_DATE,
    metodo              pago_metodo NOT NULL,
    referencia_bancaria VARCHAR(200),
    cuenta_bancaria     VARCHAR(200),

    -- CFDI complemento de pago (required for PPD method invoices)
    factura_cfdi_id     UUID        REFERENCES factura_cfdi(id) ON DELETE SET NULL,

    -- Accounting
    asiento_id          UUID        REFERENCES asiento_contable(id) ON DELETE SET NULL,
    periodo_id          UUID        NOT NULL REFERENCES periodo_contable(id) ON DELETE RESTRICT,
    notas               TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_pago_cxc_or_cxp CHECK (
        (aplicado_a = 'cxc' AND cxc_id IS NOT NULL AND cxp_id IS NULL) OR
        (aplicado_a = 'cxp' AND cxp_id IS NOT NULL AND cxc_id IS NULL)
    ),
    CONSTRAINT ck_pago_monto CHECK (monto_mxn >= 0 AND monto_usd >= 0)
);

-- =====================================================================
-- DEFERRED / SELF-REFERENTIAL FOREIGN KEYS
-- Added after all tables exist to resolve circular references.
-- =====================================================================

-- Asiento_Contable: self-reference for reversals
ALTER TABLE asiento_contable
    ADD CONSTRAINT fk_asiento_revertido
        FOREIGN KEY (asiento_revertido_id)
        REFERENCES asiento_contable(id) ON DELETE SET NULL;

-- Asiento_Contable → Cuenta_Por_Cobrar
ALTER TABLE asiento_contable
    ADD CONSTRAINT fk_asiento_cxc
        FOREIGN KEY (cxc_id)
        REFERENCES cuenta_por_cobrar(id) ON DELETE SET NULL;

-- Asiento_Contable → Cuenta_Por_Pagar
ALTER TABLE asiento_contable
    ADD CONSTRAINT fk_asiento_cxp
        FOREIGN KEY (cxp_id)
        REFERENCES cuenta_por_pagar(id) ON DELETE SET NULL;


-- =====================================================================
-- INDEXES — tenant scoping + hot foreign keys
-- =====================================================================

-- Periodo_Contable
CREATE INDEX idx_periodo_empacadora       ON periodo_contable(empacadora_id, anio, mes);
CREATE INDEX idx_periodo_estado           ON periodo_contable(estado);

-- Cuenta_Contable
CREATE INDEX idx_cuenta_empacadora        ON cuenta_contable(empacadora_id);
CREATE INDEX idx_cuenta_codigo            ON cuenta_contable(empacadora_id, codigo);
CREATE INDEX idx_cuenta_padre             ON cuenta_contable(cuenta_padre_id);
CREATE INDEX idx_cuenta_tipo              ON cuenta_contable(empacadora_id, tipo);

-- Factura_CFDI
CREATE INDEX idx_cfdi_empacadora          ON factura_cfdi(empacadora_id);
CREATE INDEX idx_cfdi_uuid_fiscal         ON factura_cfdi(uuid_fiscal);
CREATE INDEX idx_cfdi_orden_venta         ON factura_cfdi(orden_venta_id);
CREATE INDEX idx_cfdi_acuerdo             ON factura_cfdi(acuerdo_id);
CREATE INDEX idx_cfdi_estatus             ON factura_cfdi(empacadora_id, estatus);
CREATE INDEX idx_cfdi_fecha_emision       ON factura_cfdi(empacadora_id, fecha_emision);

-- Config_Contable
CREATE INDEX idx_config_empacadora        ON config_contable(empacadora_id);

-- Asiento_Contable
CREATE INDEX idx_asiento_empacadora       ON asiento_contable(empacadora_id);
CREATE INDEX idx_asiento_periodo          ON asiento_contable(periodo_id);
CREATE INDEX idx_asiento_fecha            ON asiento_contable(empacadora_id, fecha);
CREATE INDEX idx_asiento_tipo             ON asiento_contable(empacadora_id, tipo);
CREATE INDEX idx_asiento_estado           ON asiento_contable(estado);
CREATE INDEX idx_asiento_corte            ON asiento_contable(corte_id);
CREATE INDEX idx_asiento_orden_venta      ON asiento_contable(orden_venta_id);

-- Linea_Asiento
CREATE INDEX idx_linea_asiento            ON linea_asiento(asiento_id);
CREATE INDEX idx_linea_cuenta             ON linea_asiento(cuenta_id);
CREATE INDEX idx_linea_empacadora         ON linea_asiento(empacadora_id);

-- Costo_Operativo
CREATE INDEX idx_costo_empacadora         ON costo_operativo(empacadora_id);
CREATE INDEX idx_costo_corte              ON costo_operativo(corte_id);
CREATE INDEX idx_costo_acuerdo            ON costo_operativo(acuerdo_id);
CREATE INDEX idx_costo_periodo            ON costo_operativo(periodo_id);
CREATE INDEX idx_costo_tipo               ON costo_operativo(empacadora_id, tipo_costo);

-- Cuenta_Por_Cobrar
CREATE INDEX idx_cxc_empacadora           ON cuenta_por_cobrar(empacadora_id);
CREATE INDEX idx_cxc_orden_venta          ON cuenta_por_cobrar(orden_venta_id);
CREATE INDEX idx_cxc_importador           ON cuenta_por_cobrar(importador_id);
CREATE INDEX idx_cxc_estado               ON cuenta_por_cobrar(empacadora_id, estado);
CREATE INDEX idx_cxc_vencimiento          ON cuenta_por_cobrar(empacadora_id, fecha_vencimiento);
CREATE INDEX idx_cxc_periodo              ON cuenta_por_cobrar(periodo_id);

-- Cuenta_Por_Pagar
CREATE INDEX idx_cxp_empacadora           ON cuenta_por_pagar(empacadora_id);
CREATE INDEX idx_cxp_acuerdo              ON cuenta_por_pagar(acuerdo_id);
CREATE INDEX idx_cxp_corte                ON cuenta_por_pagar(corte_id);
CREATE INDEX idx_cxp_productor            ON cuenta_por_pagar(productor_id);
CREATE INDEX idx_cxp_cuadrilla            ON cuenta_por_pagar(cuadrilla_id);
CREATE INDEX idx_cxp_estado               ON cuenta_por_pagar(empacadora_id, estado);
CREATE INDEX idx_cxp_vencimiento          ON cuenta_por_pagar(empacadora_id, fecha_vencimiento);
CREATE INDEX idx_cxp_periodo              ON cuenta_por_pagar(periodo_id);

-- Pago
CREATE INDEX idx_pago_empacadora          ON pago(empacadora_id);
CREATE INDEX idx_pago_cxc                 ON pago(cxc_id);
CREATE INDEX idx_pago_cxp                 ON pago(cxp_id);
CREATE INDEX idx_pago_fecha               ON pago(empacadora_id, fecha_pago);
CREATE INDEX idx_pago_periodo             ON pago(periodo_id);

-- =====================================================================
-- END OF accounting_schema.sql
-- =====================================================================

-- =====================================================================
-- CHECKs adicionales (no estaban en la referencia)
-- =====================================================================
-- Una línea es debe XOR haber (en MXN, la moneda del trial balance).
ALTER TABLE contabilidad.linea_asiento
  ADD CONSTRAINT chk_linea_un_lado CHECK (
    (COALESCE(debe_mxn, 0) > 0 AND COALESCE(haber_mxn, 0) = 0) OR
    (COALESCE(haber_mxn, 0) > 0 AND COALESCE(debe_mxn, 0) = 0)
  );

-- Un pago aplica a exactamente un documento, consistente con aplicado_a.
ALTER TABLE contabilidad.pago
  ADD CONSTRAINT chk_pago_destino CHECK (
    (aplicado_a = 'cxc' AND cxc_id IS NOT NULL AND cxp_id IS NULL) OR
    (aplicado_a = 'cxp' AND cxp_id IS NOT NULL AND cxc_id IS NULL)
  );

-- =====================================================================
-- TRIGGERS — updated_at
-- =====================================================================
CREATE FUNCTION contabilidad.set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = clock_timestamp();
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'config_contable','periodo_contable','cuenta_contable','asiento_contable',
    'costo_operativo','cuenta_por_cobrar','cuenta_por_pagar','pago','factura_cfdi'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON contabilidad.%I
       FOR EACH ROW EXECUTE FUNCTION contabilidad.set_updated_at()', t, t);
  END LOOP;
END $$;
-- linea_asiento no lleva trigger: solo tiene created_at.

-- =====================================================================
-- TRIGGERS — ciclo de vida del asiento (partida doble)
-- =====================================================================
-- Los asientos nacen en borrador; las líneas se insertan después.
CREATE FUNCTION contabilidad.asiento_nace_borrador() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.estado <> 'borrador' THEN
    RAISE EXCEPTION 'los asientos nacen en borrador (recibí %)', NEW.estado;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_nace_borrador
  BEFORE INSERT ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.asiento_nace_borrador();

-- Confirmar exige: tiene líneas y Σdebe = Σhaber (en MXN, moneda del trial balance).
CREATE FUNCTION contabilidad.check_asiento_balanceado() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_debe numeric; v_haber numeric;
BEGIN
  SELECT COALESCE(SUM(debe_mxn), 0), COALESCE(SUM(haber_mxn), 0)
    INTO v_debe, v_haber
    FROM contabilidad.linea_asiento WHERE asiento_id = NEW.id;
  IF v_debe = 0 AND v_haber = 0 THEN
    RAISE EXCEPTION 'asiento % sin líneas no puede confirmarse', NEW.id;
  END IF;
  IF v_debe IS DISTINCT FROM v_haber THEN
    RAISE EXCEPTION 'asiento desbalanceado: debe=% haber=%', v_debe, v_haber;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_balanceado
  BEFORE UPDATE OF estado ON contabilidad.asiento_contable
  FOR EACH ROW
  WHEN (OLD.estado = 'borrador' AND NEW.estado = 'confirmado')
  EXECUTE FUNCTION contabilidad.check_asiento_balanceado();
