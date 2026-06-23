# Análisis de unificación del esquema de datos — AgroMesh / AvoOlio

**Fecha:** 2026-06-23 · **Autor:** Ricardo García (boundary contable / AGR-13)
**Estado:** análisis para decidir siguientes pasos. No es un plan de migración aprobado.

Este documento inventaria —**en vivo, no según docs**— todo lo que existe hoy
en datos y código, mide qué tan divergentes son los modelos, y propone un
camino de convergencia hacia un esquema canónico, con las extensiones concretas
que necesita la contabilidad.

---

## 1. Resumen ejecutivo

- Hay **dos backends con dos modelos de datos distintos**, ambos vivos, más un
  tercer modelo local de staging (el mío).
- El **agente (Calculadora)** corre sobre un **modelo multi-schema normalizado**
  (`core/ops/sales/agent/comms/ref/sicoa`) en Railway, y es **quien genera la
  data viva**.
- El **dashboard** corre sobre un **modelo plano en `public`** en una DB
  distinta, y **lee la del agente en solo-lectura**.
- **Decisión propuesta:** el **multi-schema del agente (Railway) es el canónico.**
  Todo lo demás converge hacia él **por adición y por contrato**, no aplanando.
- El **boundary contable (AGR-13)** se monta encima del canónico repuntando sus
  vistas `in_*` a `ops/core/sales` de Railway —el mismo patrón que ya usa el
  dashboard.

---

## 2. El mapa real (quién es dueño de qué)

| Pieza | Repo | Corre en | Modelo de datos | Estado |
|---|---|---|---|---|
| **Agente / Calculadora** | `agromesh/agent` (Next 16 + Drizzle) | Railway (proj. `evolution-api`; DB en proj. `db`) | **Multi-schema** `core/ops/sales/agent/comms/ref/sicoa`, RLS por `empacadora_id` | **Vivo.** Motor determinístico + LLM Haiku; flujos onboarding/visita/negociación/HITL; pricing multi-calibre con tests. Genera la data viva. |
| **Dashboard / webapp** | `agromesh/platform` (monorepo Turbo), `apps/web` | Railway (proj. `diplomatic-learning`) | **Plano en `public`** (39 tablas, SQL a mano en `packages/db`) — **DB distinta** | `apps/web` real (17 rutas, auth). **Lee la DB del agente read-only** (`apps/web/src/lib/agent-*.ts`) y guarda sus decisiones en su propia `resolucion_hitl`. |
| **Landing** | `agromesh/agromesh-web` | Vercel | Ninguno (estático, i18n) | Marketing puro, 1 página. No es app. |
| **Staging contable (mío)** | local `avoolio` + `agromesh` (Herd PG18) | Local | `public` plano (Monday + SICOA) **+** schema `contabilidad` (AGR-13) | Parche de staging + el boundary contable diseñado contra el modelo normalizado. |

### Data viva en Railway (DB `db`, snapshot 2026-06-23)

- `core.huerta` **4,368** · `core.acopista` 7 · `core.empacadora` 1 · `core.productor` 4
- `comms.mensaje_whatsapp` **1,026** · `sesion_conversacional` 170 · `transicion_estado` 495
- `agent.evento_auth` **533** · `agent.accion` 178 · `precio_banda_snapshot` 105
- `ops.negociacion` 30 · `ops.visita` 53 · `ref.*` catálogos sembrados

### Data en mi staging local (`avoolio.public`)

- `huerta` 918 · `productor` 693 · `acopiador` 14 · `cuadrilla` 15 · `acarreador` 10
- `corte` 446 · `resultado_lote` **2,356** · `lote_fuera_norma` 661 · `precio_calc` 17 · `cxp` **292**
- `sicoa_raw.huerta_listado_general` **41,084** (scrape SICOA)

---

## 3. Hallazgo central

La DB `db` de Railway que introspeccioné **es la base del agente** (por eso trae
el multi-schema con data viva). El dashboard **no escribe ahí**: la consume
read-only vía `AGENT_SUPABASE_URL` + service key.

> **Ese patrón —un consumidor que lee el canónico read-only y persiste lo suyo
> aparte— es exactamente el que debe usar la contabilidad.** El dashboard ya
> probó que funciona.

Mi `avoolio.public` local fue un **parche de staging** de cuando no tenía acceso
a schemas en Supabase. Coincide en espíritu con el modelo plano del dashboard,
pero **mi activo real —el schema `contabilidad`— ya está diseñado contra el
modelo normalizado** (las 31 tablas), no contra el plano. O sea: ya apunto al
lado correcto.

---

## 4. Modelo canónico

**Canónico = multi-schema del agente en Railway.** Razones:

1. Es lo **vivo** y con data de producción.
2. Es contra lo que el dashboard **ya lee**.
3. La contabilidad **ya está diseñada** contra ese estilo normalizado.
4. Aplanarlo implicaría rediseñar agente + dashboard que ya corren. Costo alto,
   cero upside.

El camino plano (`public`) **se deprecia** como destino; sobrevive solo como
fuente temporal de la data Monday/SICOA hasta migrarla.

---

## 5. Mapeo columna-por-columna (canónico ⟵ staging)

Leyenda: **=** equivalente · **+RW** solo en Railway · **+LOC** solo en mi local
(candidato a adición) · **≠** mismo concepto, forma distinta.

### 5.1 huerta — `core.huerta` ⟵ `public.huerta`
| core.huerta (RW) | public.huerta (LOC) | Nota |
|---|---|---|
| `codigo_hue` | `hue` | = (renombrar al mapear) |
| `nombre`, `productor_id`, `municipio` | `nombre`, `productor_id`, `municipio` | = |
| `variedad_id`, `ubicacion_lat/lng`, `poligono_geojson`, `superficie_hectareas`, `edad_arboles_anios`, `variedades_secundarias`, `fecha_ultimo_corte`, `estado`, `metadata`, `deleted_at` | — | +RW (el canónico es más rico) |
| `altitud_msnm` | `altura` | = |
| — | `punto_reunion`, `bascula` | **+LOC** → operativos del acopio; candidatos a `metadata` o columnas nuevas |

### 5.2 productor — `core.productor` ⟵ `public.productor`
| core.productor (RW) | public.productor (LOC) | Nota |
|---|---|---|
| `nombre`, `rfc`, `municipio` | `nombre`, `rfc`, `municipio` | = |
| `telefono`, `whatsapp_phone` | `tel` | = |
| `ubicacion_lat/lng`, `estado`, `metadata`, `deleted_at` | — | +RW |
| — | `correo` | +LOC (menor) |
| — | **`beneficiario`**, **`dias_credito`** | **+LOC → CRÍTICO para CxP/facturación.** Adición propuesta. |

### 5.3 acopiador — `core.acopista` ⟵ `public.acopiador`
| core.acopista (RW) | public.acopiador (LOC) | Nota |
|---|---|---|
| `nombre`, `whatsapp_phone`, `activo` | `nombre`, `whatsapp`, `estatus` | = |
| `acopio_id`, `email`, `rol`, `telefono_alt`, `permisos`, `inicio_at/fin_at`, `razon_baja`, `metadata` | — | +RW |
| — | `zona` | +LOC (candidato a `metadata`) |

### 5.4 cuadrilla — `core.cuadrilla` ⟵ `public.cuadrilla`
| core.cuadrilla (RW) | public.cuadrilla (LOC) | Nota |
|---|---|---|
| `tarifa_mxn_kg` | `tarifa_kg` | = |
| `empresa`, `nombre_responsable`, `telefono`, `capacidad_personas`, `certificacion_inocuidad`, `variedades_certificadas`, `deleted_at` | `nombre`, `tipo` | ≠ (RW más rico; mapear `nombre`→`empresa/responsable`) |
| — | `tarifa_dia` | +LOC → modelo de costo por día; adición si aplica |

### 5.5 acarreador — **sin equivalente en Railway**
`public.acarreador` (`nombre`, `tipo_unidad`, `tarifa_viaje`) **no existe** en el
canónico. **Adición propuesta:** entidad `core.acarreador` (actor logístico) —
necesaria para costear acarreo en CxP / AGR-25.

### 5.6 corte — `ops.corte` ⟵ `public.corte`
Divergencia máxima: el canónico es relacional (`acuerdo_id`, `huerta_id`,
`cuadrilla_id`, `acopio_id` FKs, `status` enum, `volumen_cortado_kg`,
`costo_cuadrilla_mxn_kg`); el local es un mirror de Monday con texto plano
(`huerto`, `productor`, `floracion`, `camion`, `visita1/2`, `precio_pactado`).
**Migración = resolver los textos a FKs** contra `core.*`/`ops.acuerdo_compraventa`.

### 5.7 resultado — `ops.resultado_seleccion` ⟵ `public.resultado_lote`
| ops.resultado_seleccion (RW) | public.resultado_lote (LOC) | Nota |
|---|---|---|
| `volumen_total_kg`, `desglose_calibre`(jsonb), `desglose_calidad`(jsonb), `pct_exportacion/nacional/rechazo_real` | `kilogramos`, `nacional`, `cat1`, `cat2`, `merma` | ≠ (RW agrega en jsonb; LOC explícito) |
| `corte_id`, `fecha_proceso`, `metadata` | `huerta`, `productor` (texto), `fecha_recepcion/cosecha`, `semana`, `jefe_acopio`, `tipo_corte` | mapear a FKs |
| — | **`ajuste_volumen`, `ajuste_desviacion`, `autorizado`, `comision`** | **+LOC → campos contables.** Adición o tabla puente. |

### 5.8 Sin equivalente en el canónico (gaps contables)
- **`public.cxp`** (cuentas por pagar a productor/corte/acarreo, 292 filas):
  el canónico solo tiene **`sales.pago`** (lado de **cobranza/AR**, ventas US).
  **No hay CxP / AP.** Adición mayor → núcleo de AGR-44/AGR-25.
- **`public.lote_fuera_norma`** (penalizaciones, 661 filas): sin equivalente.
  Adición (tabla propia) o fold dentro de `ops.resultado_seleccion`.
- **`public.precio_calc`** (17): **lo gana Railway.** El canónico tiene
  `agent.precio_banda_snapshot`, mucho más rico (costo_acarreo/corte aplicado,
  bandas 7 niveles, calibre, política USDA). `precio_calc` se **deprecia**.

---

## 6. Extensiones propuestas al esquema de Railway

Derivadas del mapeo. Todas son **aditivas** (no rompen agente ni dashboard):

1. **`core.productor`** → agregar `beneficiario text`, `dias_credito int`.
2. **`core.acarreador`** → nueva entidad (actor logístico + tarifa).
3. **CxP / cuentas por pagar** → nueva familia de tablas (o dentro del schema
   `contabilidad`): pagos a productor/corte/acarreo, factura, forma de pago,
   estado. Espeja `public.cxp`.
4. **Penalizaciones** → `ops.resultado_seleccion` + campos
   (`ajuste_volumen`, `ajuste_desviacion`, `autorizado`, `comision`) o tabla
   `ops.lote_fuera_norma`.
5. **Schema `contabilidad` (AGR-13)** → se añade como schema aditivo sobre la DB
   canónica, con sus `in_*` leyendo `ops/core/sales` y sus `out_*` como contrato.

---

## 7. Boundary contable (cómo encaja AGR-13)

Patrón idéntico al del dashboard: **leer el canónico, persistir lo propio.**

- Las vistas **`in_*`** (hoy leen mi `public` local) se **repuntan** a los
  schemas `ops/core/sales` de Railway (`security_invoker`, RLS por tenant).
- El schema `contabilidad` (ledger, catálogo de cuentas, asientos, CxC/CxP)
  vive **aditivo** sobre la DB canónica.
- Las **`out_*`** siguen siendo el contrato hacia la plataforma.

Unificas por **contrato**, no fusionando tablas.

---

## 8. Plan sugerido (orden de desbloqueo)

1. **Ratificar "Railway canónico"** + estas extensiones (este doc) con Mariano/Alberto.
2. **Confirmar** que el agente apunta a Railway `db` (no al Supabase viejo) — único punto sin verificar.
3. **AGR-13:** repuntar `in_*` al multi-schema real de Railway; montar `contabilidad` aditivo.
4. **AGR-25** cost capture (acarreo/corte/fijos) → alimenta el P&L.
5. **AGR-37** P&L por calibre (coordinar con Abisai: es el "Inicio 4 widgets").
6. **AGR-45** cerrar el spike CFDI (FacturAPI ya evaluado) → decisión PAC → AGR-87.
7. Migrar la data Monday/SICOA de `public` local → canónico (resolviendo textos a FKs); luego apagar Supabase legacy.

---

## 9. Pendiente de confirmar

- **El agente apunta a Railway `db`** y no al Supabase viejo (`sfkhmlaaohidmotdnmlh`).
  90% de confianza por el match exacto schema + data; no verificado para no jalar
  secretos del proyecto del agente.
- Si la DB del **dashboard** (plano `public`, `goaepoxaqyemzxpbjxin`) se consolida
  también en el proyecto `db` de Railway (Ricardo mencionó unificar proyectos
  después).
