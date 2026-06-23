# SICOA — spike de scraping

Portal: https://sicoa.apeamac.com → redirige a https://sicoa.senasica.gob.mx/
Stack del portal: ASP.NET (IIS), server-rendered, sesión por cookie + ViewState.

## Credenciales

8 usuarios en 1Password → `op://Personal/SICOA` (Secure Note, notesPlain).
Formato `usuario:password` separado por `|`. Cada usuario corresponde a una
huerta/empacadora distinta — todavía falta mapear cuál es cuál.

## Plan

### Fase 1 — Exploración (ahora)

Mapear el portal con sesión real para descubrir:
- Estructura de URLs (`/Consulta`, `/Reportes`, etc.)
- Qué endpoints devuelven JSON vs HTML
- Si hay descarga de CSV/Excel nativa (mucho mejor que parsear tablas)
- Si el ViewState importa o si las consultas son GET puros

```bash
node scripts/sicoa/explore.mjs
```

Abre Chromium con DevTools. Loguéate manual con cualquier clave, navega por
los reportes que nos interesan, cierra la ventana. Quedan en `_capture/`:
- `session-<ts>.har` — todas las requests con payloads
- `pages/NNN-<url>.html` — snapshot de cada página

### Fase 2 — Schema raw + scraper headless

Con la sesión mapeada:
- Schema `sicoa_raw` en Supabase: 1 tabla por tipo de reporte, columna `payload jsonb` + metadata (`fetched_at`, `clave_huerta`, `fuente_url`).
- Scraper headless que entra con cada clave y guarda blobs.
- Vistas `in_sicoa_*` que normalizan a tipos del dominio (siguiendo patrón AGR-13).

### Fase 3 — Programación

- Cadencia probable: diaria o post-corte (TBD).
- Runner: GitHub Actions o un worker en alguno de los VPS existentes.
- Credenciales vía `op run --env-file=...` o secretos de GHA.

## No usar `.env` para creds

Las claves se inyectan en runtime con `op run --` o `op read`. Nunca tocan
disco fuera de 1Password.
