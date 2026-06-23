--
-- PostgreSQL database dump
--

\restrict nsjSqVggz65dhah80n4NxmmaLtQtkngCQHJi78toWKmJ19GEdBdTF8QP3AcP1Nx

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: agent; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA agent;


--
-- Name: comms; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA comms;


--
-- Name: core; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA core;


--
-- Name: ops; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ops;


--
-- Name: sales; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sales;


--
-- Name: accion_tipo; Type: TYPE; Schema: agent; Owner: -
--

CREATE TYPE agent.accion_tipo AS ENUM (
    'transcribir_audio',
    'normalizar_mensaje',
    'calcular_precio',
    'proponer_oferta',
    'escalar_humano',
    'generar_acuerdo',
    'enviar_acuerdo',
    'registrar_visita',
    'cerrar_negociacion',
    'avisar_demanda_cubierta',
    'sincronizar_sicoa',
    'programar_corte_sicoa',
    'generar_lead',
    'enviar_notificacion',
    'otro'
);


--
-- Name: evento_score_tipo; Type: TYPE; Schema: agent; Owner: -
--

CREATE TYPE agent.evento_score_tipo AS ENUM (
    'estimacion_vs_real',
    'cumplimiento_acuerdo',
    'calidad_corte',
    'manual',
    'recomputacion'
);


--
-- Name: necesidad_estado; Type: TYPE; Schema: agent; Owner: -
--

CREATE TYPE agent.necesidad_estado AS ENUM (
    'abierta',
    'parcial',
    'cubierta',
    'cancelada',
    'vencida'
);


--
-- Name: necesidad_origen; Type: TYPE; Schema: agent; Owner: -
--

CREATE TYPE agent.necesidad_origen AS ENUM (
    'orden_venta',
    'demanda_mercado',
    'especulacion',
    'inventario_minimo'
);


--
-- Name: necesidad_prioridad; Type: TYPE; Schema: agent; Owner: -
--

CREATE TYPE agent.necesidad_prioridad AS ENUM (
    'baja',
    'media',
    'alta',
    'critica'
);


--
-- Name: chat_tipo; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.chat_tipo AS ENUM (
    'directo',
    'grupo',
    'broadcast'
);


--
-- Name: flujo_tipo; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.flujo_tipo AS ENUM (
    'onboarding_huerta',
    'registro_visita',
    'negociacion',
    'seguimiento_corte',
    'codigo_acceso',
    'consulta_libre',
    'otro'
);


--
-- Name: mensaje_direccion; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.mensaje_direccion AS ENUM (
    'entrante',
    'saliente'
);


--
-- Name: mensaje_tipo; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.mensaje_tipo AS ENUM (
    'texto',
    'voz',
    'foto',
    'video',
    'ubicacion',
    'pdf',
    'documento',
    'sticker'
);


--
-- Name: notificacion_canal; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.notificacion_canal AS ENUM (
    'whatsapp',
    'email',
    'sms',
    'crm',
    'webhook'
);


--
-- Name: notificacion_estado; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.notificacion_estado AS ENUM (
    'pendiente',
    'enviada',
    'entregada',
    'leida',
    'fallida'
);


--
-- Name: notificacion_tipo; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.notificacion_tipo AS ENUM (
    'necesidad_cubierta',
    'necesidad_critica',
    'lead_nuevo',
    'precio_cambio',
    'sicoa_cambio_huerta',
    'sicoa_corte_programado',
    'alerta_huerta',
    'alerta_score',
    'seguimiento_acuerdo',
    'recordatorio_corte',
    'otro'
);


--
-- Name: remitente_tipo; Type: TYPE; Schema: comms; Owner: -
--

CREATE TYPE comms.remitente_tipo AS ENUM (
    'acopio',
    'agente',
    'jefe_compras',
    'productor',
    'sistema',
    'importador'
);


--
-- Name: acopio_tipo; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.acopio_tipo AS ENUM (
    'empleado',
    'contratista',
    'coyote'
);


--
-- Name: usuario_rol; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.usuario_rol AS ENUM (
    'jefe_compras',
    'admin',
    'observador',
    'ventas'
);


--
-- Name: acuerdo_status; Type: TYPE; Schema: ops; Owner: -
--

CREATE TYPE ops.acuerdo_status AS ENUM (
    'borrador',
    'enviado',
    'confirmado',
    'rechazado',
    'vencido'
);


--
-- Name: corte_status; Type: TYPE; Schema: ops; Owner: -
--

CREATE TYPE ops.corte_status AS ENUM (
    'programado',
    'en_curso',
    'completado',
    'cancelado'
);


--
-- Name: negociacion_status; Type: TYPE; Schema: ops; Owner: -
--

CREATE TYPE ops.negociacion_status AS ENUM (
    'abierta',
    'propuesta',
    'pausada',
    'acordada',
    'rechazada',
    'cancelada',
    'vencida'
);


--
-- Name: visita_status; Type: TYPE; Schema: ops; Owner: -
--

CREATE TYPE ops.visita_status AS ENUM (
    'en_curso',
    'cerrada',
    'cancelada'
);


--
-- Name: embarque_status; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.embarque_status AS ENUM (
    'preparando',
    'en_transito',
    'en_aduana',
    'entregado',
    'incidente'
);


--
-- Name: importador_tipo; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.importador_tipo AS ENUM (
    'distribuidor',
    'cadena_retail',
    'foodservice',
    'mayorista',
    'broker'
);


--
-- Name: inventario_status; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.inventario_status AS ENUM (
    'disponible',
    'comprometido',
    'en_transito',
    'vendido',
    'descartado'
);


--
-- Name: lead_fuente; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.lead_fuente AS ENUM (
    'usda_data',
    'referral',
    'web',
    'cold_outreach',
    'evento',
    'otro'
);


--
-- Name: lead_status; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.lead_status AS ENUM (
    'nuevo',
    'contactado',
    'negociando',
    'convertido',
    'descartado'
);


--
-- Name: orden_venta_status; Type: TYPE; Schema: sales; Owner: -
--

CREATE TYPE sales.orden_venta_status AS ENUM (
    'cotizada',
    'confirmada',
    'en_transito',
    'entregada',
    'cancelada'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accion; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.accion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tipo agent.accion_tipo NOT NULL,
    visita_id uuid,
    negociacion_id uuid,
    acuerdo_id uuid,
    necesidad_id uuid,
    modelo text,
    prompt_version text,
    input_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    output_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    tokens_input integer,
    tokens_output integer,
    costo_usd numeric(10,6),
    latencia_ms integer,
    exito boolean DEFAULT true NOT NULL,
    error_mensaje text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    mensaje_id uuid
);


--
-- Name: bloqueo_productor; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.bloqueo_productor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    productor_id uuid NOT NULL,
    empacadora_id uuid NOT NULL,
    motivo text NOT NULL,
    motivo_tipo text DEFAULT 'cancelacion_acuerdo'::text NOT NULL,
    acuerdo_id uuid,
    desde_at timestamp with time zone DEFAULT now() NOT NULL,
    hasta_at timestamp with time zone NOT NULL,
    levantado_at timestamp with time zone,
    levantado_por_usuario_id uuid,
    asignado_por_usuario_id uuid NOT NULL,
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT bloqueo_productor_motivo_tipo_check CHECK ((motivo_tipo = ANY (ARRAY['cancelacion_acuerdo'::text, 'incumplimiento_calidad'::text, 'incumplimiento_volumen'::text, 'conducta'::text, 'fitosanitaria'::text, 'manual'::text]))),
    CONSTRAINT chk_hasta_despues_desde CHECK ((hasta_at > desde_at))
);


--
-- Name: evento_auth; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.evento_auth (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    whatsapp_phone text NOT NULL,
    acopista_id uuid,
    acopio_id uuid,
    empacadora_id uuid,
    resultado text NOT NULL,
    detalle text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: necesidad_compra; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.necesidad_compra (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    calibre_id uuid,
    calidad text,
    fecha_necesidad date NOT NULL,
    volumen_necesario_kg numeric(14,3) NOT NULL,
    volumen_comprado_kg numeric(14,3) DEFAULT 0 NOT NULL,
    prioridad agent.necesidad_prioridad DEFAULT 'media'::agent.necesidad_prioridad NOT NULL,
    estado agent.necesidad_estado DEFAULT 'abierta'::agent.necesidad_estado NOT NULL,
    origen agent.necesidad_origen NOT NULL,
    orden_venta_id uuid,
    demanda_mercado_id uuid,
    notas_agente text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cubierta_at timestamp with time zone,
    CONSTRAINT chk_comprado_lte_necesario CHECK ((volumen_comprado_kg <= (volumen_necesario_kg * 1.10))),
    CONSTRAINT necesidad_compra_volumen_comprado_kg_check CHECK ((volumen_comprado_kg >= (0)::numeric)),
    CONSTRAINT necesidad_compra_volumen_necesario_kg_check CHECK ((volumen_necesario_kg > (0)::numeric))
);


--
-- Name: nivel_autonomia; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.nivel_autonomia (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    productor_id uuid,
    acopio_id uuid,
    variedad_id uuid,
    nivel smallint NOT NULL,
    razon text,
    transacciones_exitosas integer DEFAULT 0 NOT NULL,
    asignado_at timestamp with time zone DEFAULT now() NOT NULL,
    asignado_por_usuario_id uuid,
    CONSTRAINT chk_productor_o_acopio CHECK (((productor_id IS NOT NULL) OR (acopio_id IS NOT NULL))),
    CONSTRAINT nivel_autonomia_nivel_check CHECK (((nivel >= 1) AND (nivel <= 3)))
);


--
-- Name: parametro_compra; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.parametro_compra (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    vigente_desde date NOT NULL,
    vigente_hasta date,
    precio_max_mxn_kg numeric(10,4),
    volumen_max_kg_por_productor numeric(12,3),
    distancia_max_km numeric(8,2),
    politica_precio_usda text DEFAULT 'mode_o_promedio'::text NOT NULL,
    utilidad_minima_excepcion_pct numeric(5,4),
    precio_preferencial_pct numeric(5,4) DEFAULT 0.05,
    percentil_preferencial numeric(5,4) DEFAULT 0.99,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT parametro_compra_percentil_preferencial_check CHECK (((percentil_preferencial >= 0.50) AND (percentil_preferencial <= 1.00))),
    CONSTRAINT parametro_compra_politica_precio_usda_check CHECK ((politica_precio_usda = ANY (ARRAY['min'::text, 'max'::text, 'mode_o_promedio'::text, 'promedio'::text, 'mode_o_min'::text]))),
    CONSTRAINT parametro_compra_precio_max_mxn_kg_check CHECK ((precio_max_mxn_kg >= (0)::numeric)),
    CONSTRAINT parametro_compra_precio_preferencial_pct_check CHECK (((precio_preferencial_pct >= (0)::numeric) AND (precio_preferencial_pct <= 0.5)))
);


--
-- Name: precio_banda_snapshot; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.precio_banda_snapshot (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    fecha date NOT NULL,
    variedad_id uuid NOT NULL,
    calibre_id uuid NOT NULL,
    categoria text NOT NULL,
    margen_pct numeric(5,4) NOT NULL,
    precio_mxn_kg numeric(10,4) NOT NULL,
    precio_venta_usd_caja numeric(10,4),
    tipo_cambio_usado numeric(10,6),
    tipo_cambio_id uuid,
    precio_usda_id uuid,
    costo_acarreo_aplicado numeric(10,4),
    costo_corte_aplicado numeric(10,4),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: score_acopio_evento; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.score_acopio_evento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acopio_id uuid NOT NULL,
    acopista_id uuid,
    tipo agent.evento_score_tipo NOT NULL,
    visita_id uuid,
    corte_id uuid,
    resultado_seleccion_id uuid,
    precision_volumen numeric(5,4),
    precision_calibre numeric(5,4),
    precision_calidad numeric(5,4),
    score_compuesto numeric(5,4) NOT NULL,
    volumen_estimado_kg numeric(12,3),
    volumen_real_kg numeric(12,3),
    desviacion_volumen_pct numeric(7,4),
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT score_acopio_evento_precision_calibre_check CHECK (((precision_calibre >= (0)::numeric) AND (precision_calibre <= (1)::numeric))),
    CONSTRAINT score_acopio_evento_precision_calidad_check CHECK (((precision_calidad >= (0)::numeric) AND (precision_calidad <= (1)::numeric))),
    CONSTRAINT score_acopio_evento_precision_volumen_check CHECK (((precision_volumen >= (0)::numeric) AND (precision_volumen <= (1)::numeric))),
    CONSTRAINT score_acopio_evento_score_compuesto_check CHECK (((score_compuesto >= (0)::numeric) AND (score_compuesto <= (1)::numeric)))
);


--
-- Name: score_cuadrilla_evento; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.score_cuadrilla_evento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cuadrilla_id uuid NOT NULL,
    tipo agent.evento_score_tipo NOT NULL,
    corte_id uuid,
    score_velocidad numeric(5,4),
    score_calidad_corte numeric(5,4),
    score_inocuidad numeric(5,4),
    score_compuesto numeric(5,4) NOT NULL,
    kg_por_hora numeric(12,4),
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT score_cuadrilla_evento_score_calidad_corte_check CHECK (((score_calidad_corte >= (0)::numeric) AND (score_calidad_corte <= (1)::numeric))),
    CONSTRAINT score_cuadrilla_evento_score_compuesto_check CHECK (((score_compuesto >= (0)::numeric) AND (score_compuesto <= (1)::numeric))),
    CONSTRAINT score_cuadrilla_evento_score_inocuidad_check CHECK (((score_inocuidad >= (0)::numeric) AND (score_inocuidad <= (1)::numeric))),
    CONSTRAINT score_cuadrilla_evento_score_velocidad_check CHECK (((score_velocidad >= (0)::numeric) AND (score_velocidad <= (1)::numeric)))
);


--
-- Name: score_huerta_evento; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.score_huerta_evento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    huerta_id uuid NOT NULL,
    tipo agent.evento_score_tipo NOT NULL,
    corte_id uuid,
    resultado_seleccion_id uuid,
    score_calidad numeric(5,4),
    score_rendimiento numeric(5,4),
    score_compuesto numeric(5,4) NOT NULL,
    rendimiento_kg_por_ha numeric(12,4),
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT score_huerta_evento_score_calidad_check CHECK (((score_calidad >= (0)::numeric) AND (score_calidad <= (1)::numeric))),
    CONSTRAINT score_huerta_evento_score_compuesto_check CHECK (((score_compuesto >= (0)::numeric) AND (score_compuesto <= (1)::numeric))),
    CONSTRAINT score_huerta_evento_score_rendimiento_check CHECK (((score_rendimiento >= (0)::numeric) AND (score_rendimiento <= (1)::numeric)))
);


--
-- Name: score_productor_evento; Type: TABLE; Schema: agent; Owner: -
--

CREATE TABLE agent.score_productor_evento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    productor_id uuid NOT NULL,
    tipo agent.evento_score_tipo NOT NULL,
    acuerdo_id uuid,
    score_cumplimiento numeric(5,4),
    score_calidad_fruta numeric(5,4),
    score_compuesto numeric(5,4) NOT NULL,
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT score_productor_evento_score_calidad_fruta_check CHECK (((score_calidad_fruta >= (0)::numeric) AND (score_calidad_fruta <= (1)::numeric))),
    CONSTRAINT score_productor_evento_score_compuesto_check CHECK (((score_compuesto >= (0)::numeric) AND (score_compuesto <= (1)::numeric))),
    CONSTRAINT score_productor_evento_score_cumplimiento_check CHECK (((score_cumplimiento >= (0)::numeric) AND (score_cumplimiento <= (1)::numeric)))
);


--
-- Name: empacadora; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.empacadora (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    rfc text,
    ubicacion_lat numeric(9,6),
    ubicacion_lng numeric(9,6),
    municipio text,
    estado text,
    direccion text,
    capacidad_kg_dia integer,
    utilidad_minima_pct numeric(5,4),
    costo_acarreo_mxn_kg numeric(10,4),
    costo_corte_mxn_kg numeric(10,4),
    fuente_tipo_cambio text DEFAULT 'banxico'::text NOT NULL,
    bandas_margen_pcts numeric(5,4)[] DEFAULT ARRAY[0.02::numeric(5,4), 0.04::numeric(5,4), 0.06::numeric(5,4), 0.08::numeric(5,4), 0.10::numeric(5,4), 0.12::numeric(5,4), 0.14::numeric(5,4)] NOT NULL,
    punto_cruce_default text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT empacadora_capacidad_kg_dia_check CHECK ((capacidad_kg_dia > 0)),
    CONSTRAINT empacadora_costo_acarreo_mxn_kg_check CHECK ((costo_acarreo_mxn_kg >= (0)::numeric)),
    CONSTRAINT empacadora_costo_corte_mxn_kg_check CHECK ((costo_corte_mxn_kg >= (0)::numeric)),
    CONSTRAINT empacadora_fuente_tipo_cambio_check CHECK ((fuente_tipo_cambio = ANY (ARRAY['banxico'::text, 'santander'::text, 'bbva'::text, 'banorte'::text, 'hsbc'::text, 'otro'::text]))),
    CONSTRAINT empacadora_utilidad_minima_pct_check CHECK (((utilidad_minima_pct >= (0)::numeric) AND (utilidad_minima_pct <= (1)::numeric)))
);


--
-- Name: v_necesidades_abiertas; Type: VIEW; Schema: agent; Owner: -
--

CREATE VIEW agent.v_necesidades_abiertas AS
 SELECT n.id,
    e.nombre AS empacadora,
    v.nombre_es AS variedad,
    c.codigo AS calibre,
    n.calidad,
    n.fecha_necesidad,
    n.volumen_necesario_kg,
    n.volumen_comprado_kg,
    (n.volumen_necesario_kg - n.volumen_comprado_kg) AS volumen_faltante_kg,
    n.prioridad,
    n.origen,
    n.estado
   FROM (((agent.necesidad_compra n
     JOIN core.empacadora e ON ((e.id = n.empacadora_id)))
     JOIN ref.variedad v ON ((v.id = n.variedad_id)))
     LEFT JOIN ref.calibre c ON ((c.id = n.calibre_id)))
  WHERE (n.estado = ANY (ARRAY['abierta'::agent.necesidad_estado, 'parcial'::agent.necesidad_estado]))
  ORDER BY
        CASE n.prioridad
            WHEN 'critica'::agent.necesidad_prioridad THEN 1
            WHEN 'alta'::agent.necesidad_prioridad THEN 2
            WHEN 'media'::agent.necesidad_prioridad THEN 3
            WHEN 'baja'::agent.necesidad_prioridad THEN 4
            ELSE NULL::integer
        END, n.fecha_necesidad;


--
-- Name: acopio; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.acopio (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    razon_social text,
    rfc text,
    telefono text,
    whatsapp_phone text,
    tipo core.acopio_tipo NOT NULL,
    zona_operacion text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: v_score_acopio_actual; Type: VIEW; Schema: agent; Owner: -
--

CREATE VIEW agent.v_score_acopio_actual AS
 SELECT a.id AS acopio_id,
    a.nombre AS acopio_nombre,
    count(se.id) AS num_eventos_90d,
    (avg(se.score_compuesto))::numeric(5,4) AS score_actual,
    (avg(se.precision_volumen))::numeric(5,4) AS precision_volumen_avg,
    (avg(se.precision_calibre))::numeric(5,4) AS precision_calibre_avg,
    (avg(se.precision_calidad))::numeric(5,4) AS precision_calidad_avg,
    max(se.created_at) AS ultimo_evento_at
   FROM (core.acopio a
     LEFT JOIN agent.score_acopio_evento se ON (((se.acopio_id = a.id) AND (se.created_at >= (now() - '90 days'::interval)))))
  WHERE (a.deleted_at IS NULL)
  GROUP BY a.id, a.nombre;


--
-- Name: cuadrilla; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.cuadrilla (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empresa text NOT NULL,
    nombre_responsable text NOT NULL,
    telefono text,
    tarifa_mxn_kg numeric(10,4),
    capacidad_personas integer,
    certificacion_inocuidad boolean DEFAULT false NOT NULL,
    variedades_certificadas uuid[],
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT cuadrilla_capacidad_personas_check CHECK ((capacidad_personas > 0)),
    CONSTRAINT cuadrilla_tarifa_mxn_kg_check CHECK ((tarifa_mxn_kg >= (0)::numeric))
);


--
-- Name: v_score_cuadrilla_actual; Type: VIEW; Schema: agent; Owner: -
--

CREATE VIEW agent.v_score_cuadrilla_actual AS
 SELECT c.id AS cuadrilla_id,
    c.empresa,
    count(se.id) AS num_eventos_lifetime,
    (avg(se.score_compuesto))::numeric(5,4) AS score_actual,
    (avg(se.score_velocidad))::numeric(5,4) AS score_velocidad_avg,
    (avg(se.score_calidad_corte))::numeric(5,4) AS score_calidad_corte_avg,
    (avg(se.score_inocuidad))::numeric(5,4) AS score_inocuidad_avg,
    max(se.created_at) AS ultimo_evento_at
   FROM (core.cuadrilla c
     LEFT JOIN agent.score_cuadrilla_evento se ON ((se.cuadrilla_id = c.id)))
  WHERE (c.deleted_at IS NULL)
  GROUP BY c.id, c.empresa;


--
-- Name: huerta; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.huerta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    codigo_hue text NOT NULL,
    productor_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    nombre text,
    ubicacion_lat numeric(9,6),
    ubicacion_lng numeric(9,6),
    poligono_geojson jsonb,
    superficie_hectareas numeric(10,4),
    altitud_msnm integer,
    edad_arboles_anios integer,
    variedades_secundarias jsonb,
    fecha_ultimo_corte date,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT huerta_altitud_msnm_check CHECK ((altitud_msnm >= 0)),
    CONSTRAINT huerta_edad_arboles_anios_check CHECK ((edad_arboles_anios >= 0)),
    CONSTRAINT huerta_superficie_hectareas_check CHECK ((superficie_hectareas >= (0)::numeric))
);


--
-- Name: v_score_huerta_actual; Type: VIEW; Schema: agent; Owner: -
--

CREATE VIEW agent.v_score_huerta_actual AS
 SELECT h.id AS huerta_id,
    h.codigo_hue,
    count(se.id) AS num_eventos_lifetime,
    (avg(se.score_compuesto))::numeric(5,4) AS score_actual,
    (avg(se.score_calidad))::numeric(5,4) AS score_calidad_avg,
    (avg(se.score_rendimiento))::numeric(5,4) AS score_rendimiento_avg,
    max(se.created_at) AS ultimo_evento_at
   FROM (core.huerta h
     LEFT JOIN agent.score_huerta_evento se ON ((se.huerta_id = h.id)))
  WHERE (h.deleted_at IS NULL)
  GROUP BY h.id, h.codigo_hue;


--
-- Name: productor; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.productor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    rfc text,
    telefono text,
    whatsapp_phone text,
    ubicacion_lat numeric(9,6),
    ubicacion_lng numeric(9,6),
    municipio text,
    estado text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: v_score_productor_actual; Type: VIEW; Schema: agent; Owner: -
--

CREATE VIEW agent.v_score_productor_actual AS
 SELECT p.id AS productor_id,
    p.nombre AS productor_nombre,
    count(se.id) AS num_eventos_lifetime,
    (avg(se.score_compuesto))::numeric(5,4) AS score_actual,
    (avg(se.score_cumplimiento))::numeric(5,4) AS score_cumplimiento_avg,
    (avg(se.score_calidad_fruta))::numeric(5,4) AS score_calidad_fruta_avg,
    max(se.created_at) AS ultimo_evento_at
   FROM (core.productor p
     LEFT JOIN agent.score_productor_evento se ON ((se.productor_id = p.id)))
  WHERE (p.deleted_at IS NULL)
  GROUP BY p.id, p.nombre;


--
-- Name: mensaje_whatsapp; Type: TABLE; Schema: comms; Owner: -
--

CREATE TABLE comms.mensaje_whatsapp (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sesion_id uuid,
    whatsapp_message_id text,
    chat_tipo comms.chat_tipo DEFAULT 'directo'::comms.chat_tipo NOT NULL,
    whatsapp_chat_id text NOT NULL,
    direccion comms.mensaje_direccion NOT NULL,
    remitente_tipo comms.remitente_tipo NOT NULL,
    remitente_id uuid,
    remitente_whatsapp_phone text,
    tipo comms.mensaje_tipo NOT NULL,
    contenido_raw text,
    media_url text,
    media_mime_type text,
    media_duration_seconds integer,
    contenido_normalizado text,
    idioma_detectado text,
    visita_id uuid,
    negociacion_id uuid,
    ubicacion_lat numeric(9,6),
    ubicacion_lng numeric(9,6),
    timestamp_origen timestamp with time zone NOT NULL,
    recibido_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: notificacion_outbound; Type: TABLE; Schema: comms; Owner: -
--

CREATE TABLE comms.notificacion_outbound (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    tipo comms.notificacion_tipo NOT NULL,
    canal comms.notificacion_canal NOT NULL,
    destinatario_tipo text NOT NULL,
    destinatario_id uuid NOT NULL,
    destinatario_nombre text,
    destinatario_canal_valor text,
    asunto text,
    mensaje text NOT NULL,
    entidad_tipo text,
    entidad_id uuid,
    estado comms.notificacion_estado DEFAULT 'pendiente'::comms.notificacion_estado NOT NULL,
    enviada_at timestamp with time zone,
    entregada_at timestamp with time zone,
    leida_at timestamp with time zone,
    fallida_at timestamp with time zone,
    error_detalle text,
    mensaje_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sesion_conversacional; Type: TABLE; Schema: comms; Owner: -
--

CREATE TABLE comms.sesion_conversacional (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acopista_id uuid NOT NULL,
    empacadora_id uuid NOT NULL,
    flujo_tipo comms.flujo_tipo NOT NULL,
    entidad_tipo text,
    entidad_id uuid,
    estado_actual text NOT NULL,
    contexto jsonb DEFAULT '{}'::jsonb NOT NULL,
    whatsapp_chat_id text,
    activa boolean DEFAULT true NOT NULL,
    cerrada_at timestamp with time zone,
    razon_cierre text,
    iniciada_at timestamp with time zone DEFAULT now() NOT NULL,
    ultima_actividad_at timestamp with time zone DEFAULT now() NOT NULL,
    expira_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT chk_entidad_consistente CHECK ((((entidad_tipo IS NULL) AND (entidad_id IS NULL)) OR ((entidad_tipo IS NOT NULL) AND (entidad_id IS NOT NULL))))
);


--
-- Name: transicion_estado; Type: TABLE; Schema: comms; Owner: -
--

CREATE TABLE comms.transicion_estado (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sesion_id uuid NOT NULL,
    estado_anterior text,
    estado_nuevo text NOT NULL,
    trigger_tipo text NOT NULL,
    mensaje_id uuid,
    contexto_delta jsonb,
    notas text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: acopista; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.acopista (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acopio_id uuid NOT NULL,
    nombre text NOT NULL,
    whatsapp_phone text NOT NULL,
    telefono_alt text,
    email text,
    rol text DEFAULT 'operador'::text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    inicio_at timestamp with time zone DEFAULT now() NOT NULL,
    fin_at timestamp with time zone,
    razon_baja text,
    permisos jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_fin_despues_inicio CHECK (((fin_at IS NULL) OR (fin_at >= inicio_at)))
);


--
-- Name: acopista_historial; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.acopista_historial (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acopista_id uuid NOT NULL,
    evento text NOT NULL,
    valor_anterior jsonb,
    valor_nuevo jsonb,
    motivo text,
    ejecutado_por_usuario_id uuid,
    ejecutado_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: codigo_acceso_temporal; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.codigo_acceso_temporal (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    codigo text NOT NULL,
    whatsapp_phone text NOT NULL,
    nombre_persona text,
    creado_por_usuario_id uuid NOT NULL,
    expira_at timestamp with time zone NOT NULL,
    usado_at timestamp with time zone,
    revocado_at timestamp with time zone,
    revocado_por_usuario_id uuid,
    acopio_id_creado uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_expira_futuro CHECK ((expira_at > created_at))
);


--
-- Name: empacadora_acopio; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.empacadora_acopio (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    acopio_id uuid NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    activo boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: empacadora_variedad; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.empacadora_variedad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    utilidad_minima_pct numeric(5,4),
    costo_acarreo_mxn_kg numeric(10,4),
    costo_corte_mxn_kg numeric(10,4),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT empacadora_variedad_costo_acarreo_mxn_kg_check CHECK ((costo_acarreo_mxn_kg >= (0)::numeric)),
    CONSTRAINT empacadora_variedad_costo_corte_mxn_kg_check CHECK ((costo_corte_mxn_kg >= (0)::numeric)),
    CONSTRAINT empacadora_variedad_utilidad_minima_pct_check CHECK (((utilidad_minima_pct >= (0)::numeric) AND (utilidad_minima_pct <= (1)::numeric)))
);


--
-- Name: huerta_alerta; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.huerta_alerta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    huerta_id uuid NOT NULL,
    tipo text NOT NULL,
    severidad text DEFAULT 'media'::text NOT NULL,
    descripcion text,
    fecha_inicio date DEFAULT CURRENT_DATE NOT NULL,
    fecha_resolucion date,
    activa boolean DEFAULT true NOT NULL,
    detectada_por text,
    detectada_por_usuario_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT huerta_alerta_severidad_check CHECK ((severidad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text, 'critica'::text]))),
    CONSTRAINT huerta_alerta_tipo_check CHECK ((tipo = ANY (ARRAY['gusano_barrenador'::text, 'plaga_otra'::text, 'altitud_baja'::text, 'fitosanitaria_sicoa'::text, 'score_bajo'::text, 'cancelacion_previa'::text, 'otro'::text])))
);


--
-- Name: sesion; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.sesion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    token_hash text NOT NULL,
    refresh_token_hash text,
    user_agent text,
    ip_address inet,
    creada_at timestamp with time zone DEFAULT now() NOT NULL,
    expira_at timestamp with time zone NOT NULL,
    revocada_at timestamp with time zone,
    ultima_actividad_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: usuario; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    nombre text NOT NULL,
    email text NOT NULL,
    whatsapp_phone text,
    rol core.usuario_rol NOT NULL,
    password_hash text,
    password_updated_at timestamp with time zone,
    ultimo_login_at timestamp with time zone,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp with time zone,
    email_verificado_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: v_acopistas_autorizados; Type: VIEW; Schema: core; Owner: -
--

CREATE VIEW core.v_acopistas_autorizados AS
 SELECT ac.id AS acopista_id,
    ac.whatsapp_phone,
    ac.nombre AS acopista_nombre,
    ac.rol AS acopista_rol,
    ac.permisos AS acopista_permisos,
    a.id AS acopio_id,
    a.nombre AS acopio_nombre,
    ea.empacadora_id,
    e.nombre AS empacadora_nombre,
    ea.fecha_inicio AS relacion_inicio,
    ea.fecha_fin AS relacion_fin
   FROM (((core.acopista ac
     JOIN core.acopio a ON ((a.id = ac.acopio_id)))
     JOIN core.empacadora_acopio ea ON ((ea.acopio_id = a.id)))
     JOIN core.empacadora e ON ((e.id = ea.empacadora_id)))
  WHERE ((ac.activo = true) AND ((ac.fin_at IS NULL) OR (ac.fin_at > now())) AND (ea.activo = true) AND ((ea.fecha_fin IS NULL) OR (ea.fecha_fin >= CURRENT_DATE)) AND (a.deleted_at IS NULL) AND (e.deleted_at IS NULL));


--
-- Name: acuerdo_compraventa; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.acuerdo_compraventa (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    negociacion_id uuid NOT NULL,
    plantilla_id uuid NOT NULL,
    status ops.acuerdo_status DEFAULT 'borrador'::ops.acuerdo_status NOT NULL,
    pdf_url text,
    pdf_hash_sha256 text,
    variables_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    fecha_corte_programada date,
    enviado_at timestamp with time zone,
    confirmado_at timestamp with time zone,
    confirmado_por text,
    vencimiento_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: capacidad_proceso; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.capacidad_proceso (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    fecha date NOT NULL,
    capacidad_total_kg numeric(12,3) NOT NULL,
    capacidad_comprometida_kg numeric(12,3) DEFAULT 0 NOT NULL,
    cortes_programados integer DEFAULT 0 NOT NULL,
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT capacidad_proceso_capacidad_comprometida_kg_check CHECK ((capacidad_comprometida_kg >= (0)::numeric)),
    CONSTRAINT capacidad_proceso_capacidad_total_kg_check CHECK ((capacidad_total_kg >= (0)::numeric)),
    CONSTRAINT chk_comprometida_lte_total CHECK ((capacidad_comprometida_kg <= capacidad_total_kg))
);


--
-- Name: corte; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.corte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acuerdo_id uuid NOT NULL,
    huerta_id uuid NOT NULL,
    cuadrilla_id uuid,
    acopio_id uuid,
    status ops.corte_status DEFAULT 'programado'::ops.corte_status NOT NULL,
    programado_para date NOT NULL,
    inicio_at timestamp with time zone,
    fin_at timestamp with time zone,
    volumen_cortado_kg numeric(12,3),
    costo_cuadrilla_mxn_kg numeric(10,4),
    incidencias text,
    notas_acopio text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT corte_costo_cuadrilla_mxn_kg_check CHECK ((costo_cuadrilla_mxn_kg >= (0)::numeric)),
    CONSTRAINT corte_volumen_cortado_kg_check CHECK ((volumen_cortado_kg >= (0)::numeric))
);


--
-- Name: demanda_mercado; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.demanda_mercado (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fecha date NOT NULL,
    variedad_id uuid,
    calibre_id uuid,
    region_us text,
    volumen_demandado_est_kg numeric(14,2),
    tendencia text,
    temporada text,
    competidores_activos jsonb,
    fuente text,
    notas_agente text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT demanda_mercado_tendencia_check CHECK ((tendencia = ANY (ARRAY['alta'::text, 'estable'::text, 'baja'::text])))
);


--
-- Name: negociacion; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.negociacion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visita_id uuid,
    empacadora_id uuid NOT NULL,
    productor_id uuid NOT NULL,
    huerta_id uuid NOT NULL,
    acopio_id uuid NOT NULL,
    acopista_id uuid,
    variedad_id uuid NOT NULL,
    necesidad_compra_id uuid,
    status ops.negociacion_status DEFAULT 'abierta'::ops.negociacion_status NOT NULL,
    precio_propuesto_mxn_kg numeric(10,4),
    precio_min_mxn_kg numeric(10,4),
    precio_max_mxn_kg numeric(10,4),
    precio_acordado_mxn_kg numeric(10,4),
    volumen_acordado_kg numeric(12,3),
    calibre_objetivo jsonb,
    calidad_objetivo jsonb,
    referencia_usda_id uuid,
    tipo_cambio_id uuid,
    requirio_hitl boolean DEFAULT false NOT NULL,
    aprobado_por_usuario_id uuid,
    aprobado_at timestamp with time zone,
    razon_hitl text,
    pausada_at timestamp with time zone,
    expira_at timestamp with time zone,
    cierre_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_hitl_aprobacion CHECK (((requirio_hitl = false) OR ((status <> 'acordada'::ops.negociacion_status) OR (aprobado_por_usuario_id IS NOT NULL)))),
    CONSTRAINT chk_precio_min_max CHECK (((precio_min_mxn_kg IS NULL) OR (precio_max_mxn_kg IS NULL) OR (precio_min_mxn_kg <= precio_max_mxn_kg))),
    CONSTRAINT negociacion_precio_acordado_mxn_kg_check CHECK ((precio_acordado_mxn_kg >= (0)::numeric)),
    CONSTRAINT negociacion_precio_max_mxn_kg_check CHECK ((precio_max_mxn_kg >= (0)::numeric)),
    CONSTRAINT negociacion_precio_min_mxn_kg_check CHECK ((precio_min_mxn_kg >= (0)::numeric)),
    CONSTRAINT negociacion_precio_propuesto_mxn_kg_check CHECK ((precio_propuesto_mxn_kg >= (0)::numeric)),
    CONSTRAINT negociacion_volumen_acordado_kg_check CHECK ((volumen_acordado_kg >= (0)::numeric))
);


--
-- Name: resultado_seleccion; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.resultado_seleccion (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    corte_id uuid NOT NULL,
    fecha_proceso timestamp with time zone DEFAULT now() NOT NULL,
    volumen_total_kg numeric(12,3) NOT NULL,
    desglose_calibre jsonb,
    desglose_calidad jsonb,
    pct_exportacion_real numeric(5,4),
    pct_nacional_real numeric(5,4),
    pct_rechazo_real numeric(5,4),
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resultado_seleccion_pct_exportacion_real_check CHECK (((pct_exportacion_real >= (0)::numeric) AND (pct_exportacion_real <= (1)::numeric))),
    CONSTRAINT resultado_seleccion_pct_nacional_real_check CHECK (((pct_nacional_real >= (0)::numeric) AND (pct_nacional_real <= (1)::numeric))),
    CONSTRAINT resultado_seleccion_pct_rechazo_real_check CHECK (((pct_rechazo_real >= (0)::numeric) AND (pct_rechazo_real <= (1)::numeric))),
    CONSTRAINT resultado_seleccion_volumen_total_kg_check CHECK ((volumen_total_kg >= (0)::numeric))
);


--
-- Name: riesgo_aceptado; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.riesgo_aceptado (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visita_id uuid,
    negociacion_id uuid,
    huerta_alerta_id uuid NOT NULL,
    aceptado_por_acopista_id uuid NOT NULL,
    notas text,
    aceptado_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_visita_o_negociacion CHECK (((visita_id IS NOT NULL) OR (negociacion_id IS NOT NULL)))
);


--
-- Name: v_negociaciones_pendientes_hitl; Type: VIEW; Schema: ops; Owner: -
--

CREATE VIEW ops.v_negociaciones_pendientes_hitl AS
 SELECT n.id,
    n.created_at,
    e.nombre AS empacadora,
    p.nombre AS productor,
    a.nombre AS acopio,
    h.codigo_hue,
    var.nombre_es AS variedad,
    n.precio_propuesto_mxn_kg,
    n.volumen_acordado_kg,
    n.razon_hitl
   FROM (((((ops.negociacion n
     JOIN core.empacadora e ON ((e.id = n.empacadora_id)))
     JOIN core.productor p ON ((p.id = n.productor_id)))
     JOIN core.acopio a ON ((a.id = n.acopio_id)))
     JOIN core.huerta h ON ((h.id = n.huerta_id)))
     JOIN ref.variedad var ON ((var.id = n.variedad_id)))
  WHERE ((n.requirio_hitl = true) AND (n.aprobado_por_usuario_id IS NULL) AND (n.status = ANY (ARRAY['abierta'::ops.negociacion_status, 'propuesta'::ops.negociacion_status])))
  ORDER BY n.created_at;


--
-- Name: visita; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.visita (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    huerta_id uuid NOT NULL,
    acopio_id uuid NOT NULL,
    acopista_id uuid,
    empacadora_id uuid NOT NULL,
    status ops.visita_status DEFAULT 'en_curso'::ops.visita_status NOT NULL,
    inicio_at timestamp with time zone DEFAULT now() NOT NULL,
    cierre_at timestamp with time zone,
    volumen_estimado_kg numeric(12,3),
    calibre_estimado jsonb,
    calidad_estimada jsonb,
    ubicacion_lat numeric(9,6),
    ubicacion_lng numeric(9,6),
    ruta_gps_geojson jsonb,
    fotos jsonb,
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_cierre_despues_inicio CHECK (((cierre_at IS NULL) OR (cierre_at >= inicio_at))),
    CONSTRAINT visita_volumen_estimado_kg_check CHECK ((volumen_estimado_kg >= (0)::numeric))
);


--
-- Name: v_visitas_activas; Type: VIEW; Schema: ops; Owner: -
--

CREATE VIEW ops.v_visitas_activas AS
 SELECT v.id,
    v.inicio_at,
    h.codigo_hue,
    pr.nombre_es AS producto,
    var.nombre_es AS variedad,
    p.nombre AS productor,
    a.nombre AS acopio,
    e.nombre AS empacadora,
    v.volumen_estimado_kg,
    v.calibre_estimado,
    v.calidad_estimada
   FROM ((((((ops.visita v
     JOIN core.huerta h ON ((h.id = v.huerta_id)))
     JOIN ref.variedad var ON ((var.id = h.variedad_id)))
     JOIN ref.producto pr ON ((pr.id = var.producto_id)))
     JOIN core.productor p ON ((p.id = h.productor_id)))
     JOIN core.acopio a ON ((a.id = v.acopio_id)))
     JOIN core.empacadora e ON ((e.id = v.empacadora_id)))
  WHERE (v.status = 'en_curso'::ops.visita_status);


--
-- Name: contacto_importador; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.contacto_importador (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    importador_id uuid NOT NULL,
    nombre text NOT NULL,
    cargo text,
    telefono text,
    email text,
    es_decisor boolean DEFAULT false NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: embarque; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.embarque (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    orden_venta_id uuid NOT NULL,
    empacadora_id uuid NOT NULL,
    fecha_salida date,
    fecha_llegada_est date,
    fecha_llegada_real date,
    transportista text,
    transporte_propio boolean DEFAULT false NOT NULL,
    punto_cruce text,
    num_contenedor text,
    temperatura_control_c numeric(4,1),
    total_cajas integer,
    status sales.embarque_status DEFAULT 'preparando'::sales.embarque_status NOT NULL,
    incidencias text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: historial_compra; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.historial_compra (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    importador_id uuid NOT NULL,
    orden_venta_id uuid,
    fecha date NOT NULL,
    variedad_id uuid NOT NULL,
    calibre_id uuid,
    calidad text,
    volumen_cajas integer NOT NULL,
    precio_usd_caja numeric(10,4) NOT NULL,
    satisfaccion smallint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT historial_compra_precio_usd_caja_check CHECK ((precio_usd_caja >= (0)::numeric)),
    CONSTRAINT historial_compra_satisfaccion_check CHECK (((satisfaccion >= 1) AND (satisfaccion <= 5))),
    CONSTRAINT historial_compra_volumen_cajas_check CHECK ((volumen_cajas > 0))
);


--
-- Name: importador; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.importador (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre_empresa text NOT NULL,
    pais text DEFAULT 'US'::text NOT NULL,
    estado_us text,
    ciudad text,
    tipo sales.importador_tipo,
    canal_venta text,
    volumen_mensual_cajas integer,
    calibres_preferidos jsonb,
    condiciones_pago_usual text,
    activo boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: inventario_disponible; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.inventario_disponible (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    calibre_id uuid NOT NULL,
    presentacion_id uuid NOT NULL,
    calidad text,
    cajas_disponibles integer NOT NULL,
    huerta_origen_id uuid,
    corte_id uuid,
    status sales.inventario_status DEFAULT 'disponible'::sales.inventario_status NOT NULL,
    fecha_empaque date,
    vida_anaquel_dias integer,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT inventario_disponible_cajas_disponibles_check CHECK ((cajas_disponibles >= 0))
);


--
-- Name: lead; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.lead (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    importador_id uuid,
    nombre_empresa text,
    contacto_nombre text,
    email text,
    telefono text,
    variedad_id uuid,
    calibre_interes text,
    volumen_estimado_cajas integer,
    fecha_necesidad date,
    fuente sales.lead_fuente NOT NULL,
    status sales.lead_status DEFAULT 'nuevo'::sales.lead_status NOT NULL,
    score smallint,
    notas_agente text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lead_score_check CHECK (((score >= 0) AND (score <= 100)))
);


--
-- Name: linea_orden_venta; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.linea_orden_venta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    orden_id uuid NOT NULL,
    variedad_id uuid NOT NULL,
    calibre_id uuid NOT NULL,
    presentacion_id uuid NOT NULL,
    calidad text,
    cantidad_cajas integer NOT NULL,
    precio_caja_usd numeric(10,4) NOT NULL,
    corte_origen_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT linea_orden_venta_cantidad_cajas_check CHECK ((cantidad_cajas > 0)),
    CONSTRAINT linea_orden_venta_precio_caja_usd_check CHECK ((precio_caja_usd >= (0)::numeric))
);


--
-- Name: orden_venta; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.orden_venta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    empacadora_id uuid NOT NULL,
    importador_id uuid NOT NULL,
    contacto_id uuid,
    fecha_orden timestamp with time zone DEFAULT now() NOT NULL,
    fecha_entrega_estimada date,
    fecha_entrega_real date,
    status sales.orden_venta_status DEFAULT 'cotizada'::sales.orden_venta_status NOT NULL,
    total_usd numeric(14,2),
    condiciones_pago text,
    incoterm text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pago; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.pago (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    orden_venta_id uuid NOT NULL,
    importador_id uuid NOT NULL,
    fecha_pago date NOT NULL,
    monto_usd numeric(14,2) NOT NULL,
    metodo text DEFAULT 'wire_transfer'::text NOT NULL,
    referencia_bancaria text,
    es_pago_parcial boolean DEFAULT false NOT NULL,
    notas text,
    registrado_por_usuario_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pago_metodo_check CHECK ((metodo = ANY (ARRAY['wire_transfer'::text, 'ach'::text, 'check'::text, 'cash'::text, 'otro'::text]))),
    CONSTRAINT pago_monto_usd_check CHECK ((monto_usd > (0)::numeric))
);


--
-- Name: reclamo_calidad; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.reclamo_calidad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    orden_venta_id uuid NOT NULL,
    linea_orden_id uuid,
    importador_id uuid NOT NULL,
    fecha_reclamo date DEFAULT CURRENT_DATE NOT NULL,
    descripcion text NOT NULL,
    severidad text DEFAULT 'media'::text NOT NULL,
    cadena_auditada jsonb,
    estado text DEFAULT 'abierto'::text NOT NULL,
    resuelto_at timestamp with time zone,
    resolucion_notas text,
    monto_compensacion_usd numeric(12,2),
    asignado_a_usuario_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reclamo_calidad_estado_check CHECK ((estado = ANY (ARRAY['abierto'::text, 'investigando'::text, 'resuelto'::text, 'desestimado'::text, 'compensado'::text]))),
    CONSTRAINT reclamo_calidad_severidad_check CHECK ((severidad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text, 'critica'::text])))
);


--
-- Name: score_importador_evento; Type: TABLE; Schema: sales; Owner: -
--

CREATE TABLE sales.score_importador_evento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    importador_id uuid NOT NULL,
    empacadora_id uuid NOT NULL,
    fecha_calculo date DEFAULT CURRENT_DATE NOT NULL,
    score_pago numeric(5,4),
    score_volumen numeric(5,4),
    score_distancia numeric(5,4),
    score_fidelidad numeric(5,4),
    score_compuesto numeric(5,4) NOT NULL,
    pesos_aplicados jsonb NOT NULL,
    dias_mora_promedio numeric(6,2),
    volumen_anual_cajas integer,
    distancia_cruce_km numeric(8,2),
    notas text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT score_importador_evento_score_compuesto_check CHECK (((score_compuesto >= (0)::numeric) AND (score_compuesto <= (1)::numeric))),
    CONSTRAINT score_importador_evento_score_distancia_check CHECK (((score_distancia >= (0)::numeric) AND (score_distancia <= (1)::numeric))),
    CONSTRAINT score_importador_evento_score_fidelidad_check CHECK (((score_fidelidad >= (0)::numeric) AND (score_fidelidad <= (1)::numeric))),
    CONSTRAINT score_importador_evento_score_pago_check CHECK (((score_pago >= (0)::numeric) AND (score_pago <= (1)::numeric))),
    CONSTRAINT score_importador_evento_score_volumen_check CHECK (((score_volumen >= (0)::numeric) AND (score_volumen <= (1)::numeric)))
);


--
-- Name: accion accion_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_pkey PRIMARY KEY (id);


--
-- Name: bloqueo_productor bloqueo_productor_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_pkey PRIMARY KEY (id);


--
-- Name: evento_auth evento_auth_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.evento_auth
    ADD CONSTRAINT evento_auth_pkey PRIMARY KEY (id);


--
-- Name: necesidad_compra necesidad_compra_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_pkey PRIMARY KEY (id);


--
-- Name: nivel_autonomia nivel_autonomia_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_pkey PRIMARY KEY (id);


--
-- Name: parametro_compra parametro_compra_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.parametro_compra
    ADD CONSTRAINT parametro_compra_pkey PRIMARY KEY (id);


--
-- Name: precio_banda_snapshot precio_banda_snapshot_empacadora_id_fecha_variedad_id_calib_key; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_empacadora_id_fecha_variedad_id_calib_key UNIQUE (empacadora_id, fecha, variedad_id, calibre_id, categoria, margen_pct);


--
-- Name: precio_banda_snapshot precio_banda_snapshot_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_pkey PRIMARY KEY (id);


--
-- Name: score_acopio_evento score_acopio_evento_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_pkey PRIMARY KEY (id);


--
-- Name: score_cuadrilla_evento score_cuadrilla_evento_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_cuadrilla_evento
    ADD CONSTRAINT score_cuadrilla_evento_pkey PRIMARY KEY (id);


--
-- Name: score_huerta_evento score_huerta_evento_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_huerta_evento
    ADD CONSTRAINT score_huerta_evento_pkey PRIMARY KEY (id);


--
-- Name: score_productor_evento score_productor_evento_pkey; Type: CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_productor_evento
    ADD CONSTRAINT score_productor_evento_pkey PRIMARY KEY (id);


--
-- Name: mensaje_whatsapp mensaje_whatsapp_pkey; Type: CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.mensaje_whatsapp
    ADD CONSTRAINT mensaje_whatsapp_pkey PRIMARY KEY (id);


--
-- Name: mensaje_whatsapp mensaje_whatsapp_whatsapp_message_id_key; Type: CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.mensaje_whatsapp
    ADD CONSTRAINT mensaje_whatsapp_whatsapp_message_id_key UNIQUE (whatsapp_message_id);


--
-- Name: notificacion_outbound notificacion_outbound_pkey; Type: CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.notificacion_outbound
    ADD CONSTRAINT notificacion_outbound_pkey PRIMARY KEY (id);


--
-- Name: sesion_conversacional sesion_conversacional_pkey; Type: CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.sesion_conversacional
    ADD CONSTRAINT sesion_conversacional_pkey PRIMARY KEY (id);


--
-- Name: transicion_estado transicion_estado_pkey; Type: CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.transicion_estado
    ADD CONSTRAINT transicion_estado_pkey PRIMARY KEY (id);


--
-- Name: acopio acopio_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopio
    ADD CONSTRAINT acopio_pkey PRIMARY KEY (id);


--
-- Name: acopio acopio_whatsapp_phone_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopio
    ADD CONSTRAINT acopio_whatsapp_phone_key UNIQUE (whatsapp_phone);


--
-- Name: acopista_historial acopista_historial_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista_historial
    ADD CONSTRAINT acopista_historial_pkey PRIMARY KEY (id);


--
-- Name: acopista acopista_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista
    ADD CONSTRAINT acopista_pkey PRIMARY KEY (id);


--
-- Name: acopista acopista_whatsapp_phone_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista
    ADD CONSTRAINT acopista_whatsapp_phone_key UNIQUE (whatsapp_phone);


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_codigo_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_codigo_key UNIQUE (codigo);


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_pkey PRIMARY KEY (id);


--
-- Name: cuadrilla cuadrilla_empresa_nombre_responsable_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.cuadrilla
    ADD CONSTRAINT cuadrilla_empresa_nombre_responsable_key UNIQUE (empresa, nombre_responsable);


--
-- Name: cuadrilla cuadrilla_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.cuadrilla
    ADD CONSTRAINT cuadrilla_pkey PRIMARY KEY (id);


--
-- Name: empacadora_acopio empacadora_acopio_empacadora_id_acopio_id_fecha_inicio_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_acopio
    ADD CONSTRAINT empacadora_acopio_empacadora_id_acopio_id_fecha_inicio_key UNIQUE (empacadora_id, acopio_id, fecha_inicio);


--
-- Name: empacadora_acopio empacadora_acopio_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_acopio
    ADD CONSTRAINT empacadora_acopio_pkey PRIMARY KEY (id);


--
-- Name: empacadora empacadora_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora
    ADD CONSTRAINT empacadora_pkey PRIMARY KEY (id);


--
-- Name: empacadora empacadora_rfc_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora
    ADD CONSTRAINT empacadora_rfc_key UNIQUE (rfc);


--
-- Name: empacadora_variedad empacadora_variedad_empacadora_id_variedad_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_variedad
    ADD CONSTRAINT empacadora_variedad_empacadora_id_variedad_id_key UNIQUE (empacadora_id, variedad_id);


--
-- Name: empacadora_variedad empacadora_variedad_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_variedad
    ADD CONSTRAINT empacadora_variedad_pkey PRIMARY KEY (id);


--
-- Name: huerta_alerta huerta_alerta_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta_alerta
    ADD CONSTRAINT huerta_alerta_pkey PRIMARY KEY (id);


--
-- Name: huerta huerta_codigo_hue_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta
    ADD CONSTRAINT huerta_codigo_hue_key UNIQUE (codigo_hue);


--
-- Name: huerta huerta_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta
    ADD CONSTRAINT huerta_pkey PRIMARY KEY (id);


--
-- Name: productor productor_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.productor
    ADD CONSTRAINT productor_pkey PRIMARY KEY (id);


--
-- Name: productor productor_rfc_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.productor
    ADD CONSTRAINT productor_rfc_key UNIQUE (rfc);


--
-- Name: productor productor_whatsapp_phone_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.productor
    ADD CONSTRAINT productor_whatsapp_phone_key UNIQUE (whatsapp_phone);


--
-- Name: sesion sesion_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.sesion
    ADD CONSTRAINT sesion_pkey PRIMARY KEY (id);


--
-- Name: sesion sesion_refresh_token_hash_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.sesion
    ADD CONSTRAINT sesion_refresh_token_hash_key UNIQUE (refresh_token_hash);


--
-- Name: sesion sesion_token_hash_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.sesion
    ADD CONSTRAINT sesion_token_hash_key UNIQUE (token_hash);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_whatsapp_phone_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_whatsapp_phone_key UNIQUE (whatsapp_phone);


--
-- Name: acuerdo_compraventa acuerdo_compraventa_negociacion_id_key; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.acuerdo_compraventa
    ADD CONSTRAINT acuerdo_compraventa_negociacion_id_key UNIQUE (negociacion_id);


--
-- Name: acuerdo_compraventa acuerdo_compraventa_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.acuerdo_compraventa
    ADD CONSTRAINT acuerdo_compraventa_pkey PRIMARY KEY (id);


--
-- Name: capacidad_proceso capacidad_proceso_empacadora_id_fecha_key; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.capacidad_proceso
    ADD CONSTRAINT capacidad_proceso_empacadora_id_fecha_key UNIQUE (empacadora_id, fecha);


--
-- Name: capacidad_proceso capacidad_proceso_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.capacidad_proceso
    ADD CONSTRAINT capacidad_proceso_pkey PRIMARY KEY (id);


--
-- Name: corte corte_acuerdo_id_key; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_acuerdo_id_key UNIQUE (acuerdo_id);


--
-- Name: corte corte_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_pkey PRIMARY KEY (id);


--
-- Name: demanda_mercado demanda_mercado_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.demanda_mercado
    ADD CONSTRAINT demanda_mercado_pkey PRIMARY KEY (id);


--
-- Name: negociacion negociacion_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_pkey PRIMARY KEY (id);


--
-- Name: resultado_seleccion resultado_seleccion_corte_id_key; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.resultado_seleccion
    ADD CONSTRAINT resultado_seleccion_corte_id_key UNIQUE (corte_id);


--
-- Name: resultado_seleccion resultado_seleccion_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.resultado_seleccion
    ADD CONSTRAINT resultado_seleccion_pkey PRIMARY KEY (id);


--
-- Name: riesgo_aceptado riesgo_aceptado_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.riesgo_aceptado
    ADD CONSTRAINT riesgo_aceptado_pkey PRIMARY KEY (id);


--
-- Name: visita visita_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.visita
    ADD CONSTRAINT visita_pkey PRIMARY KEY (id);


--
-- Name: contacto_importador contacto_importador_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contacto_importador
    ADD CONSTRAINT contacto_importador_pkey PRIMARY KEY (id);


--
-- Name: embarque embarque_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.embarque
    ADD CONSTRAINT embarque_pkey PRIMARY KEY (id);


--
-- Name: historial_compra historial_compra_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.historial_compra
    ADD CONSTRAINT historial_compra_pkey PRIMARY KEY (id);


--
-- Name: importador importador_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.importador
    ADD CONSTRAINT importador_pkey PRIMARY KEY (id);


--
-- Name: inventario_disponible inventario_disponible_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT inventario_disponible_pkey PRIMARY KEY (id);


--
-- Name: lead lead_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.lead
    ADD CONSTRAINT lead_pkey PRIMARY KEY (id);


--
-- Name: linea_orden_venta linea_orden_venta_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT linea_orden_venta_pkey PRIMARY KEY (id);


--
-- Name: orden_venta orden_venta_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orden_venta
    ADD CONSTRAINT orden_venta_pkey PRIMARY KEY (id);


--
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id);


--
-- Name: reclamo_calidad reclamo_calidad_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.reclamo_calidad
    ADD CONSTRAINT reclamo_calidad_pkey PRIMARY KEY (id);


--
-- Name: score_importador_evento score_importador_evento_pkey; Type: CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.score_importador_evento
    ADD CONSTRAINT score_importador_evento_pkey PRIMARY KEY (id);


--
-- Name: idx_accion_exito; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_accion_exito ON agent.accion USING btree (exito, created_at DESC) WHERE (exito = false);


--
-- Name: idx_accion_mensaje; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_accion_mensaje ON agent.accion USING btree (mensaje_id) WHERE (mensaje_id IS NOT NULL);


--
-- Name: idx_accion_negociacion; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_accion_negociacion ON agent.accion USING btree (negociacion_id) WHERE (negociacion_id IS NOT NULL);


--
-- Name: idx_accion_tipo_fecha; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_accion_tipo_fecha ON agent.accion USING btree (tipo, created_at DESC);


--
-- Name: idx_accion_visita; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_accion_visita ON agent.accion USING btree (visita_id) WHERE (visita_id IS NOT NULL);


--
-- Name: idx_auth_resultado; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_auth_resultado ON agent.evento_auth USING btree (resultado, created_at DESC);


--
-- Name: idx_auth_whatsapp_fecha; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_auth_whatsapp_fecha ON agent.evento_auth USING btree (whatsapp_phone, created_at DESC);


--
-- Name: idx_autonomia_emp_acopio; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_autonomia_emp_acopio ON agent.nivel_autonomia USING btree (empacadora_id, acopio_id);


--
-- Name: idx_autonomia_emp_productor; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_autonomia_emp_productor ON agent.nivel_autonomia USING btree (empacadora_id, productor_id);


--
-- Name: idx_bloqueo_productor_activo; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_bloqueo_productor_activo ON agent.bloqueo_productor USING btree (productor_id, empacadora_id, hasta_at);


--
-- Name: idx_bloqueo_productor_empacadora; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_bloqueo_productor_empacadora ON agent.bloqueo_productor USING btree (empacadora_id, hasta_at DESC);


--
-- Name: idx_necesidad_emp_estado; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_necesidad_emp_estado ON agent.necesidad_compra USING btree (empacadora_id, estado);


--
-- Name: idx_necesidad_fecha; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_necesidad_fecha ON agent.necesidad_compra USING btree (fecha_necesidad) WHERE (estado = ANY (ARRAY['abierta'::agent.necesidad_estado, 'parcial'::agent.necesidad_estado]));


--
-- Name: idx_necesidad_prioridad; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_necesidad_prioridad ON agent.necesidad_compra USING btree (empacadora_id, prioridad, fecha_necesidad) WHERE (estado = ANY (ARRAY['abierta'::agent.necesidad_estado, 'parcial'::agent.necesidad_estado]));


--
-- Name: idx_necesidad_variedad; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_necesidad_variedad ON agent.necesidad_compra USING btree (variedad_id);


--
-- Name: idx_parametro_emp_variedad_vigente; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_parametro_emp_variedad_vigente ON agent.parametro_compra USING btree (empacadora_id, variedad_id, vigente_desde DESC);


--
-- Name: idx_precio_banda_emp_fecha; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_precio_banda_emp_fecha ON agent.precio_banda_snapshot USING btree (empacadora_id, fecha DESC);


--
-- Name: idx_precio_banda_lookup; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_precio_banda_lookup ON agent.precio_banda_snapshot USING btree (empacadora_id, variedad_id, calibre_id, fecha DESC);


--
-- Name: idx_score_acopio_acopio; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_score_acopio_acopio ON agent.score_acopio_evento USING btree (acopio_id, created_at DESC);


--
-- Name: idx_score_acopio_corte; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_score_acopio_corte ON agent.score_acopio_evento USING btree (corte_id) WHERE (corte_id IS NOT NULL);


--
-- Name: idx_score_cuadrilla_cuadrilla; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_score_cuadrilla_cuadrilla ON agent.score_cuadrilla_evento USING btree (cuadrilla_id, created_at DESC);


--
-- Name: idx_score_huerta_huerta; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_score_huerta_huerta ON agent.score_huerta_evento USING btree (huerta_id, created_at DESC);


--
-- Name: idx_score_productor_productor; Type: INDEX; Schema: agent; Owner: -
--

CREATE INDEX idx_score_productor_productor ON agent.score_productor_evento USING btree (productor_id, created_at DESC);


--
-- Name: idx_mensaje_chat; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_chat ON comms.mensaje_whatsapp USING btree (whatsapp_chat_id, timestamp_origen DESC);


--
-- Name: idx_mensaje_chat_tipo; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_chat_tipo ON comms.mensaje_whatsapp USING btree (chat_tipo);


--
-- Name: idx_mensaje_negociacion; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_negociacion ON comms.mensaje_whatsapp USING btree (negociacion_id) WHERE (negociacion_id IS NOT NULL);


--
-- Name: idx_mensaje_sesion; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_sesion ON comms.mensaje_whatsapp USING btree (sesion_id, timestamp_origen DESC) WHERE (sesion_id IS NOT NULL);


--
-- Name: idx_mensaje_timestamp; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_timestamp ON comms.mensaje_whatsapp USING btree (timestamp_origen DESC);


--
-- Name: idx_mensaje_visita; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_mensaje_visita ON comms.mensaje_whatsapp USING btree (visita_id) WHERE (visita_id IS NOT NULL);


--
-- Name: idx_notif_destinatario; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_notif_destinatario ON comms.notificacion_outbound USING btree (destinatario_tipo, destinatario_id);


--
-- Name: idx_notif_empacadora_estado; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_notif_empacadora_estado ON comms.notificacion_outbound USING btree (empacadora_id, estado);


--
-- Name: idx_notif_entidad; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_notif_entidad ON comms.notificacion_outbound USING btree (entidad_tipo, entidad_id) WHERE (entidad_id IS NOT NULL);


--
-- Name: idx_notif_tipo_fecha; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_notif_tipo_fecha ON comms.notificacion_outbound USING btree (tipo, created_at DESC);


--
-- Name: idx_sesion_acopista_activa; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_sesion_acopista_activa ON comms.sesion_conversacional USING btree (acopista_id, ultima_actividad_at DESC) WHERE (activa = true);


--
-- Name: idx_sesion_empacadora_flujo; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_sesion_empacadora_flujo ON comms.sesion_conversacional USING btree (empacadora_id, flujo_tipo);


--
-- Name: idx_sesion_entidad; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_sesion_entidad ON comms.sesion_conversacional USING btree (entidad_tipo, entidad_id) WHERE (entidad_id IS NOT NULL);


--
-- Name: idx_sesion_estado; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_sesion_estado ON comms.sesion_conversacional USING btree (estado_actual) WHERE (activa = true);


--
-- Name: idx_sesion_expira; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_sesion_expira ON comms.sesion_conversacional USING btree (expira_at) WHERE ((activa = true) AND (expira_at IS NOT NULL));


--
-- Name: idx_sesion_unica_activa; Type: INDEX; Schema: comms; Owner: -
--

CREATE UNIQUE INDEX idx_sesion_unica_activa ON comms.sesion_conversacional USING btree (acopista_id, flujo_tipo, entidad_id) WHERE ((activa = true) AND (entidad_id IS NOT NULL));


--
-- Name: idx_transicion_sesion; Type: INDEX; Schema: comms; Owner: -
--

CREATE INDEX idx_transicion_sesion ON comms.transicion_estado USING btree (sesion_id, created_at DESC);


--
-- Name: idx_acopio_whatsapp; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopio_whatsapp ON core.acopio USING btree (whatsapp_phone) WHERE (deleted_at IS NULL);


--
-- Name: idx_acopista_acopio; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopista_acopio ON core.acopista USING btree (acopio_id) WHERE activo;


--
-- Name: idx_acopista_fin_at; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopista_fin_at ON core.acopista USING btree (fin_at) WHERE (fin_at IS NOT NULL);


--
-- Name: idx_acopista_hist_acopista; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopista_hist_acopista ON core.acopista_historial USING btree (acopista_id, ejecutado_at DESC);


--
-- Name: idx_acopista_hist_evento; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopista_hist_evento ON core.acopista_historial USING btree (evento, ejecutado_at DESC);


--
-- Name: idx_acopista_whatsapp_activo; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_acopista_whatsapp_activo ON core.acopista USING btree (whatsapp_phone) WHERE activo;


--
-- Name: idx_codigo_temp_empacadora; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_codigo_temp_empacadora ON core.codigo_acceso_temporal USING btree (empacadora_id, created_at DESC);


--
-- Name: idx_codigo_temp_phone; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_codigo_temp_phone ON core.codigo_acceso_temporal USING btree (whatsapp_phone, expira_at DESC);


--
-- Name: idx_codigo_temp_vigente; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_codigo_temp_vigente ON core.codigo_acceso_temporal USING btree (codigo) WHERE ((usado_at IS NULL) AND (revocado_at IS NULL));


--
-- Name: idx_emp_acopio_acopio; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_emp_acopio_acopio ON core.empacadora_acopio USING btree (acopio_id) WHERE activo;


--
-- Name: idx_emp_acopio_empacadora; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_emp_acopio_empacadora ON core.empacadora_acopio USING btree (empacadora_id) WHERE activo;


--
-- Name: idx_emp_variedad_empacadora; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_emp_variedad_empacadora ON core.empacadora_variedad USING btree (empacadora_id) WHERE activo;


--
-- Name: idx_emp_variedad_variedad; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_emp_variedad_variedad ON core.empacadora_variedad USING btree (variedad_id) WHERE activo;


--
-- Name: idx_empacadora_deleted_at; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_empacadora_deleted_at ON core.empacadora USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: idx_huerta_alerta_huerta_activa; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_alerta_huerta_activa ON core.huerta_alerta USING btree (huerta_id) WHERE (activa = true);


--
-- Name: idx_huerta_alerta_tipo_activa; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_alerta_tipo_activa ON core.huerta_alerta USING btree (tipo, fecha_inicio DESC) WHERE (activa = true);


--
-- Name: idx_huerta_codigo_hue; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_codigo_hue ON core.huerta USING btree (codigo_hue) WHERE (deleted_at IS NULL);


--
-- Name: idx_huerta_fecha_ultimo_corte; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_fecha_ultimo_corte ON core.huerta USING btree (fecha_ultimo_corte);


--
-- Name: idx_huerta_nombre_trgm; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_nombre_trgm ON core.huerta USING gin (nombre public.gin_trgm_ops);


--
-- Name: idx_huerta_productor; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_productor ON core.huerta USING btree (productor_id);


--
-- Name: idx_huerta_variedad; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_huerta_variedad ON core.huerta USING btree (variedad_id);


--
-- Name: idx_productor_deleted_at; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_productor_deleted_at ON core.productor USING btree (deleted_at) WHERE (deleted_at IS NULL);


--
-- Name: idx_productor_whatsapp; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_productor_whatsapp ON core.productor USING btree (whatsapp_phone) WHERE (deleted_at IS NULL);


--
-- Name: idx_sesion_expira; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_sesion_expira ON core.sesion USING btree (expira_at) WHERE (revocada_at IS NULL);


--
-- Name: idx_sesion_usuario_activa; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_sesion_usuario_activa ON core.sesion USING btree (usuario_id) WHERE (revocada_at IS NULL);


--
-- Name: idx_usuario_empacadora; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX idx_usuario_empacadora ON core.usuario USING btree (empacadora_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_acuerdo_status; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_acuerdo_status ON ops.acuerdo_compraventa USING btree (status);


--
-- Name: idx_capacidad_emp_fecha; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_capacidad_emp_fecha ON ops.capacidad_proceso USING btree (empacadora_id, fecha DESC);


--
-- Name: idx_corte_cuadrilla; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_corte_cuadrilla ON ops.corte USING btree (cuadrilla_id);


--
-- Name: idx_corte_huerta; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_corte_huerta ON ops.corte USING btree (huerta_id);


--
-- Name: idx_corte_programado; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_corte_programado ON ops.corte USING btree (programado_para);


--
-- Name: idx_corte_status; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_corte_status ON ops.corte USING btree (status);


--
-- Name: idx_demanda_fecha; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_demanda_fecha ON ops.demanda_mercado USING btree (fecha DESC);


--
-- Name: idx_demanda_temporada; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_demanda_temporada ON ops.demanda_mercado USING btree (temporada) WHERE (temporada IS NOT NULL);


--
-- Name: idx_demanda_variedad; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_demanda_variedad ON ops.demanda_mercado USING btree (variedad_id);


--
-- Name: idx_negociacion_huerta; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_huerta ON ops.negociacion USING btree (huerta_id);


--
-- Name: idx_negociacion_necesidad; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_necesidad ON ops.negociacion USING btree (necesidad_compra_id) WHERE (necesidad_compra_id IS NOT NULL);


--
-- Name: idx_negociacion_productor; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_productor ON ops.negociacion USING btree (productor_id);


--
-- Name: idx_negociacion_status; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_status ON ops.negociacion USING btree (empacadora_id, status);


--
-- Name: idx_negociacion_variedad; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_variedad ON ops.negociacion USING btree (variedad_id);


--
-- Name: idx_negociacion_visita; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_negociacion_visita ON ops.negociacion USING btree (visita_id);


--
-- Name: idx_riesgo_aceptado_acopista; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_riesgo_aceptado_acopista ON ops.riesgo_aceptado USING btree (aceptado_por_acopista_id, aceptado_at DESC);


--
-- Name: idx_riesgo_aceptado_huerta_alerta; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_riesgo_aceptado_huerta_alerta ON ops.riesgo_aceptado USING btree (huerta_alerta_id);


--
-- Name: idx_seleccion_corte; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_seleccion_corte ON ops.resultado_seleccion USING btree (corte_id);


--
-- Name: idx_seleccion_fecha; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_seleccion_fecha ON ops.resultado_seleccion USING btree (fecha_proceso DESC);


--
-- Name: idx_visita_acopio; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_visita_acopio ON ops.visita USING btree (acopio_id);


--
-- Name: idx_visita_acopista; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_visita_acopista ON ops.visita USING btree (acopista_id);


--
-- Name: idx_visita_empacadora_status; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_visita_empacadora_status ON ops.visita USING btree (empacadora_id, status);


--
-- Name: idx_visita_huerta; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_visita_huerta ON ops.visita USING btree (huerta_id);


--
-- Name: idx_visita_inicio; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX idx_visita_inicio ON ops.visita USING btree (inicio_at DESC);


--
-- Name: idx_contacto_importador; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_contacto_importador ON sales.contacto_importador USING btree (importador_id) WHERE (deleted_at IS NULL);


--
-- Name: idx_embarque_orden; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_embarque_orden ON sales.embarque USING btree (orden_venta_id);


--
-- Name: idx_embarque_status; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_embarque_status ON sales.embarque USING btree (status);


--
-- Name: idx_historial_importador_fecha; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_historial_importador_fecha ON sales.historial_compra USING btree (importador_id, fecha DESC);


--
-- Name: idx_importador_activo; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_importador_activo ON sales.importador USING btree (activo) WHERE (deleted_at IS NULL);


--
-- Name: idx_inventario_empacadora_status; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_inventario_empacadora_status ON sales.inventario_disponible USING btree (empacadora_id, status);


--
-- Name: idx_inventario_variedad_calibre; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_inventario_variedad_calibre ON sales.inventario_disponible USING btree (variedad_id, calibre_id);


--
-- Name: idx_lead_empacadora_status; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_lead_empacadora_status ON sales.lead USING btree (empacadora_id, status);


--
-- Name: idx_lead_importador; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_lead_importador ON sales.lead USING btree (importador_id) WHERE (importador_id IS NOT NULL);


--
-- Name: idx_linea_orden_orden; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_linea_orden_orden ON sales.linea_orden_venta USING btree (orden_id);


--
-- Name: idx_orden_venta_empacadora; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_orden_venta_empacadora ON sales.orden_venta USING btree (empacadora_id, status);


--
-- Name: idx_orden_venta_fecha; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_orden_venta_fecha ON sales.orden_venta USING btree (fecha_orden DESC);


--
-- Name: idx_orden_venta_importador; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_orden_venta_importador ON sales.orden_venta USING btree (importador_id);


--
-- Name: idx_pago_importador; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_pago_importador ON sales.pago USING btree (importador_id, fecha_pago DESC);


--
-- Name: idx_pago_orden; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_pago_orden ON sales.pago USING btree (orden_venta_id, fecha_pago DESC);


--
-- Name: idx_reclamo_estado; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_reclamo_estado ON sales.reclamo_calidad USING btree (estado, fecha_reclamo DESC) WHERE (estado = ANY (ARRAY['abierto'::text, 'investigando'::text]));


--
-- Name: idx_reclamo_importador; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_reclamo_importador ON sales.reclamo_calidad USING btree (importador_id, fecha_reclamo DESC);


--
-- Name: idx_reclamo_orden; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_reclamo_orden ON sales.reclamo_calidad USING btree (orden_venta_id);


--
-- Name: idx_score_imp_emp; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_score_imp_emp ON sales.score_importador_evento USING btree (empacadora_id, fecha_calculo DESC);


--
-- Name: idx_score_imp_imp; Type: INDEX; Schema: sales; Owner: -
--

CREATE INDEX idx_score_imp_imp ON sales.score_importador_evento USING btree (importador_id, fecha_calculo DESC);


--
-- Name: necesidad_compra set_updated_at; Type: TRIGGER; Schema: agent; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON agent.necesidad_compra FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: parametro_compra set_updated_at; Type: TRIGGER; Schema: agent; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON agent.parametro_compra FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: notificacion_outbound set_updated_at; Type: TRIGGER; Schema: comms; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON comms.notificacion_outbound FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: acopio set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.acopio FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: acopista set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.acopista FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: cuadrilla set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.cuadrilla FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: empacadora set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.empacadora FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: empacadora_acopio set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.empacadora_acopio FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: empacadora_variedad set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.empacadora_variedad FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: huerta set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.huerta FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: huerta_alerta set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.huerta_alerta FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: productor set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.productor FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: usuario set_updated_at; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON core.usuario FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: acuerdo_compraventa set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.acuerdo_compraventa FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: capacidad_proceso set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.capacidad_proceso FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: corte set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.corte FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: negociacion set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.negociacion FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: resultado_seleccion set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.resultado_seleccion FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: visita set_updated_at; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ops.visita FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: contacto_importador set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.contacto_importador FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: embarque set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.embarque FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: importador set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.importador FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: inventario_disponible set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.inventario_disponible FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: lead set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.lead FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: linea_orden_venta set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.linea_orden_venta FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: orden_venta set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.orden_venta FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: pago set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.pago FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: reclamo_calidad set_updated_at; Type: TRIGGER; Schema: sales; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales.reclamo_calidad FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


--
-- Name: accion accion_acuerdo_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_acuerdo_id_fkey FOREIGN KEY (acuerdo_id) REFERENCES ops.acuerdo_compraventa(id) ON DELETE SET NULL;


--
-- Name: accion accion_mensaje_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_mensaje_id_fkey FOREIGN KEY (mensaje_id) REFERENCES comms.mensaje_whatsapp(id) ON DELETE SET NULL;


--
-- Name: accion accion_necesidad_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_necesidad_id_fkey FOREIGN KEY (necesidad_id) REFERENCES agent.necesidad_compra(id) ON DELETE SET NULL;


--
-- Name: accion accion_negociacion_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_negociacion_id_fkey FOREIGN KEY (negociacion_id) REFERENCES ops.negociacion(id) ON DELETE SET NULL;


--
-- Name: accion accion_visita_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.accion
    ADD CONSTRAINT accion_visita_id_fkey FOREIGN KEY (visita_id) REFERENCES ops.visita(id) ON DELETE SET NULL;


--
-- Name: bloqueo_productor bloqueo_productor_acuerdo_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_acuerdo_id_fkey FOREIGN KEY (acuerdo_id) REFERENCES ops.acuerdo_compraventa(id) ON DELETE SET NULL;


--
-- Name: bloqueo_productor bloqueo_productor_asignado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_asignado_por_usuario_id_fkey FOREIGN KEY (asignado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE RESTRICT;


--
-- Name: bloqueo_productor bloqueo_productor_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: bloqueo_productor bloqueo_productor_levantado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_levantado_por_usuario_id_fkey FOREIGN KEY (levantado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: bloqueo_productor bloqueo_productor_productor_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.bloqueo_productor
    ADD CONSTRAINT bloqueo_productor_productor_id_fkey FOREIGN KEY (productor_id) REFERENCES core.productor(id) ON DELETE CASCADE;


--
-- Name: evento_auth evento_auth_acopio_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.evento_auth
    ADD CONSTRAINT evento_auth_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE SET NULL;


--
-- Name: evento_auth evento_auth_acopista_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.evento_auth
    ADD CONSTRAINT evento_auth_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE SET NULL;


--
-- Name: evento_auth evento_auth_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.evento_auth
    ADD CONSTRAINT evento_auth_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE SET NULL;


--
-- Name: necesidad_compra necesidad_compra_calibre_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE SET NULL;


--
-- Name: necesidad_compra necesidad_compra_demanda_mercado_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_demanda_mercado_id_fkey FOREIGN KEY (demanda_mercado_id) REFERENCES ops.demanda_mercado(id) ON DELETE SET NULL;


--
-- Name: necesidad_compra necesidad_compra_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: necesidad_compra necesidad_compra_orden_venta_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_orden_venta_id_fkey FOREIGN KEY (orden_venta_id) REFERENCES sales.orden_venta(id) ON DELETE SET NULL;


--
-- Name: necesidad_compra necesidad_compra_variedad_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.necesidad_compra
    ADD CONSTRAINT necesidad_compra_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: nivel_autonomia nivel_autonomia_acopio_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE CASCADE;


--
-- Name: nivel_autonomia nivel_autonomia_asignado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_asignado_por_usuario_id_fkey FOREIGN KEY (asignado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: nivel_autonomia nivel_autonomia_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: nivel_autonomia nivel_autonomia_productor_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_productor_id_fkey FOREIGN KEY (productor_id) REFERENCES core.productor(id) ON DELETE CASCADE;


--
-- Name: nivel_autonomia nivel_autonomia_variedad_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.nivel_autonomia
    ADD CONSTRAINT nivel_autonomia_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE CASCADE;


--
-- Name: parametro_compra parametro_compra_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.parametro_compra
    ADD CONSTRAINT parametro_compra_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: parametro_compra parametro_compra_variedad_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.parametro_compra
    ADD CONSTRAINT parametro_compra_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: precio_banda_snapshot precio_banda_snapshot_calibre_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE RESTRICT;


--
-- Name: precio_banda_snapshot precio_banda_snapshot_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: precio_banda_snapshot precio_banda_snapshot_precio_usda_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_precio_usda_id_fkey FOREIGN KEY (precio_usda_id) REFERENCES ref.precio_usda(id) ON DELETE SET NULL;


--
-- Name: precio_banda_snapshot precio_banda_snapshot_tipo_cambio_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_tipo_cambio_id_fkey FOREIGN KEY (tipo_cambio_id) REFERENCES ref.tipo_cambio(id) ON DELETE SET NULL;


--
-- Name: precio_banda_snapshot precio_banda_snapshot_variedad_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.precio_banda_snapshot
    ADD CONSTRAINT precio_banda_snapshot_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: score_acopio_evento score_acopio_evento_acopio_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE CASCADE;


--
-- Name: score_acopio_evento score_acopio_evento_acopista_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE SET NULL;


--
-- Name: score_acopio_evento score_acopio_evento_corte_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_corte_id_fkey FOREIGN KEY (corte_id) REFERENCES ops.corte(id) ON DELETE SET NULL;


--
-- Name: score_acopio_evento score_acopio_evento_resultado_seleccion_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_resultado_seleccion_id_fkey FOREIGN KEY (resultado_seleccion_id) REFERENCES ops.resultado_seleccion(id) ON DELETE SET NULL;


--
-- Name: score_acopio_evento score_acopio_evento_visita_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_acopio_evento
    ADD CONSTRAINT score_acopio_evento_visita_id_fkey FOREIGN KEY (visita_id) REFERENCES ops.visita(id) ON DELETE SET NULL;


--
-- Name: score_cuadrilla_evento score_cuadrilla_evento_corte_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_cuadrilla_evento
    ADD CONSTRAINT score_cuadrilla_evento_corte_id_fkey FOREIGN KEY (corte_id) REFERENCES ops.corte(id) ON DELETE SET NULL;


--
-- Name: score_cuadrilla_evento score_cuadrilla_evento_cuadrilla_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_cuadrilla_evento
    ADD CONSTRAINT score_cuadrilla_evento_cuadrilla_id_fkey FOREIGN KEY (cuadrilla_id) REFERENCES core.cuadrilla(id) ON DELETE CASCADE;


--
-- Name: score_huerta_evento score_huerta_evento_corte_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_huerta_evento
    ADD CONSTRAINT score_huerta_evento_corte_id_fkey FOREIGN KEY (corte_id) REFERENCES ops.corte(id) ON DELETE SET NULL;


--
-- Name: score_huerta_evento score_huerta_evento_huerta_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_huerta_evento
    ADD CONSTRAINT score_huerta_evento_huerta_id_fkey FOREIGN KEY (huerta_id) REFERENCES core.huerta(id) ON DELETE CASCADE;


--
-- Name: score_huerta_evento score_huerta_evento_resultado_seleccion_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_huerta_evento
    ADD CONSTRAINT score_huerta_evento_resultado_seleccion_id_fkey FOREIGN KEY (resultado_seleccion_id) REFERENCES ops.resultado_seleccion(id) ON DELETE SET NULL;


--
-- Name: score_productor_evento score_productor_evento_acuerdo_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_productor_evento
    ADD CONSTRAINT score_productor_evento_acuerdo_id_fkey FOREIGN KEY (acuerdo_id) REFERENCES ops.acuerdo_compraventa(id) ON DELETE SET NULL;


--
-- Name: score_productor_evento score_productor_evento_productor_id_fkey; Type: FK CONSTRAINT; Schema: agent; Owner: -
--

ALTER TABLE ONLY agent.score_productor_evento
    ADD CONSTRAINT score_productor_evento_productor_id_fkey FOREIGN KEY (productor_id) REFERENCES core.productor(id) ON DELETE CASCADE;


--
-- Name: transicion_estado fk_transicion_mensaje; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.transicion_estado
    ADD CONSTRAINT fk_transicion_mensaje FOREIGN KEY (mensaje_id) REFERENCES comms.mensaje_whatsapp(id) ON DELETE SET NULL;


--
-- Name: mensaje_whatsapp mensaje_whatsapp_negociacion_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.mensaje_whatsapp
    ADD CONSTRAINT mensaje_whatsapp_negociacion_id_fkey FOREIGN KEY (negociacion_id) REFERENCES ops.negociacion(id) ON DELETE SET NULL;


--
-- Name: mensaje_whatsapp mensaje_whatsapp_sesion_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.mensaje_whatsapp
    ADD CONSTRAINT mensaje_whatsapp_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES comms.sesion_conversacional(id) ON DELETE SET NULL;


--
-- Name: mensaje_whatsapp mensaje_whatsapp_visita_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.mensaje_whatsapp
    ADD CONSTRAINT mensaje_whatsapp_visita_id_fkey FOREIGN KEY (visita_id) REFERENCES ops.visita(id) ON DELETE SET NULL;


--
-- Name: notificacion_outbound notificacion_outbound_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.notificacion_outbound
    ADD CONSTRAINT notificacion_outbound_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: notificacion_outbound notificacion_outbound_mensaje_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.notificacion_outbound
    ADD CONSTRAINT notificacion_outbound_mensaje_id_fkey FOREIGN KEY (mensaje_id) REFERENCES comms.mensaje_whatsapp(id) ON DELETE SET NULL;


--
-- Name: sesion_conversacional sesion_conversacional_acopista_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.sesion_conversacional
    ADD CONSTRAINT sesion_conversacional_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE CASCADE;


--
-- Name: sesion_conversacional sesion_conversacional_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.sesion_conversacional
    ADD CONSTRAINT sesion_conversacional_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: transicion_estado transicion_estado_sesion_id_fkey; Type: FK CONSTRAINT; Schema: comms; Owner: -
--

ALTER TABLE ONLY comms.transicion_estado
    ADD CONSTRAINT transicion_estado_sesion_id_fkey FOREIGN KEY (sesion_id) REFERENCES comms.sesion_conversacional(id) ON DELETE CASCADE;


--
-- Name: acopista acopista_acopio_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista
    ADD CONSTRAINT acopista_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE RESTRICT;


--
-- Name: acopista_historial acopista_historial_acopista_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista_historial
    ADD CONSTRAINT acopista_historial_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE CASCADE;


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_acopio_id_creado_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_acopio_id_creado_fkey FOREIGN KEY (acopio_id_creado) REFERENCES core.acopio(id) ON DELETE SET NULL;


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_creado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_creado_por_usuario_id_fkey FOREIGN KEY (creado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE RESTRICT;


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: codigo_acceso_temporal codigo_acceso_temporal_revocado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.codigo_acceso_temporal
    ADD CONSTRAINT codigo_acceso_temporal_revocado_por_usuario_id_fkey FOREIGN KEY (revocado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: empacadora_acopio empacadora_acopio_acopio_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_acopio
    ADD CONSTRAINT empacadora_acopio_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE CASCADE;


--
-- Name: empacadora_acopio empacadora_acopio_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_acopio
    ADD CONSTRAINT empacadora_acopio_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: empacadora_variedad empacadora_variedad_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_variedad
    ADD CONSTRAINT empacadora_variedad_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: empacadora_variedad empacadora_variedad_variedad_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.empacadora_variedad
    ADD CONSTRAINT empacadora_variedad_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: acopista_historial fk_acopista_hist_usuario; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.acopista_historial
    ADD CONSTRAINT fk_acopista_hist_usuario FOREIGN KEY (ejecutado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: huerta_alerta fk_huerta_alerta_usuario; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta_alerta
    ADD CONSTRAINT fk_huerta_alerta_usuario FOREIGN KEY (detectada_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: huerta_alerta huerta_alerta_huerta_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta_alerta
    ADD CONSTRAINT huerta_alerta_huerta_id_fkey FOREIGN KEY (huerta_id) REFERENCES core.huerta(id) ON DELETE CASCADE;


--
-- Name: huerta huerta_productor_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta
    ADD CONSTRAINT huerta_productor_id_fkey FOREIGN KEY (productor_id) REFERENCES core.productor(id) ON DELETE RESTRICT;


--
-- Name: huerta huerta_variedad_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.huerta
    ADD CONSTRAINT huerta_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: sesion sesion_usuario_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.sesion
    ADD CONSTRAINT sesion_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES core.usuario(id) ON DELETE CASCADE;


--
-- Name: usuario usuario_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: acuerdo_compraventa acuerdo_compraventa_negociacion_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.acuerdo_compraventa
    ADD CONSTRAINT acuerdo_compraventa_negociacion_id_fkey FOREIGN KEY (negociacion_id) REFERENCES ops.negociacion(id) ON DELETE RESTRICT;


--
-- Name: acuerdo_compraventa acuerdo_compraventa_plantilla_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.acuerdo_compraventa
    ADD CONSTRAINT acuerdo_compraventa_plantilla_id_fkey FOREIGN KEY (plantilla_id) REFERENCES ref.plantilla_acuerdo(id) ON DELETE RESTRICT;


--
-- Name: capacidad_proceso capacidad_proceso_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.capacidad_proceso
    ADD CONSTRAINT capacidad_proceso_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: corte corte_acopio_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE SET NULL;


--
-- Name: corte corte_acuerdo_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_acuerdo_id_fkey FOREIGN KEY (acuerdo_id) REFERENCES ops.acuerdo_compraventa(id) ON DELETE RESTRICT;


--
-- Name: corte corte_cuadrilla_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_cuadrilla_id_fkey FOREIGN KEY (cuadrilla_id) REFERENCES core.cuadrilla(id) ON DELETE SET NULL;


--
-- Name: corte corte_huerta_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.corte
    ADD CONSTRAINT corte_huerta_id_fkey FOREIGN KEY (huerta_id) REFERENCES core.huerta(id) ON DELETE RESTRICT;


--
-- Name: demanda_mercado demanda_mercado_calibre_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.demanda_mercado
    ADD CONSTRAINT demanda_mercado_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE SET NULL;


--
-- Name: demanda_mercado demanda_mercado_variedad_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.demanda_mercado
    ADD CONSTRAINT demanda_mercado_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE SET NULL;


--
-- Name: negociacion fk_negociacion_necesidad; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT fk_negociacion_necesidad FOREIGN KEY (necesidad_compra_id) REFERENCES agent.necesidad_compra(id) ON DELETE SET NULL;


--
-- Name: negociacion negociacion_acopio_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE RESTRICT;


--
-- Name: negociacion negociacion_acopista_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE SET NULL;


--
-- Name: negociacion negociacion_aprobado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_aprobado_por_usuario_id_fkey FOREIGN KEY (aprobado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: negociacion negociacion_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE RESTRICT;


--
-- Name: negociacion negociacion_huerta_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_huerta_id_fkey FOREIGN KEY (huerta_id) REFERENCES core.huerta(id) ON DELETE RESTRICT;


--
-- Name: negociacion negociacion_productor_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_productor_id_fkey FOREIGN KEY (productor_id) REFERENCES core.productor(id) ON DELETE RESTRICT;


--
-- Name: negociacion negociacion_referencia_usda_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_referencia_usda_id_fkey FOREIGN KEY (referencia_usda_id) REFERENCES ref.precio_usda(id) ON DELETE SET NULL;


--
-- Name: negociacion negociacion_tipo_cambio_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_tipo_cambio_id_fkey FOREIGN KEY (tipo_cambio_id) REFERENCES ref.tipo_cambio(id) ON DELETE SET NULL;


--
-- Name: negociacion negociacion_variedad_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: negociacion negociacion_visita_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.negociacion
    ADD CONSTRAINT negociacion_visita_id_fkey FOREIGN KEY (visita_id) REFERENCES ops.visita(id) ON DELETE SET NULL;


--
-- Name: resultado_seleccion resultado_seleccion_corte_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.resultado_seleccion
    ADD CONSTRAINT resultado_seleccion_corte_id_fkey FOREIGN KEY (corte_id) REFERENCES ops.corte(id) ON DELETE RESTRICT;


--
-- Name: riesgo_aceptado riesgo_aceptado_aceptado_por_acopista_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.riesgo_aceptado
    ADD CONSTRAINT riesgo_aceptado_aceptado_por_acopista_id_fkey FOREIGN KEY (aceptado_por_acopista_id) REFERENCES core.acopista(id) ON DELETE RESTRICT;


--
-- Name: riesgo_aceptado riesgo_aceptado_huerta_alerta_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.riesgo_aceptado
    ADD CONSTRAINT riesgo_aceptado_huerta_alerta_id_fkey FOREIGN KEY (huerta_alerta_id) REFERENCES core.huerta_alerta(id) ON DELETE RESTRICT;


--
-- Name: riesgo_aceptado riesgo_aceptado_negociacion_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.riesgo_aceptado
    ADD CONSTRAINT riesgo_aceptado_negociacion_id_fkey FOREIGN KEY (negociacion_id) REFERENCES ops.negociacion(id) ON DELETE SET NULL;


--
-- Name: riesgo_aceptado riesgo_aceptado_visita_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.riesgo_aceptado
    ADD CONSTRAINT riesgo_aceptado_visita_id_fkey FOREIGN KEY (visita_id) REFERENCES ops.visita(id) ON DELETE SET NULL;


--
-- Name: visita visita_acopio_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.visita
    ADD CONSTRAINT visita_acopio_id_fkey FOREIGN KEY (acopio_id) REFERENCES core.acopio(id) ON DELETE RESTRICT;


--
-- Name: visita visita_acopista_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.visita
    ADD CONSTRAINT visita_acopista_id_fkey FOREIGN KEY (acopista_id) REFERENCES core.acopista(id) ON DELETE SET NULL;


--
-- Name: visita visita_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.visita
    ADD CONSTRAINT visita_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE RESTRICT;


--
-- Name: visita visita_huerta_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.visita
    ADD CONSTRAINT visita_huerta_id_fkey FOREIGN KEY (huerta_id) REFERENCES core.huerta(id) ON DELETE RESTRICT;


--
-- Name: contacto_importador contacto_importador_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.contacto_importador
    ADD CONSTRAINT contacto_importador_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE CASCADE;


--
-- Name: embarque embarque_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.embarque
    ADD CONSTRAINT embarque_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE RESTRICT;


--
-- Name: embarque embarque_orden_venta_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.embarque
    ADD CONSTRAINT embarque_orden_venta_id_fkey FOREIGN KEY (orden_venta_id) REFERENCES sales.orden_venta(id) ON DELETE RESTRICT;


--
-- Name: inventario_disponible fk_inv_corte; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT fk_inv_corte FOREIGN KEY (corte_id) REFERENCES ops.corte(id) ON DELETE SET NULL;


--
-- Name: inventario_disponible fk_inv_huerta; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT fk_inv_huerta FOREIGN KEY (huerta_origen_id) REFERENCES core.huerta(id) ON DELETE SET NULL;


--
-- Name: linea_orden_venta fk_linea_corte; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT fk_linea_corte FOREIGN KEY (corte_origen_id) REFERENCES ops.corte(id) ON DELETE SET NULL;


--
-- Name: historial_compra historial_compra_calibre_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.historial_compra
    ADD CONSTRAINT historial_compra_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE SET NULL;


--
-- Name: historial_compra historial_compra_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.historial_compra
    ADD CONSTRAINT historial_compra_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE CASCADE;


--
-- Name: historial_compra historial_compra_orden_venta_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.historial_compra
    ADD CONSTRAINT historial_compra_orden_venta_id_fkey FOREIGN KEY (orden_venta_id) REFERENCES sales.orden_venta(id) ON DELETE SET NULL;


--
-- Name: historial_compra historial_compra_variedad_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.historial_compra
    ADD CONSTRAINT historial_compra_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: inventario_disponible inventario_disponible_calibre_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT inventario_disponible_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE RESTRICT;


--
-- Name: inventario_disponible inventario_disponible_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT inventario_disponible_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: inventario_disponible inventario_disponible_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT inventario_disponible_presentacion_id_fkey FOREIGN KEY (presentacion_id) REFERENCES ref.presentacion(id) ON DELETE RESTRICT;


--
-- Name: inventario_disponible inventario_disponible_variedad_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.inventario_disponible
    ADD CONSTRAINT inventario_disponible_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: lead lead_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.lead
    ADD CONSTRAINT lead_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: lead lead_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.lead
    ADD CONSTRAINT lead_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE SET NULL;


--
-- Name: lead lead_variedad_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.lead
    ADD CONSTRAINT lead_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE SET NULL;


--
-- Name: linea_orden_venta linea_orden_venta_calibre_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT linea_orden_venta_calibre_id_fkey FOREIGN KEY (calibre_id) REFERENCES ref.calibre(id) ON DELETE RESTRICT;


--
-- Name: linea_orden_venta linea_orden_venta_orden_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT linea_orden_venta_orden_id_fkey FOREIGN KEY (orden_id) REFERENCES sales.orden_venta(id) ON DELETE CASCADE;


--
-- Name: linea_orden_venta linea_orden_venta_presentacion_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT linea_orden_venta_presentacion_id_fkey FOREIGN KEY (presentacion_id) REFERENCES ref.presentacion(id) ON DELETE RESTRICT;


--
-- Name: linea_orden_venta linea_orden_venta_variedad_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.linea_orden_venta
    ADD CONSTRAINT linea_orden_venta_variedad_id_fkey FOREIGN KEY (variedad_id) REFERENCES ref.variedad(id) ON DELETE RESTRICT;


--
-- Name: orden_venta orden_venta_contacto_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orden_venta
    ADD CONSTRAINT orden_venta_contacto_id_fkey FOREIGN KEY (contacto_id) REFERENCES sales.contacto_importador(id) ON DELETE SET NULL;


--
-- Name: orden_venta orden_venta_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orden_venta
    ADD CONSTRAINT orden_venta_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE RESTRICT;


--
-- Name: orden_venta orden_venta_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.orden_venta
    ADD CONSTRAINT orden_venta_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE RESTRICT;


--
-- Name: pago pago_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.pago
    ADD CONSTRAINT pago_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE RESTRICT;


--
-- Name: pago pago_orden_venta_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.pago
    ADD CONSTRAINT pago_orden_venta_id_fkey FOREIGN KEY (orden_venta_id) REFERENCES sales.orden_venta(id) ON DELETE RESTRICT;


--
-- Name: pago pago_registrado_por_usuario_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.pago
    ADD CONSTRAINT pago_registrado_por_usuario_id_fkey FOREIGN KEY (registrado_por_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: reclamo_calidad reclamo_calidad_asignado_a_usuario_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.reclamo_calidad
    ADD CONSTRAINT reclamo_calidad_asignado_a_usuario_id_fkey FOREIGN KEY (asignado_a_usuario_id) REFERENCES core.usuario(id) ON DELETE SET NULL;


--
-- Name: reclamo_calidad reclamo_calidad_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.reclamo_calidad
    ADD CONSTRAINT reclamo_calidad_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE RESTRICT;


--
-- Name: reclamo_calidad reclamo_calidad_linea_orden_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.reclamo_calidad
    ADD CONSTRAINT reclamo_calidad_linea_orden_id_fkey FOREIGN KEY (linea_orden_id) REFERENCES sales.linea_orden_venta(id) ON DELETE SET NULL;


--
-- Name: reclamo_calidad reclamo_calidad_orden_venta_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.reclamo_calidad
    ADD CONSTRAINT reclamo_calidad_orden_venta_id_fkey FOREIGN KEY (orden_venta_id) REFERENCES sales.orden_venta(id) ON DELETE RESTRICT;


--
-- Name: score_importador_evento score_importador_evento_empacadora_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.score_importador_evento
    ADD CONSTRAINT score_importador_evento_empacadora_id_fkey FOREIGN KEY (empacadora_id) REFERENCES core.empacadora(id) ON DELETE CASCADE;


--
-- Name: score_importador_evento score_importador_evento_importador_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: -
--

ALTER TABLE ONLY sales.score_importador_evento
    ADD CONSTRAINT score_importador_evento_importador_id_fkey FOREIGN KEY (importador_id) REFERENCES sales.importador(id) ON DELETE CASCADE;


--
-- Name: accion; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.accion ENABLE ROW LEVEL SECURITY;

--
-- Name: bloqueo_productor; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.bloqueo_productor ENABLE ROW LEVEL SECURITY;

--
-- Name: evento_auth; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.evento_auth ENABLE ROW LEVEL SECURITY;

--
-- Name: necesidad_compra; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.necesidad_compra ENABLE ROW LEVEL SECURITY;

--
-- Name: nivel_autonomia; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.nivel_autonomia ENABLE ROW LEVEL SECURITY;

--
-- Name: parametro_compra; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.parametro_compra ENABLE ROW LEVEL SECURITY;

--
-- Name: precio_banda_snapshot; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.precio_banda_snapshot ENABLE ROW LEVEL SECURITY;

--
-- Name: score_acopio_evento; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.score_acopio_evento ENABLE ROW LEVEL SECURITY;

--
-- Name: score_cuadrilla_evento; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.score_cuadrilla_evento ENABLE ROW LEVEL SECURITY;

--
-- Name: score_huerta_evento; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.score_huerta_evento ENABLE ROW LEVEL SECURITY;

--
-- Name: score_productor_evento; Type: ROW SECURITY; Schema: agent; Owner: -
--

ALTER TABLE agent.score_productor_evento ENABLE ROW LEVEL SECURITY;

--
-- Name: accion tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.accion USING ((((visita_id IS NOT NULL) AND (visita_id IN ( SELECT visita.id
   FROM ops.visita
  WHERE (visita.empacadora_id = app.current_empacadora_id())))) OR ((negociacion_id IS NOT NULL) AND (negociacion_id IN ( SELECT negociacion.id
   FROM ops.negociacion
  WHERE (negociacion.empacadora_id = app.current_empacadora_id())))) OR ((necesidad_id IS NOT NULL) AND (necesidad_id IN ( SELECT necesidad_compra.id
   FROM agent.necesidad_compra
  WHERE (necesidad_compra.empacadora_id = app.current_empacadora_id())))) OR ((mensaje_id IS NOT NULL) AND (mensaje_id IN ( SELECT m.id
   FROM (comms.mensaje_whatsapp m
     JOIN comms.sesion_conversacional s ON ((s.id = m.sesion_id)))
  WHERE (s.empacadora_id = app.current_empacadora_id()))))));


--
-- Name: bloqueo_productor tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.bloqueo_productor USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: evento_auth tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.evento_auth USING (((empacadora_id = app.current_empacadora_id()) OR (empacadora_id IS NULL)));


--
-- Name: necesidad_compra tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.necesidad_compra USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: nivel_autonomia tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.nivel_autonomia USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: parametro_compra tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.parametro_compra USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: precio_banda_snapshot tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.precio_banda_snapshot USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: score_acopio_evento tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.score_acopio_evento USING ((acopio_id IN ( SELECT empacadora_acopio.acopio_id
   FROM core.empacadora_acopio
  WHERE (empacadora_acopio.empacadora_id = app.current_empacadora_id()))));


--
-- Name: score_cuadrilla_evento tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.score_cuadrilla_evento USING ((cuadrilla_id IN ( SELECT c.cuadrilla_id
   FROM ops.corte c
  WHERE (c.acuerdo_id IN ( SELECT a.id
           FROM (ops.acuerdo_compraventa a
             JOIN ops.negociacion n ON ((n.id = a.negociacion_id)))
          WHERE (n.empacadora_id = app.current_empacadora_id()))))));


--
-- Name: score_huerta_evento tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.score_huerta_evento USING ((huerta_id IN ( SELECT visita.huerta_id
   FROM ops.visita
  WHERE (visita.empacadora_id = app.current_empacadora_id())
UNION
 SELECT negociacion.huerta_id
   FROM ops.negociacion
  WHERE (negociacion.empacadora_id = app.current_empacadora_id()))));


--
-- Name: score_productor_evento tenant_isolation; Type: POLICY; Schema: agent; Owner: -
--

CREATE POLICY tenant_isolation ON agent.score_productor_evento USING ((productor_id IN ( SELECT h.productor_id
   FROM core.huerta h
  WHERE (h.id IN ( SELECT visita.huerta_id
           FROM ops.visita
          WHERE (visita.empacadora_id = app.current_empacadora_id())
        UNION
         SELECT negociacion.huerta_id
           FROM ops.negociacion
          WHERE (negociacion.empacadora_id = app.current_empacadora_id()))))));


--
-- Name: mensaje_whatsapp; Type: ROW SECURITY; Schema: comms; Owner: -
--

ALTER TABLE comms.mensaje_whatsapp ENABLE ROW LEVEL SECURITY;

--
-- Name: notificacion_outbound; Type: ROW SECURITY; Schema: comms; Owner: -
--

ALTER TABLE comms.notificacion_outbound ENABLE ROW LEVEL SECURITY;

--
-- Name: sesion_conversacional; Type: ROW SECURITY; Schema: comms; Owner: -
--

ALTER TABLE comms.sesion_conversacional ENABLE ROW LEVEL SECURITY;

--
-- Name: mensaje_whatsapp tenant_isolation; Type: POLICY; Schema: comms; Owner: -
--

CREATE POLICY tenant_isolation ON comms.mensaje_whatsapp USING ((((sesion_id IS NOT NULL) AND (sesion_id IN ( SELECT sesion_conversacional.id
   FROM comms.sesion_conversacional
  WHERE (sesion_conversacional.empacadora_id = app.current_empacadora_id())))) OR ((sesion_id IS NULL) AND (whatsapp_chat_id IN ( SELECT a.whatsapp_phone
   FROM (core.acopista a
     JOIN core.empacadora_acopio ea ON ((ea.acopio_id = a.acopio_id)))
  WHERE (ea.empacadora_id = app.current_empacadora_id()))))));


--
-- Name: notificacion_outbound tenant_isolation; Type: POLICY; Schema: comms; Owner: -
--

CREATE POLICY tenant_isolation ON comms.notificacion_outbound USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: sesion_conversacional tenant_isolation; Type: POLICY; Schema: comms; Owner: -
--

CREATE POLICY tenant_isolation ON comms.sesion_conversacional USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: transicion_estado tenant_isolation; Type: POLICY; Schema: comms; Owner: -
--

CREATE POLICY tenant_isolation ON comms.transicion_estado USING ((sesion_id IN ( SELECT sesion_conversacional.id
   FROM comms.sesion_conversacional
  WHERE (sesion_conversacional.empacadora_id = app.current_empacadora_id()))));


--
-- Name: transicion_estado; Type: ROW SECURITY; Schema: comms; Owner: -
--

ALTER TABLE comms.transicion_estado ENABLE ROW LEVEL SECURITY;

--
-- Name: acopio; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.acopio ENABLE ROW LEVEL SECURITY;

--
-- Name: acopista; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.acopista ENABLE ROW LEVEL SECURITY;

--
-- Name: acopista_historial; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.acopista_historial ENABLE ROW LEVEL SECURITY;

--
-- Name: codigo_acceso_temporal; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.codigo_acceso_temporal ENABLE ROW LEVEL SECURITY;

--
-- Name: cuadrilla; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.cuadrilla ENABLE ROW LEVEL SECURITY;

--
-- Name: empacadora; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.empacadora ENABLE ROW LEVEL SECURITY;

--
-- Name: empacadora_acopio; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.empacadora_acopio ENABLE ROW LEVEL SECURITY;

--
-- Name: empacadora_variedad; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.empacadora_variedad ENABLE ROW LEVEL SECURITY;

--
-- Name: huerta; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.huerta ENABLE ROW LEVEL SECURITY;

--
-- Name: huerta_alerta; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.huerta_alerta ENABLE ROW LEVEL SECURITY;

--
-- Name: productor; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.productor ENABLE ROW LEVEL SECURITY;

--
-- Name: sesion; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.sesion ENABLE ROW LEVEL SECURITY;

--
-- Name: codigo_acceso_temporal tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.codigo_acceso_temporal USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: empacadora tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.empacadora USING ((id = app.current_empacadora_id()));


--
-- Name: empacadora_acopio tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.empacadora_acopio USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: empacadora_variedad tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.empacadora_variedad USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: huerta_alerta tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.huerta_alerta USING ((huerta_id IN ( SELECT visita.huerta_id
   FROM ops.visita
  WHERE (visita.empacadora_id = app.current_empacadora_id())
UNION
 SELECT negociacion.huerta_id
   FROM ops.negociacion
  WHERE (negociacion.empacadora_id = app.current_empacadora_id()))));


--
-- Name: sesion tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.sesion USING ((usuario_id IN ( SELECT usuario.id
   FROM core.usuario
  WHERE (usuario.empacadora_id = app.current_empacadora_id()))));


--
-- Name: usuario tenant_isolation; Type: POLICY; Schema: core; Owner: -
--

CREATE POLICY tenant_isolation ON core.usuario USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: usuario; Type: ROW SECURITY; Schema: core; Owner: -
--

ALTER TABLE core.usuario ENABLE ROW LEVEL SECURITY;

--
-- Name: acuerdo_compraventa; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.acuerdo_compraventa ENABLE ROW LEVEL SECURITY;

--
-- Name: capacidad_proceso; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.capacidad_proceso ENABLE ROW LEVEL SECURITY;

--
-- Name: corte; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.corte ENABLE ROW LEVEL SECURITY;

--
-- Name: demanda_mercado; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.demanda_mercado ENABLE ROW LEVEL SECURITY;

--
-- Name: negociacion; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.negociacion ENABLE ROW LEVEL SECURITY;

--
-- Name: resultado_seleccion; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.resultado_seleccion ENABLE ROW LEVEL SECURITY;

--
-- Name: riesgo_aceptado; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.riesgo_aceptado ENABLE ROW LEVEL SECURITY;

--
-- Name: acuerdo_compraventa tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.acuerdo_compraventa USING ((negociacion_id IN ( SELECT negociacion.id
   FROM ops.negociacion
  WHERE (negociacion.empacadora_id = app.current_empacadora_id()))));


--
-- Name: capacidad_proceso tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.capacidad_proceso USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: corte tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.corte USING ((acuerdo_id IN ( SELECT a.id
   FROM (ops.acuerdo_compraventa a
     JOIN ops.negociacion n ON ((n.id = a.negociacion_id)))
  WHERE (n.empacadora_id = app.current_empacadora_id()))));


--
-- Name: negociacion tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.negociacion USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: resultado_seleccion tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.resultado_seleccion USING ((corte_id IN ( SELECT c.id
   FROM ((ops.corte c
     JOIN ops.acuerdo_compraventa a ON ((a.id = c.acuerdo_id)))
     JOIN ops.negociacion n ON ((n.id = a.negociacion_id)))
  WHERE (n.empacadora_id = app.current_empacadora_id()))));


--
-- Name: riesgo_aceptado tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.riesgo_aceptado USING ((((visita_id IS NOT NULL) AND (visita_id IN ( SELECT visita.id
   FROM ops.visita
  WHERE (visita.empacadora_id = app.current_empacadora_id())))) OR ((negociacion_id IS NOT NULL) AND (negociacion_id IN ( SELECT negociacion.id
   FROM ops.negociacion
  WHERE (negociacion.empacadora_id = app.current_empacadora_id()))))));


--
-- Name: visita tenant_isolation; Type: POLICY; Schema: ops; Owner: -
--

CREATE POLICY tenant_isolation ON ops.visita USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: visita; Type: ROW SECURITY; Schema: ops; Owner: -
--

ALTER TABLE ops.visita ENABLE ROW LEVEL SECURITY;

--
-- Name: contacto_importador; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.contacto_importador ENABLE ROW LEVEL SECURITY;

--
-- Name: embarque; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.embarque ENABLE ROW LEVEL SECURITY;

--
-- Name: historial_compra; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.historial_compra ENABLE ROW LEVEL SECURITY;

--
-- Name: importador; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.importador ENABLE ROW LEVEL SECURITY;

--
-- Name: inventario_disponible; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.inventario_disponible ENABLE ROW LEVEL SECURITY;

--
-- Name: lead; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.lead ENABLE ROW LEVEL SECURITY;

--
-- Name: linea_orden_venta; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.linea_orden_venta ENABLE ROW LEVEL SECURITY;

--
-- Name: orden_venta; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.orden_venta ENABLE ROW LEVEL SECURITY;

--
-- Name: pago; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.pago ENABLE ROW LEVEL SECURITY;

--
-- Name: reclamo_calidad; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.reclamo_calidad ENABLE ROW LEVEL SECURITY;

--
-- Name: score_importador_evento; Type: ROW SECURITY; Schema: sales; Owner: -
--

ALTER TABLE sales.score_importador_evento ENABLE ROW LEVEL SECURITY;

--
-- Name: embarque tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.embarque USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: inventario_disponible tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.inventario_disponible USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: lead tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.lead USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: linea_orden_venta tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.linea_orden_venta USING ((orden_id IN ( SELECT orden_venta.id
   FROM sales.orden_venta
  WHERE (orden_venta.empacadora_id = app.current_empacadora_id()))));


--
-- Name: orden_venta tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.orden_venta USING ((empacadora_id = app.current_empacadora_id()));


--
-- Name: pago tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.pago USING ((orden_venta_id IN ( SELECT orden_venta.id
   FROM sales.orden_venta
  WHERE (orden_venta.empacadora_id = app.current_empacadora_id()))));


--
-- Name: reclamo_calidad tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.reclamo_calidad USING ((orden_venta_id IN ( SELECT orden_venta.id
   FROM sales.orden_venta
  WHERE (orden_venta.empacadora_id = app.current_empacadora_id()))));


--
-- Name: score_importador_evento tenant_isolation; Type: POLICY; Schema: sales; Owner: -
--

CREATE POLICY tenant_isolation ON sales.score_importador_evento USING ((empacadora_id = app.current_empacadora_id()));


--
-- PostgreSQL database dump complete
--

\unrestrict nsjSqVggz65dhah80n4NxmmaLtQtkngCQHJi78toWKmJ19GEdBdTF8QP3AcP1Nx

