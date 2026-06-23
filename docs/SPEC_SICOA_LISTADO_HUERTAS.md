# Spec — Exportación SICOA: Listado General de Huertas

**Autor:** Ricardo · **Estado:** draft · **Fecha:** 2026-06-16
**Issue Linear relacionado:** TBD (AGR-XX)

## 1. Contexto

SICOA (Sistema Integral de Cosecha de Aguacate) es el portal oficial
APEAM/SENASICA donde se registra el catálogo de huertas autorizadas a
exportar a USA. Las huertas son la entidad de la que cuelgan todos los
permisos fitosanitarios y embarques.

Avoolio necesita una copia operacional de este catálogo en Supabase para:

- Cruzar huertas que opera Avoolio (en `acopio.huerta`) contra el padrón
  oficial APEAM y detectar inconsistencias (clave que no existe, productor
  diferente, hectáreas distintas).
- Saber si la huerta está activa/baja en SICOA antes de programar acopio.
- Tener histórico — si APEAM da de baja una huerta a mitad de temporada,
  necesitamos saber cuándo y por qué.

Este spec cubre **solo el "Listado General de Huertos"**. Otros reportes
SICOA (Huertos Limpios, Cortes Programados, Materia Seca, etc.) van en
specs separados — cada uno con cadencia distinta.

## 2. Lo que ya está probado

Spike en `scripts/sicoa/` confirma:

- Login automatizado funciona con `playwright-extra` + stealth plugin
  (necesario para pasar Radware Bot Manager / `stormcaster.js`).
- 4 de 8 credenciales del Secure Note `op://Personal/SICOA` siguen vivas
  (a 2026-06-16): `adrian.acmargo`, `Laga.Le`, `RO.LEMO`, `LIXA.QUIROS`.
- URL del reporte: `https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx`
- Pantalla = formulario ASP.NET con dropdown **Estado** (default `MICHOACAN`),
  textbox **Criterio de búsqueda**, botón **Consultar**. Tras consultar,
  se renderiza una grilla DevExpress server-side (no CSV/Excel export).

## 3. Decisiones tomadas (2026-06-16)

1. **Estado:** solo `MICHOACAN` por ahora (Avoolio opera en Pátzcuaro).
   Si se expande a Jalisco u otros, se agrega a la config sin tocar código.
2. **Cred del cron:** rotar entre las 4 vivas del Secure Note (`adrian.acmargo`,
   `Laga.Le`, `RO.LEMO`, `LIXA.QUIROS`). Pedir cred de servicio dedicada a APEAM
   está en backlog — cuando se tenga, se mueve a `op://Personal/SICOA-bot`.
3. **Cadencia:** **semanal**, lunes 06:00 CST. Si el delta de filas semana
   contra semana resulta más grande de lo esperado, se sube a diario.

## 4. Investigación — resultados (2026-06-16)

Ejecutado vía `scripts/sicoa/probe-consulta.mjs` y `probe-expand.mjs`:

- ❌ **Consulta con criterio vacío no devuelve nada.** El server obliga
  a poner al menos 1 char en el textbox `tbCriterio`. Esto rompe la
  estrategia "1 consulta = catálogo completo".
- ✅ **No hay paginación visible.** URUAPAN devolvió 36 filas en 1 sola
  respuesta. Asumimos sin pager hasta encontrar un criterio que sí lo
  dispare (improbable en MVP-Pátzcuaro).
- ✅ **Columnas confirmadas (5):**
  `Huerta | Sagarpa | Status | Localidad | Municipio`.
  El valor de `Status` es el dato más útil: `ALTA EN PADRON CERTIFICADO`,
  `HUERTO PROGRAMABLE`, `HUERTO NO PROPUESTO`, etc. Define si la huerta
  está apta para corte/exportación.
- ✅ **Clave Sagarpa = identificador estable** (ej. `HUE08160661012`).
  Formato `HUE` + 2 dígitos estado + 3 municipio + 6 secuencia. Es la
  llave natural para `sicoa_raw.huerta_listado_general`.
- ❌ **No hay master-detail (expand).** El `+` que aparece en el render
  era decorativo. No hay datos adicionales tras click.
- ⚠ **Búsqueda es substring** sobre múltiples columnas. URUAPAN trajo
  huertas cuyo municipio es TANCITARO porque "URUAPAN" aparecía en otro
  campo (¿localidad histórica?). Implicación: si iteramos por municipios,
  hay que filtrar resultados post-fetch para descartar matches falsos.

Capturas: `_capture/expand-2026-06-16T21-02-31-419Z/`

## 5. Diseño técnico

### 5.1 Schema Supabase

Nuevo schema `sicoa_raw` (mismo patrón que el resto de fuentes externas):

```sql
create schema if not exists sicoa_raw;

create table sicoa_raw.huerta_listado_general (
  id              bigserial primary key,
  fetched_at      timestamptz not null default now(),
  estado          text not null,                 -- 'MICHOACAN'
  criterio        text not null,                 -- criterio enviado al server
  clave_sagarpa   text not null,                 -- ej. 'HUE08160661012'
  nombre_huerta   text not null,                 -- ej. 'PATZCUARO'
  status          text not null,                 -- 'ALTA EN PADRON CERTIFICADO', ...
  localidad       text,
  municipio       text not null,
  payload         jsonb not null,                -- fila cruda completa
  scraper_version text not null,
  cred_user       text not null,
  unique (clave_sagarpa, fetched_at)
);

create index on sicoa_raw.huerta_listado_general (clave_sagarpa, fetched_at desc);
create index on sicoa_raw.huerta_listado_general (municipio);
create index on sicoa_raw.huerta_listado_general using gin (payload);
```

Vista normalizada con el último snapshot por huerta:

```sql
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
```

### 5.2 Scraper

`scripts/sicoa/scrape-listado-huertas.mjs`:

```
1. Login (playwright-extra + stealth) con cred rotada del Secure Note
2. Para cada criterio configurado (default ['PATZCUARO']):
     a. Navegar a SIC_ListadoGeneralDeHuertos.aspx
     b. Estado = MICHOACAN (default ya seleccionado)
     c. Type criterio en tbCriterio
     d. Click bConsultar, esperar a que desaparezca "Loading…"
     e. Parsear grilla → array de objetos {nombre_huerta, clave_sagarpa, status, localidad, municipio}
     f. Filtrar post-fetch: descartar filas cuyo municipio NO matchee criterio
        (porque la búsqueda substring trae falsos positivos)
3. Dedupear por clave_sagarpa (criterios pueden solaparse)
4. Insertar batch en sicoa_raw.huerta_listado_general
5. Logout (cerrar sesión explícito)
```

**Lista inicial de criterios:** `['PATZCUARO']`. Cuando Avoolio se expanda
a otros municipios, se agrega a `SICOA_CRITERIOS` env var (CSV).

- **Inputs (env):** `SICOA_USER`, `SICOA_PASS`, `SICOA_ESTADOS` (CSV),
  `SUPABASE_DB_URL`. Inyectados con `op run --env-file=...`.
- **Idempotencia:** no aplica — insertamos siempre, histórico.
- **Tiempo estimado por corrida:** 30-60s (1 estado, ~10K huertas).
- **Manejo de errores:**
  - Si login falla → exit 2, alerta.
  - Si tabla viene vacía cuando histórico tenía N filas → exit 3
    (probable cambio del portal), NO insertar el batch.
  - Reintentos: 1 vez con backoff de 30s si Radware tira `429`.

### 5.3 Programación

GitHub Actions, workflow `sicoa-listado-semanal.yml`:

- Cron `0 12 * * 1` UTC = lunes 06:00 CST.
- Inyecta secrets desde el repo (`SICOA_USER`, `SICOA_PASS`, `SUPABASE_DB_URL`).
- En caso de fallo, notifica a Slack (canal `#avoolio-alerts`, a crear).

### 5.4 Observabilidad

- Tabla `sicoa_raw.scrape_log`:
  - `started_at`, `finished_at`, `status` (`ok|error`), `rows_inserted`,
    `error_message`, `scraper_version`.
- Vista `acopio.in_sicoa_health` para el dashboard: última corrida,
  delta de filas vs corrida previa, cred usada.

## 6. Riesgos y mitigaciones

| Riesgo | Probabilidad | Mitigación |
|---|---|---|
| APEAM cambia el portal | media | Vista `in_sicoa_huerta` desacopla; cambios afectan solo el scraper |
| Radware empieza a tirar más fuerte | media-baja | Lo enfrentaremos cuando pase; existe `playwright-stealth-evasions` como next step |
| Cred expira sin avisar | alta | Pedir cred de servicio dedicada + alerta si scraper falla 2× seguidas |
| APEAM detecta scraping y bloquea IP | baja | Solo 1 corrida/día, user-agent normal, headers humanos |

## 7. Plan de ataque

- ~~**Día 1** — Investigación.~~ **Hecho 2026-06-16.**
- **Día 2** — Schema + vista en Supabase + migration `sicoa_raw.*`.
- **Día 3** — Scraper `scrape-listado-huertas.mjs` + test contra prod
  con criterio `PATZCUARO`.
- **Día 4** — Cron en GHA semanal + observabilidad + alerta a Slack.

Total restante: 3 días.

## 8. Fuera de alcance

- Otros reportes SICOA (van en specs separados).
- UI en el dashboard de Avoolio para visualizar este catálogo
  (se agrega en otra historia consumiendo `in_sicoa_huerta`).
- Reconciliación automática contra `acopio.huerta` (otra historia).
