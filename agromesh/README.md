# Módulo de contabilidad AgroMesh — boundary

Schema `contabilidad` en el Supabase compartido. Owner: Ricardo (AGR-13).
Spec: `docs/superpowers/specs/2026-06-10-accounting-data-model-design.md`.
Contrato: `blueprint/30_integrations/ACCOUNTING_REQUIREMENTS.md`.

## Para Abisai (plataforma)

1. **Prerequisito:** `blueprint/10_data_model/schema.sql` aplicado en `public` (AGR-7).
2. Aplicar `migrations/0001_contabilidad.sql`.
3. Exponer el schema `contabilidad` en la API (Dashboard → Settings → API → Exposed schemas).
4. Consumir **solo las vistas `out_*`** (GRANT SELECT ya incluido para
   `authenticated`/`service_role`). Las tablas internas y las `in_*` no son parte del contrato.
5. Las `out_*` filtran por `contabilidad.current_empacadora()`, que hoy lee
   `current_setting('app.empacadora_id')`. Cuando AGR-8 defina el claim de tenant
   en el JWT, se cambia **solo el cuerpo de esa función** — avisar a Ricardo.

## Las 6 vistas del contrato

Terminología en prosa: `docs/GLOSARIO_CONTABLE.md` (jerga contable mexicana).

| Vista | Reporte (en cristiano) | Consume | Granularidad |
|---|---|---|---|
| `out_pnl_calibre` | Estado de resultados por calibre | Admin Inicio (4 widgets) | empacadora + periodo + calibre |
| `out_ar_aging` | Antigüedad de saldos de CxC | Ventas Embarques + Admin | empacadora + orden + importador |
| `out_ap_status` | Estatus de cuentas por pagar | Admin | empacadora + acuerdo/corte + acreedor |
| `out_salud_negocio` | Salud del negocio | Owner | empacadora + periodo |
| `out_cfdi_status` | Estatus de timbrado por pedido | Ventas Pedidos | empacadora + orden_venta |
| `out_cierre_periodo` | Cierre mensual | Admin + Owner | empacadora + periodo |

Las columnas exactas están fijadas por test: `tests/09_contrato_outputs.sql`.
Cambiar una columna = romper el contrato = coordinar antes.

## Tests

`./test.sh` — corre contra el PostgreSQL local (Herd, `127.0.0.1:5432`, user `root`;
configurable vía `PGHOST`/`PGPORT`/`PGUSER`/`PSQL_BIN`). Crea una base efímera
`agromesh_test`: aplica el schema operacional del blueprint + la migración + seed,
corre los 10 archivos de `tests/` y dropea la base al salir.
