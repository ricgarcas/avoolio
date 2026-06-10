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

-- Pago<->documento ya viene garantizado por ck_pago_cxc_or_cxp en la referencia.

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

-- =====================================================================
-- TRIGGERS — inmutabilidad del journal
-- =====================================================================
-- Confirmado: solo se permite la transición a revertido sin tocar nada más.
-- Revertido: intocable. Borrador: libre. Corrección = asiento de reversa
-- nuevo apuntando asiento_revertido_id al original.
CREATE FUNCTION contabilidad.bloquear_asiento_inmutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.estado <> 'borrador' THEN
      RAISE EXCEPTION 'asiento % es inmutable (estado %): usa un asiento de reversa', OLD.id, OLD.estado;
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.estado = 'revertido' THEN
    RAISE EXCEPTION 'asiento % está revertido y es inmutable', OLD.id;
  END IF;

  IF OLD.estado = 'confirmado' THEN
    IF NOT (NEW.estado = 'revertido'
            AND (to_jsonb(NEW) - 'estado' - 'updated_at')
              = (to_jsonb(OLD) - 'estado' - 'updated_at')) THEN
      RAISE EXCEPTION 'asiento % confirmado es inmutable: usa un asiento de reversa', OLD.id;
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_inmutable
  BEFORE UPDATE OR DELETE ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.bloquear_asiento_inmutable();

-- Las líneas solo se tocan mientras el asiento está en borrador.
CREATE FUNCTION contabilidad.bloquear_lineas_confirmadas() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_estado contabilidad.asiento_estado;
BEGIN
  SELECT estado INTO v_estado FROM contabilidad.asiento_contable
   WHERE id = COALESCE(NEW.asiento_id, OLD.asiento_id);
  IF v_estado <> 'borrador' THEN
    RAISE EXCEPTION 'las líneas del asiento % son inmutables (estado %)',
      COALESCE(NEW.asiento_id, OLD.asiento_id), v_estado;
  END IF;
  RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_lineas_inmutables
  BEFORE INSERT OR UPDATE OR DELETE ON contabilidad.linea_asiento
  FOR EACH ROW EXECUTE FUNCTION contabilidad.bloquear_lineas_confirmadas();

-- =====================================================================
-- TRIGGERS — candado de periodo cerrado
-- =====================================================================
CREATE FUNCTION contabilidad.check_periodo_abierto() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_estado contabilidad.periodo_estado; v_anio int; v_mes int;
BEGIN
  SELECT estado, anio, mes INTO v_estado, v_anio, v_mes
    FROM contabilidad.periodo_contable WHERE id = NEW.periodo_id;
  IF v_estado = 'cerrado' THEN
    RAISE EXCEPTION 'periodo %-% está cerrado: no admite asientos', v_anio, lpad(v_mes::text, 2, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_periodo_abierto
  BEFORE INSERT OR UPDATE OF periodo_id ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.check_periodo_abierto();

-- =====================================================================
-- TRIGGERS — solo cuentas hoja activas reciben líneas
-- =====================================================================
CREATE FUNCTION contabilidad.check_cuenta_posteable() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_hoja boolean; v_activa boolean; v_codigo text;
BEGIN
  SELECT es_hoja, activa, codigo INTO v_hoja, v_activa, v_codigo
    FROM contabilidad.cuenta_contable WHERE id = NEW.cuenta_id;
  IF NOT v_hoja OR NOT v_activa THEN
    RAISE EXCEPTION 'cuenta % no es posteable (es_hoja=%, activa=%)', v_codigo, v_hoja, v_activa;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_linea_cuenta_posteable
  BEFORE INSERT OR UPDATE OF cuenta_id ON contabilidad.linea_asiento
  FOR EACH ROW EXECUTE FUNCTION contabilidad.check_cuenta_posteable();

-- =====================================================================
-- TRIGGERS — pagos recalculan saldo y estado (sin drift)
-- =====================================================================
CREATE FUNCTION contabilidad.aplicar_pago() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_cxc uuid; v_cxp uuid;
BEGIN
  v_cxc := COALESCE(NEW.cxc_id, OLD.cxc_id);
  v_cxp := COALESCE(NEW.cxp_id, OLD.cxp_id);

  IF v_cxc IS NOT NULL THEN
    UPDATE contabilidad.cuenta_por_cobrar c SET
      saldo_pendiente_usd = c.monto_usd - pagado.total,
      estado = CASE
        WHEN c.estado = 'cancelada' THEN c.estado
        WHEN pagado.total >= c.monto_usd THEN 'pagada'::contabilidad.cxc_estado
        WHEN pagado.total > 0 THEN 'parcial'::contabilidad.cxc_estado
        ELSE 'pendiente'::contabilidad.cxc_estado
      END,
      fecha_pago_real = CASE WHEN pagado.total >= c.monto_usd THEN pagado.ultima ELSE NULL END
    FROM (
      SELECT COALESCE(SUM(p.monto_usd), 0) AS total, MAX(p.fecha_pago) AS ultima
        FROM contabilidad.pago p WHERE p.cxc_id = v_cxc
    ) pagado
    WHERE c.id = v_cxc;
  END IF;

  IF v_cxp IS NOT NULL THEN
    UPDATE contabilidad.cuenta_por_pagar c SET
      saldo_pendiente_mxn = c.monto_mxn - pagado.total,
      estado = CASE
        WHEN c.estado = 'cancelada' THEN c.estado
        WHEN pagado.total >= c.monto_mxn THEN 'pagada'::contabilidad.cxp_estado
        WHEN pagado.total > 0 THEN 'parcial'::contabilidad.cxp_estado
        ELSE 'pendiente'::contabilidad.cxp_estado
      END,
      fecha_pago_real = CASE WHEN pagado.total >= c.monto_mxn THEN pagado.ultima ELSE NULL END
    FROM (
      SELECT COALESCE(SUM(p.monto_mxn), 0) AS total, MAX(p.fecha_pago) AS ultima
        FROM contabilidad.pago p WHERE p.cxp_id = v_cxp
    ) pagado
    WHERE c.id = v_cxp;
  END IF;

  RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_pago_aplica
  AFTER INSERT OR UPDATE OR DELETE ON contabilidad.pago
  FOR EACH ROW EXECUTE FUNCTION contabilidad.aplicar_pago();

-- =====================================================================
-- RLS — aislamiento por tenant
-- =====================================================================
-- El tenant actual se resuelve vía esta función. HOY lee el setting
-- app.empacadora_id; cuando AGR-8 defina el modelo usuario/JWT en Supabase,
-- SOLO se cambia el cuerpo de esta función (las políticas no se tocan):
--   p.ej. (current_setting('request.jwt.claims', true)::jsonb ->> 'empacadora_id')::uuid
CREATE FUNCTION contabilidad.current_empacadora() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.empacadora_id', true), '')::uuid
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'config_contable','periodo_contable','cuenta_contable','asiento_contable',
    'linea_asiento','costo_operativo','cuenta_por_cobrar','cuenta_por_pagar',
    'pago','factura_cfdi'
  ] LOOP
    EXECUTE format('ALTER TABLE contabilidad.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON contabilidad.%I
         USING (empacadora_id = contabilidad.current_empacadora())
         WITH CHECK (empacadora_id = contabilidad.current_empacadora())', t);
  END LOOP;
END $$;
-- Sin FORCE: el owner del schema (jobs internos del módulo) opera cross-tenant.

-- =====================================================================
-- VISTAS DE ENTRADA in_* — lectura del modelo operacional (public)
-- security_invoker: el RLS de las tablas base aplica al consultante.
-- Nota: corte y resultado_seleccion no tienen empacadora_id propio;
-- se resuelve vía join a acuerdo_compra_venta.
-- =====================================================================
CREATE VIEW contabilidad.in_acuerdos WITH (security_invoker = true) AS
SELECT a.id, a.empacadora_id, a.productor_id, a.huerta_id,
       a.precio_por_kg, a.volumen_acordado_ton, a.estado,
       a.fecha_corte_programada, a.created_at, a.updated_at
  FROM public.acuerdo_compra_venta a;

CREATE VIEW contabilidad.in_cortes WITH (security_invoker = true) AS
SELECT c.id, a.empacadora_id, c.acuerdo_id, c.huerta_id, c.cuadrilla_id,
       c.acopio_id, c.fecha, c.volumen_cortado_ton, c.costo_cuadrilla_por_kg,
       c.estado, c.created_at, c.updated_at
  FROM public.corte c
  JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id;

CREATE VIEW contabilidad.in_resultados_seleccion WITH (security_invoker = true) AS
SELECT rs.id, a.empacadora_id, rs.corte_id, rs.volumen_total_kg,
       rs.pct_exportacion_real, rs.pct_nacional_real,
       rs.desglose_calibre, rs.desglose_calidad, rs.fecha_proceso, rs.created_at
  FROM public.resultado_seleccion rs
  JOIN public.corte c ON c.id = rs.corte_id
  JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id;

CREATE VIEW contabilidad.in_ordenes_venta WITH (security_invoker = true) AS
SELECT ov.id AS orden_venta_id, ov.empacadora_id, ov.importador_id,
       ov.estado, ov.total_usd, ov.condiciones_pago, ov.incoterm,
       ov.fecha_orden, ov.fecha_entrega_real,
       lo.id AS linea_id, lo.calibre, lo.calidad, lo.cantidad_cajas,
       lo.precio_caja_usd, lo.corte_origen_id
  FROM public.orden_venta ov
  LEFT JOIN public.linea_orden_venta lo ON lo.orden_id = ov.id;

CREATE VIEW contabilidad.in_embarques WITH (security_invoker = true) AS
SELECT e.id, e.empacadora_id, e.orden_venta_id, e.fecha_salida,
       e.fecha_llegada_est, e.fecha_llegada_real, e.total_cajas,
       e.estado, e.created_at, e.updated_at
  FROM public.embarque e;

-- =====================================================================
-- VISTAS DE OUTPUT out_* — EL CONTRATO con AgroMesh
-- (ACCOUNTING_REQUIREMENTS.md §"HARD DATA — what AgroMesh NEEDS BACK")
-- Owner-security + filtro por current_empacadora(): tenant-scoped siempre.
-- Cambiar columnas aquí = romper el contrato -> coordinar con Abisai.
-- =====================================================================

-- P&L por calibre · consume: Admin Inicio (4 widgets)
CREATE VIEW contabilidad.out_pnl_calibre AS
WITH vol AS (
  -- kg por (corte, calibre) desde el JSONB de la seleccionadora,
  -- con el share del calibre dentro del corte para prorratear costos.
  SELECT a.empacadora_id, c.id AS corte_id, rs.fecha_proceso::date AS fecha,
         kv.key AS calibre,
         (kv.value #>> '{}')::numeric AS kg,
         SUM((kv.value #>> '{}')::numeric) OVER (PARTITION BY c.id) AS kg_corte
    FROM public.resultado_seleccion rs
    JOIN public.corte c ON c.id = rs.corte_id
    JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id
   CROSS JOIN LATERAL jsonb_each(rs.desglose_calibre) kv
),
costos_corte AS (
  SELECT co.corte_id,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'acarreo')            AS acarreo,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'corte_cuadrilla')    AS cuadrilla,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'empaque_materiales') AS empaque,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'costo_fijo_empaque') AS fijo
    FROM contabilidad.costo_operativo co
   WHERE co.corte_id IS NOT NULL
   GROUP BY co.corte_id
),
fruta_corte AS (
  SELECT c.id AS corte_id,
         (a.precio_por_kg * c.volumen_cortado_ton * 1000)::numeric AS costo_fruta
    FROM public.corte c
    JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id
),
costos_calibre AS (
  -- prorrateo por share de kg del calibre dentro del corte
  SELECT v.empacadora_id, v.fecha, v.calibre,
         SUM(v.kg) AS volumen_kg,
         SUM(COALESCE(fc.costo_fruta, 0) * v.kg / NULLIF(v.kg_corte, 0)) AS costo_fruta_mxn,
         SUM(COALESCE(cc.acarreo, 0)     * v.kg / NULLIF(v.kg_corte, 0)) AS costo_acarreo_mxn,
         SUM(COALESCE(cc.cuadrilla, 0)   * v.kg / NULLIF(v.kg_corte, 0)) AS costo_cuadrilla_mxn,
         SUM(COALESCE(cc.empaque, 0)     * v.kg / NULLIF(v.kg_corte, 0)) AS costo_empaque_mxn,
         SUM(COALESCE(cc.fijo, 0)        * v.kg / NULLIF(v.kg_corte, 0)) AS costo_fijo_mxn
    FROM vol v
    LEFT JOIN costos_corte cc ON cc.corte_id = v.corte_id
    LEFT JOIN fruta_corte fc  ON fc.corte_id = v.corte_id
   GROUP BY v.empacadora_id, v.fecha, v.calibre
),
ingresos AS (
  SELECT ov.empacadora_id,
         COALESCE(ov.fecha_entrega_real, ov.fecha_orden::date) AS fecha,
         lo.calibre,
         SUM(lo.cantidad_cajas * lo.precio_caja_usd) AS ingresos_usd,
         SUM(lo.cantidad_cajas)                      AS cajas_vendidas
    FROM public.linea_orden_venta lo
    JOIN public.orden_venta ov ON ov.id = lo.orden_id
   WHERE lo.calibre IS NOT NULL
   GROUP BY 1, 2, 3
),
fx_periodo AS (
  -- TC promedio del periodo desde las CxC facturadas; fallback al TC ref del tenant.
  SELECT cxc.empacadora_id, p.id AS periodo_id, AVG(cxc.tipo_cambio_factura) AS tc
    FROM contabilidad.cuenta_por_cobrar cxc
    JOIN contabilidad.periodo_contable p
      ON p.empacadora_id = cxc.empacadora_id
     AND cxc.fecha_emision BETWEEN p.fecha_inicio AND p.fecha_fin
   GROUP BY 1, 2
)
SELECT p.empacadora_id,
       p.id                                            AS periodo_id,
       p.anio, p.mes,
       COALESCE(i.calibre, cx.calibre)::text           AS calibre,
       COALESCE(i.ingresos_usd, 0)::numeric            AS ingresos_usd,
       (COALESCE(i.ingresos_usd, 0)
         * COALESCE(fx.tc, e.tipo_cambio_ref, 0))::numeric AS ingresos_mxn,
       COALESCE(cx.costo_fruta_mxn, 0)::numeric        AS costo_fruta_mxn,
       COALESCE(cx.costo_acarreo_mxn, 0)::numeric      AS costo_acarreo_mxn,
       COALESCE(cx.costo_cuadrilla_mxn, 0)::numeric    AS costo_cuadrilla_mxn,
       COALESCE(cx.costo_empaque_mxn, 0)::numeric      AS costo_empaque_mxn,
       COALESCE(cx.costo_fijo_mxn, 0)::numeric         AS costo_fijo_mxn,
       (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
        + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
        + COALESCE(cx.costo_fijo_mxn,0))::numeric      AS costo_total_mxn,
       (COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
        - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
           + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
           + COALESCE(cx.costo_fijo_mxn,0)))::numeric  AS margen_bruto_mxn,
       CASE WHEN COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0) > 0
            THEN ((COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
                   - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
                      + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
                      + COALESCE(cx.costo_fijo_mxn,0)))
                  / (COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)) * 100)
       END::numeric                                    AS margen_bruto_pct,
       CASE WHEN COALESCE(cx.volumen_kg, 0) > 0
            THEN ((COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
                   - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
                      + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
                      + COALESCE(cx.costo_fijo_mxn,0))) / cx.volumen_kg)
       END::numeric                                    AS margen_por_kg_mxn,
       COALESCE(cx.volumen_kg, 0)::numeric             AS volumen_kg,
       COALESCE(i.cajas_vendidas, 0)::bigint           AS cajas_vendidas
  FROM contabilidad.periodo_contable p
  JOIN public.empacadora e ON e.id = p.empacadora_id
  LEFT JOIN ingresos i
    ON i.empacadora_id = p.empacadora_id
   AND i.fecha BETWEEN p.fecha_inicio AND p.fecha_fin
  LEFT JOIN costos_calibre cx
    ON cx.empacadora_id = p.empacadora_id
   AND cx.fecha BETWEEN p.fecha_inicio AND p.fecha_fin
   AND cx.calibre = i.calibre
  LEFT JOIN fx_periodo fx
    ON fx.empacadora_id = p.empacadora_id AND fx.periodo_id = p.id
 WHERE p.empacadora_id = contabilidad.current_empacadora()
   AND COALESCE(i.calibre, cx.calibre) IS NOT NULL;

-- AR aging · consume: Ventas Embarques + Admin
CREATE VIEW contabilidad.out_ar_aging AS
SELECT cxc.empacadora_id,
       cxc.id              AS cxc_id,
       cxc.orden_venta_id,
       cxc.importador_id,
       cxc.monto_usd,
       cxc.saldo_pendiente_usd,
       cxc.fecha_emision,
       cxc.fecha_vencimiento,
       cxc.fecha_pago_real,
       (current_date - cxc.fecha_emision)::int AS dias_transcurridos,
       CASE
         WHEN cxc.estado IN ('pagada', 'cancelada')          THEN cxc.estado::text
         WHEN current_date >  cxc.fecha_vencimiento          THEN 'vencida'
         WHEN current_date >= cxc.fecha_vencimiento - 4      THEN 'por_vencer_21_25'
         ELSE 'corriente'
       END::text AS bucket,
       cxc.estado::text AS estado
  FROM contabilidad.cuenta_por_cobrar cxc
 WHERE cxc.empacadora_id = contabilidad.current_empacadora();

-- AP status · consume: Admin (cash planning)
CREATE VIEW contabilidad.out_ap_status AS
SELECT cxp.empacadora_id,
       cxp.id AS cxp_id,
       cxp.acuerdo_id,
       cxp.corte_id,
       CASE WHEN cxp.productor_id IS NOT NULL THEN 'productor' ELSE 'cuadrilla' END::text AS acreedor_tipo,
       cxp.productor_id,
       cxp.cuadrilla_id,
       cxp.monto_mxn,
       cxp.saldo_pendiente_mxn,
       cxp.fecha_emision,
       cxp.fecha_vencimiento,
       cxp.estado::text AS estado
  FROM contabilidad.cuenta_por_pagar cxp
 WHERE cxp.empacadora_id = contabilidad.current_empacadora();

-- Salud del negocio · consume: Owner hero metric
CREATE VIEW contabilidad.out_salud_negocio AS
WITH resultado AS (
  SELECT p.empacadora_id, p.id AS periodo_id, p.anio, p.mes,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN la.haber_mxn - la.debe_mxn ELSE 0 END) AS ingresos,
         SUM(CASE WHEN cu.tipo = 'egreso'  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS egresos
    FROM contabilidad.periodo_contable p
    LEFT JOIN contabilidad.asiento_contable a
      ON a.periodo_id = p.id AND a.estado = 'confirmado'
    LEFT JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    LEFT JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id
   GROUP BY 1, 2, 3, 4
),
caja AS (
  -- saldo acumulado de cuentas de bancos (códigos 11xx) hasta el fin de cada periodo
  SELECT p.id AS periodo_id,
         SUM(la.debe_mxn - la.haber_mxn) AS saldo
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.asiento_contable a
      ON a.empacadora_id = p.empacadora_id AND a.estado = 'confirmado'
     AND a.fecha <= p.fecha_fin
    JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id AND cu.codigo LIKE '11%'
   GROUP BY 1
),
exposicion AS (
  SELECT p.id AS periodo_id,
         SUM(cxc.saldo_pendiente_usd) FILTER (WHERE cxc.estado IN ('pendiente','parcial')) AS cxc_abierta,
         SUM(cxc.saldo_pendiente_usd) FILTER (
           WHERE cxc.estado IN ('pendiente','parcial') AND cxc.fecha_vencimiento < current_date) AS cxc_vencida
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.cuenta_por_cobrar cxc
      ON cxc.empacadora_id = p.empacadora_id
     AND cxc.fecha_emision <= p.fecha_fin
   GROUP BY 1
),
deuda AS (
  SELECT p.id AS periodo_id,
         SUM(cxp.saldo_pendiente_mxn) FILTER (WHERE cxp.estado IN ('pendiente','parcial')) AS cxp_abierta
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.cuenta_por_pagar cxp
      ON cxp.empacadora_id = p.empacadora_id
     AND cxp.fecha_emision <= p.fecha_fin
   GROUP BY 1
)
SELECT r.empacadora_id, r.periodo_id, r.anio, r.mes,
       (r.ingresos - r.egresos)::numeric AS margen_neto_mxn,
       CASE WHEN r.ingresos > 0
            THEN ((r.ingresos - r.egresos) / r.ingresos * 100) END::numeric AS margen_neto_pct,
       (CASE WHEN r.ingresos > 0 THEN (r.ingresos - r.egresos) / r.ingresos * 100 END
        - LAG(CASE WHEN r.ingresos > 0 THEN (r.ingresos - r.egresos) / r.ingresos * 100 END)
          OVER (PARTITION BY r.empacadora_id ORDER BY r.anio, r.mes))::numeric AS tendencia_margen_pct,
       COALESCE(c.saldo, 0)::numeric        AS posicion_caja_mxn,
       COALESCE(x.cxc_abierta, 0)::numeric  AS cxc_abierta_usd,
       COALESCE(x.cxc_vencida, 0)::numeric  AS cxc_vencida_usd,
       COALESCE(d.cxp_abierta, 0)::numeric  AS cxp_abierta_mxn
  FROM resultado r
  LEFT JOIN caja c       ON c.periodo_id = r.periodo_id
  LEFT JOIN exposicion x ON x.periodo_id = r.periodo_id
  LEFT JOIN deuda d      ON d.periodo_id = r.periodo_id
 WHERE r.empacadora_id = contabilidad.current_empacadora();

-- CFDI status por orden · consume: Ventas Pedidos
CREATE VIEW contabilidad.out_cfdi_status AS
SELECT ov.empacadora_id,
       ov.id AS orden_venta_id,
       f.id  AS factura_cfdi_id,
       f.uuid_fiscal,
       f.serie,
       f.folio,
       COALESCE(f.estatus::text, 'sin_facturar') AS estatus,
       f.total_mxn,
       f.total_usd,
       f.fecha_timbrado,
       f.xml_url,
       f.pdf_url
  FROM public.orden_venta ov
  LEFT JOIN contabilidad.factura_cfdi f
    ON f.orden_venta_id = ov.id AND f.tipo_comprobante = 'ingreso'
 WHERE ov.empacadora_id = contabilidad.current_empacadora();

-- Cierre de periodo · consume: Admin + Owner ("monthly truth")
CREATE VIEW contabilidad.out_cierre_periodo AS
WITH agregado AS (
  SELECT p.empacadora_id, p.id AS periodo_id, p.anio, p.mes,
         p.estado::text AS estado_periodo, p.fecha_cierre,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN la.haber_mxn - la.debe_mxn ELSE 0 END) AS ingresos_mxn,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN COALESCE(la.haber_usd,0) - COALESCE(la.debe_usd,0) ELSE 0 END) AS ingresos_usd,
         SUM(CASE WHEN cu.tipo = 'egreso' AND a.tipo IN ('compra_fruta','costo_operativo')
                  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS cogs_mxn,
         SUM(CASE WHEN cu.tipo = 'egreso' AND a.tipo NOT IN ('compra_fruta','costo_operativo','ajuste_fx')
                  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS opex_mxn,
         SUM(CASE WHEN a.tipo = 'ajuste_fx' THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS ajuste_fx_mxn
    FROM contabilidad.periodo_contable p
    LEFT JOIN contabilidad.asiento_contable a
      ON a.periodo_id = p.id AND a.estado = 'confirmado'
    LEFT JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    LEFT JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id
   GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT empacadora_id, periodo_id, anio, mes, estado_periodo,
       ingresos_mxn::numeric, ingresos_usd::numeric, cogs_mxn::numeric, opex_mxn::numeric,
       ajuste_fx_mxn::numeric,
       (ingresos_mxn - cogs_mxn - opex_mxn - ajuste_fx_mxn)::numeric AS neto_mxn,
       fecha_cierre
  FROM agregado
 WHERE empacadora_id = contabilidad.current_empacadora();
