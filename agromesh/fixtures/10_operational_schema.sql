-- =====================================================================
-- AgroMesh — V1 schema (PostgreSQL)
-- Generated from DATA_MODEL.md v1.0 · 2026-06-06
-- 31 entities across 9 domains.
--
-- Conventions:
--   * UUID PKs via gen_random_uuid() (pgcrypto).
--   * created_at / updated_at TIMESTAMPTZ added to every table (Design note §4).
--   * Money columns name their unit (_mxn / _usd / _kg / _caja).
--   * ENUMs are named types (see "Enumerated types").
--   * ON DELETE: RESTRICT by default; SET NULL for optional links.
--
-- This DDL honors the spec exactly. Proposed additions (Usuario/auth,
-- tenancy join tables, PostGIS) are at the bottom, commented out, pending
-- your decisions in DATA_MODEL.md "Design notes".
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- Enumerated types
-- ---------------------------------------------------------------------
CREATE TYPE acopio_tipo              AS ENUM ('empleado','contratista');
CREATE TYPE importador_tipo          AS ENUM ('distribuidor','cadena','foodservice','mayorista');
CREATE TYPE visita_tipo              AS ENUM ('visita','negociacion');
CREATE TYPE negociacion_estado       AS ENUM ('abierta','acordada','cancelada','en_espera');
CREATE TYPE acuerdo_estado           AS ENUM ('pendiente','en_corte','completado','cancelado');
CREATE TYPE corte_estado             AS ENUM ('programado','en_proceso','completado');
CREATE TYPE orden_venta_estado       AS ENUM ('cotizada','confirmada','en_transito','entregada','cancelada');
CREATE TYPE lead_fuente              AS ENUM ('usda_data','referral','web','cold_outreach');
CREATE TYPE lead_estado              AS ENUM ('nuevo','contactado','negociando','convertido','descartado');
CREATE TYPE demanda_tendencia        AS ENUM ('alta','estable','baja');
CREATE TYPE inventario_estado        AS ENUM ('disponible','comprometido','en_transito');
CREATE TYPE embarque_estado          AS ENUM ('preparando','en_transito','en_aduana','entregado');
CREATE TYPE necesidad_prioridad      AS ENUM ('alta','media','baja');
CREATE TYPE necesidad_estado         AS ENUM ('abierta','cubierta','parcial');
CREATE TYPE necesidad_origen         AS ENUM ('orden_venta','demanda_mercado','especulacion');
CREATE TYPE sicoa_estatus            AS ENUM ('disponible','bloqueada','en_revision','liberada');
CREATE TYPE sicoa_corte_estado       AS ENUM ('pendiente','programado','confirmado','rechazado');
CREATE TYPE notif_agente_origen      AS ENUM ('calculadora','ventas');
CREATE TYPE notif_canal              AS ENUM ('whatsapp','email','crm','sms');
CREATE TYPE notif_destinatario_tipo  AS ENUM ('acopio','importador','contacto','empacadora');
CREATE TYPE notif_tipo               AS ENUM ('necesidad_cubierta','lead_nuevo','precio_cambio','sicoa_cambio','alerta_huerta','corte_programado','seguimiento');
CREATE TYPE notif_estado             AS ENUM ('enviada','entregada','leida','fallida');

-- =====================================================================
-- DOMAIN 1 — Actors
-- =====================================================================

CREATE TABLE empacadora (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre               VARCHAR(200) NOT NULL,
    ubicacion            VARCHAR(300),
    capacidad_diaria_ton DECIMAL(8,2),
    costo_fijo_por_kg    DECIMAL(6,2),
    utilidad_min_por_kg  DECIMAL(6,2),
    tipo_cambio_ref      DECIMAL(6,2),
    config_pricing       JSONB,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE productor (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(200) NOT NULL,
    telefono    VARCHAR(20),
    ubicacion   VARCHAR(300),
    num_huertas INT,                         -- derived; see Design note §3
    notas       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE importador (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_empresa         VARCHAR(200) NOT NULL,
    ubicacion_us           VARCHAR(300),
    tipo                   importador_tipo,
    canal_venta            VARCHAR(100),
    volumen_mensual_cajas  INT,
    calibres_preferidos    JSONB,
    condiciones_pago_usual VARCHAR(100),
    activo                 BOOLEAN NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cuadrilla (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_corte           VARCHAR(200),
    nombre                  VARCHAR(200) NOT NULL,
    certificacion_inocuidad BOOLEAN NOT NULL DEFAULT FALSE,
    herramientas_reglamento BOOLEAN NOT NULL DEFAULT FALSE,
    precio_por_kg           DECIMAL(6,2),
    capacidad_personas      INT,
    notas                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE acopio (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id     UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    nombre            VARCHAR(200) NOT NULL,
    telefono_whatsapp VARCHAR(20),
    zona_operacion    VARCHAR(200),
    tipo              acopio_tipo,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta        DATE,
    notas             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE huerta (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    productor_id          UUID NOT NULL REFERENCES productor(id) ON DELETE RESTRICT,
    codigo_hue            VARCHAR(50),
    ubicacion_gps         POINT,                  -- consider PostGIS; Design note §6
    superficie_ha         DECIMAL(6,2),
    altitud_msnm          INT,
    fecha_ultimo_corte    DATE,
    intervalo_corte_meses INT,
    notas                 TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE contacto_importador (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    importador_id UUID NOT NULL REFERENCES importador(id) ON DELETE CASCADE,
    nombre        VARCHAR(200) NOT NULL,
    cargo         VARCHAR(100),
    telefono      VARCHAR(20),
    email         VARCHAR(200),
    es_decisor    BOOLEAN NOT NULL DEFAULT FALSE,
    notas         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 4 — Market & Prices  (created early; Necesidad_Compra depends on Demanda_Mercado)
-- =====================================================================

CREATE TABLE precio_mercado_usda (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha                DATE NOT NULL,
    origen               VARCHAR(50),
    calibre              VARCHAR(10),
    precio_min_usd       DECIMAL(8,2),
    precio_max_usd       DECIMAL(8,2),
    precio_prom_usd      DECIMAL(8,2),
    volumen_importado_lbs DECIMAL(12,2),
    terminal_market      VARCHAR(50),
    fuente_url           VARCHAR(500),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE demanda_mercado (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha                 DATE NOT NULL,
    calibre               VARCHAR(10),
    region_us             VARCHAR(50),
    volumen_demandado_est DECIMAL(10,2),
    tendencia             demanda_tendencia,
    temporada             VARCHAR(50),
    competidores_activos  JSONB,
    fuente                VARCHAR(100),
    notas_agente          TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE precio_empaque (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id           UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    fecha                   DATE NOT NULL,
    calibre                 VARCHAR(10),
    precio_venta_usd_caja   DECIMAL(8,2),
    tipo_cambio             DECIMAL(6,2),
    precio_compra_max_kg_mxn DECIMAL(6,2),
    costo_fijo_kg           DECIMAL(6,2),
    utilidad_kg             DECIMAL(6,2),
    margen_pct              DECIMAL(5,2),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 3 — Sales Operations US  (Orden_Venta before Necesidad_Compra)
-- =====================================================================

CREATE TABLE orden_venta (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id          UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    importador_id          UUID NOT NULL REFERENCES importador(id) ON DELETE RESTRICT,
    contacto_id            UUID REFERENCES contacto_importador(id) ON DELETE SET NULL,
    fecha_orden            TIMESTAMPTZ,
    fecha_entrega_estimada DATE,
    fecha_entrega_real     DATE,
    estado                 orden_venta_estado NOT NULL DEFAULT 'cotizada',
    total_usd              DECIMAL(12,2),
    condiciones_pago       VARCHAR(100),
    incoterm               VARCHAR(20),
    notas                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE lead_venta (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id          UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    importador_id          UUID REFERENCES importador(id) ON DELETE SET NULL,
    nombre_empresa         VARCHAR(200),
    contacto_nombre        VARCHAR(200),
    email                  VARCHAR(200),
    telefono               VARCHAR(20),
    calibre_interes        VARCHAR(50),
    volumen_estimado_cajas INT,
    fecha_necesidad        DATE,
    fuente                 lead_fuente,
    estado                 lead_estado NOT NULL DEFAULT 'nuevo',
    score                  INT CHECK (score BETWEEN 0 AND 100),
    notas_agente           TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE historial_compra_importador (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    importador_id UUID NOT NULL REFERENCES importador(id) ON DELETE CASCADE,
    fecha         DATE,
    calibre       VARCHAR(10),
    calidad       VARCHAR(20),
    volumen_cajas INT,
    precio_usd_caja DECIMAL(8,2),
    satisfaccion  INT CHECK (satisfaccion BETWEEN 1 AND 5),
    notas         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 7 — Bridge: Necesidad_Compra
-- =====================================================================

CREATE TABLE necesidad_compra (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id         UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    fecha_necesidad       DATE,
    calibre               VARCHAR(10),
    calidad               VARCHAR(20),
    volumen_necesario_ton DECIMAL(8,2),
    volumen_comprado_ton  DECIMAL(8,2) DEFAULT 0,
    volumen_faltante_ton  DECIMAL(8,2),          -- derived; see Design note §3
    prioridad             necesidad_prioridad,
    estado                necesidad_estado NOT NULL DEFAULT 'abierta',
    origen                necesidad_origen NOT NULL,
    orden_venta_id        UUID REFERENCES orden_venta(id) ON DELETE SET NULL,
    demanda_mercado_id    UUID REFERENCES demanda_mercado(id) ON DELETE SET NULL,
    notas_agente          TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 2 — Purchase Operations MX
-- =====================================================================

CREATE TABLE visita_huerta (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    acopio_id                UUID NOT NULL REFERENCES acopio(id) ON DELETE RESTRICT,
    huerta_id                UUID NOT NULL REFERENCES huerta(id) ON DELETE RESTRICT,
    fecha                    TIMESTAMPTZ,
    tipo                     visita_tipo,
    est_volumen_ton          DECIMAL(8,2),
    est_calibre_predominante VARCHAR(20),
    est_pct_exportacion      INT,
    est_pct_nacional         INT,
    ubicacion_gps            POINT,
    fotos                    JSONB,
    notas                    TEXT,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE negociacion_compra (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visita_id              UUID REFERENCES visita_huerta(id) ON DELETE SET NULL,   -- nullable: async
    acopio_id              UUID NOT NULL REFERENCES acopio(id) ON DELETE RESTRICT,
    huerta_id              UUID NOT NULL REFERENCES huerta(id) ON DELETE RESTRICT,
    empacadora_id          UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    fecha_inicio           TIMESTAMPTZ,
    fecha_cierre           TIMESTAMPTZ,
    estado                 negociacion_estado NOT NULL DEFAULT 'abierta',
    precio_ofrecido_kg     DECIMAL(6,2),
    precio_acordado_kg     DECIMAL(6,2),
    calibres_solicitados   JSONB,
    volumen_negociado_ton  DECIMAL(8,2),
    precio_ref_usda_usd    DECIMAL(6,2),
    tipo_cambio_usado      DECIMAL(6,2),
    margen_calculado_kg    DECIMAL(6,2),
    dentro_margen_utilidad BOOLEAN,
    aprobacion_hitl        BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_hitl            TEXT,
    necesidad_compra_id    UUID REFERENCES necesidad_compra(id) ON DELETE SET NULL,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE acuerdo_compra_venta (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    negociacion_id        UUID NOT NULL REFERENCES negociacion_compra(id) ON DELETE RESTRICT,
    empacadora_id         UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    productor_id          UUID NOT NULL REFERENCES productor(id) ON DELETE RESTRICT,
    huerta_id             UUID NOT NULL REFERENCES huerta(id) ON DELETE RESTRICT,
    precio_por_kg         DECIMAL(6,2),
    volumen_acordado_ton  DECIMAL(8,2),
    fecha_corte_programada DATE,
    estado                acuerdo_estado NOT NULL DEFAULT 'pendiente',
    terminos_condiciones  TEXT,
    documento_url         VARCHAR(500),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE corte (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    acuerdo_id            UUID NOT NULL REFERENCES acuerdo_compra_venta(id) ON DELETE RESTRICT,
    huerta_id             UUID NOT NULL REFERENCES huerta(id) ON DELETE RESTRICT,
    cuadrilla_id          UUID REFERENCES cuadrilla(id) ON DELETE SET NULL,
    acopio_id             UUID REFERENCES acopio(id) ON DELETE SET NULL,
    fecha                 DATE,
    hora_inicio           TIME,
    hora_fin              TIME,
    volumen_cortado_ton   DECIMAL(8,2),
    costo_cuadrilla_por_kg DECIMAL(6,2),
    incidencias           TEXT,
    notas_acopio          TEXT,
    estado                corte_estado NOT NULL DEFAULT 'programado',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE resultado_seleccion (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    corte_id            UUID NOT NULL UNIQUE REFERENCES corte(id) ON DELETE CASCADE,  -- 1:1
    volumen_total_kg    DECIMAL(10,2),
    pct_exportacion_real INT,
    pct_nacional_real   INT,
    desglose_calibre    JSONB,
    desglose_calidad    JSONB,
    fecha_proceso       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE linea_orden_venta (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_id        UUID NOT NULL REFERENCES orden_venta(id) ON DELETE CASCADE,
    calibre         VARCHAR(10),
    calidad         VARCHAR(20),
    presentacion    VARCHAR(50),
    cantidad_cajas  INT,
    precio_caja_usd DECIMAL(8,2),
    corte_origen_id UUID REFERENCES corte(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 5 — Inventory & Logistics
-- =====================================================================

CREATE TABLE inventario_disponible (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id    UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    fecha            DATE,
    calibre          VARCHAR(10),
    calidad          VARCHAR(20),
    cajas_disponibles INT,
    huerta_origen_id UUID REFERENCES huerta(id) ON DELETE SET NULL,
    corte_id         UUID REFERENCES corte(id) ON DELETE SET NULL,
    estado           inventario_estado NOT NULL DEFAULT 'disponible',
    fecha_empaque    DATE,
    vida_anaquel_dias INT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE embarque (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    orden_venta_id      UUID NOT NULL REFERENCES orden_venta(id) ON DELETE RESTRICT,
    fecha_salida        DATE,
    fecha_llegada_est   DATE,
    fecha_llegada_real  DATE,
    transportista       VARCHAR(200),
    num_contenedor      VARCHAR(50),
    temperatura_control DECIMAL(4,1),
    total_cajas         INT,
    estado              embarque_estado NOT NULL DEFAULT 'preparando',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE capacidad_proceso (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id            UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    fecha                    DATE,
    capacidad_total_ton      DECIMAL(8,2),
    capacidad_usada_ton      DECIMAL(8,2),
    capacidad_disponible_ton DECIMAL(8,2),       -- derived; see Design note §3
    cortes_programados       INT,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 6 — Reputation & Scoring
-- =====================================================================

CREATE TABLE score_acopio (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    acopio_id        UUID NOT NULL REFERENCES acopio(id) ON DELETE CASCADE,
    corte_id         UUID REFERENCES corte(id) ON DELETE SET NULL,
    visita_id        UUID REFERENCES visita_huerta(id) ON DELETE SET NULL,
    vol_estimado_ton DECIMAL(8,2),
    vol_real_ton     DECIMAL(8,2),
    desviacion_vol_pct DECIMAL(5,2),
    precision_calibre DECIMAL(5,2),
    precision_calidad DECIMAL(5,2),
    score_general    DECIMAL(5,2),
    fecha            DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE score_huerta (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    huerta_id             UUID NOT NULL REFERENCES huerta(id) ON DELETE CASCADE,
    score_calidad_promedio DECIMAL(5,2),
    score_rendimiento     DECIMAL(5,2),
    score_confiabilidad   DECIMAL(5,2),
    num_cortes_historicos INT,
    ultimo_corte          DATE,
    alertas               TEXT,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE score_productor (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    productor_id       UUID NOT NULL REFERENCES productor(id) ON DELETE CASCADE,
    score_cumplimiento DECIMAL(5,2),
    score_calidad_fruta DECIMAL(5,2),
    score_general      DECIMAL(5,2),
    num_transacciones  INT,
    alertas            TEXT,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE score_cuadrilla (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cuadrilla_id       UUID NOT NULL REFERENCES cuadrilla(id) ON DELETE CASCADE,
    score_velocidad    DECIMAL(5,2),
    score_calidad_corte DECIMAL(5,2),
    score_inocuidad    DECIMAL(5,2),
    score_general      DECIMAL(5,2),
    num_cortes         INT,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 8 — SICOA Integration
-- =====================================================================

CREATE TABLE sicoa_huerta_sync (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    huerta_id                UUID NOT NULL REFERENCES huerta(id) ON DELETE CASCADE,
    sicoa_id                 VARCHAR(50),
    estatus_sicoa            sicoa_estatus,
    fecha_sync               TIMESTAMPTZ,
    datos_excel_raw          JSONB,
    certificacion_fito       BOOLEAN,
    fecha_venc_certificacion DATE,
    zona_sicoa               VARCHAR(100),
    cambio_detectado         BOOLEAN NOT NULL DEFAULT FALSE,
    detalle_cambio           TEXT,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sicoa_programacion_corte (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    corte_id              UUID NOT NULL REFERENCES corte(id) ON DELETE CASCADE,
    acuerdo_id            UUID REFERENCES acuerdo_compra_venta(id) ON DELETE SET NULL,
    huerta_id             UUID REFERENCES huerta(id) ON DELETE SET NULL,
    sicoa_huerta_id       VARCHAR(50),
    fecha_programada      DATE,
    estado_sicoa          sicoa_corte_estado NOT NULL DEFAULT 'pendiente',
    sicoa_folio           VARCHAR(50),
    fecha_registro_sicoa  TIMESTAMPTZ,
    intentos_registro     INT NOT NULL DEFAULT 0,
    error_sicoa           TEXT,
    screenshot_confirmacion VARCHAR(500),
    notas                 TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sicoa_credenciales (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID NOT NULL REFERENCES empacadora(id) ON DELETE CASCADE,
    usuario_sicoa       VARCHAR(100),
    password_encrypted  VARCHAR(500),            -- encrypted at rest, never plaintext
    url_portal          VARCHAR(300),
    ultimo_login_exitoso TIMESTAMPTZ,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- DOMAIN 9 — Notifications
-- =====================================================================

CREATE TABLE notificacion_agente (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empacadora_id       UUID NOT NULL REFERENCES empacadora(id) ON DELETE RESTRICT,
    agente_origen       notif_agente_origen,
    canal               notif_canal,
    destinatario_tipo   notif_destinatario_tipo,
    destinatario_id     UUID,                    -- polymorphic, no FK (Design note §5)
    destinatario_nombre VARCHAR(200),
    tipo_notificacion   notif_tipo,
    mensaje             TEXT,
    entidad_relacionada VARCHAR(50),             -- polymorphic
    entidad_id          UUID,                    -- polymorphic, no FK
    estado              notif_estado NOT NULL DEFAULT 'enviada',
    fecha_envio         TIMESTAMPTZ,
    fecha_lectura       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- Indexes — tenant scoping + hot foreign keys + lookups
-- =====================================================================
CREATE INDEX idx_acopio_empacadora        ON acopio(empacadora_id);
CREATE INDEX idx_acopio_whatsapp          ON acopio(telefono_whatsapp);
CREATE INDEX idx_huerta_productor         ON huerta(productor_id);
CREATE INDEX idx_huerta_codigo_hue        ON huerta(codigo_hue);
CREATE INDEX idx_contacto_importador      ON contacto_importador(importador_id);
CREATE INDEX idx_orden_empacadora         ON orden_venta(empacadora_id);
CREATE INDEX idx_orden_importador         ON orden_venta(importador_id);
CREATE INDEX idx_lead_empacadora          ON lead_venta(empacadora_id);
CREATE INDEX idx_hist_importador          ON historial_compra_importador(importador_id);
CREATE INDEX idx_necesidad_empacadora     ON necesidad_compra(empacadora_id);
CREATE INDEX idx_necesidad_estado         ON necesidad_compra(estado);
CREATE INDEX idx_visita_acopio            ON visita_huerta(acopio_id);
CREATE INDEX idx_visita_huerta            ON visita_huerta(huerta_id);
CREATE INDEX idx_negociacion_empacadora   ON negociacion_compra(empacadora_id);
CREATE INDEX idx_negociacion_necesidad    ON negociacion_compra(necesidad_compra_id);
CREATE INDEX idx_negociacion_estado       ON negociacion_compra(estado);
CREATE INDEX idx_acuerdo_empacadora       ON acuerdo_compra_venta(empacadora_id);
CREATE INDEX idx_acuerdo_negociacion      ON acuerdo_compra_venta(negociacion_id);
CREATE INDEX idx_corte_acuerdo            ON corte(acuerdo_id);
CREATE INDEX idx_corte_huerta             ON corte(huerta_id);
CREATE INDEX idx_linea_orden             ON linea_orden_venta(orden_id);
CREATE INDEX idx_inventario_empacadora    ON inventario_disponible(empacadora_id);
CREATE INDEX idx_embarque_orden           ON embarque(orden_venta_id);
CREATE INDEX idx_precio_empaque_emp       ON precio_empaque(empacadora_id, fecha);
CREATE INDEX idx_usda_fecha_calibre       ON precio_mercado_usda(fecha, calibre);
CREATE INDEX idx_score_acopio_acopio      ON score_acopio(acopio_id);
CREATE INDEX idx_sicoa_sync_huerta        ON sicoa_huerta_sync(huerta_id);
CREATE INDEX idx_sicoa_prog_corte         ON sicoa_programacion_corte(corte_id);
CREATE INDEX idx_notif_empacadora         ON notificacion_agente(empacadora_id, estado);

-- =====================================================================
-- PROPOSED ADDITIONS — pending decisions (DATA_MODEL.md Design notes)
-- Uncomment after confirming. NOT part of the 31-entity baseline.
-- =====================================================================

-- §7 Usuario / Auth — dashboard logins + role-based access.
-- CREATE TYPE usuario_rol AS ENUM
--   ('supervisor','admin','owner','ventas','ops_agromesh');
-- CREATE TABLE usuario (
--     id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     empacadora_id UUID REFERENCES empacadora(id) ON DELETE CASCADE,  -- NULL for ops_agromesh
--     nombre        VARCHAR(200) NOT NULL,
--     email         VARCHAR(200) UNIQUE NOT NULL,
--     rol           usuario_rol NOT NULL,
--     telefono_whatsapp VARCHAR(20),
--     activo        BOOLEAN NOT NULL DEFAULT TRUE,
--     ultimo_login  TIMESTAMPTZ,
--     created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
--     updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
-- );

-- §2 Tenancy join tables — if producers/orchards are shared across tenants.
-- CREATE TABLE empacadora_productor (
--     empacadora_id UUID REFERENCES empacadora(id) ON DELETE CASCADE,
--     productor_id  UUID REFERENCES productor(id)  ON DELETE CASCADE,
--     PRIMARY KEY (empacadora_id, productor_id)
-- );

-- §6 PostGIS — swap POINT for geography(Point,4326) for distance/routing.
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- ALTER TABLE huerta        ALTER COLUMN ubicacion_gps TYPE geography(Point,4326)
--   USING ST_SetSRID(ST_MakePoint(ubicacion_gps[0], ubicacion_gps[1]),4326);
-- ALTER TABLE visita_huerta ALTER COLUMN ubicacion_gps TYPE geography(Point,4326)
--   USING ST_SetSRID(ST_MakePoint(ubicacion_gps[0], ubicacion_gps[1]),4326);
