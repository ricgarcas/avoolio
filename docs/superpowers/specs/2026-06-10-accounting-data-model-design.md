# AGR-13 — Modelo de datos contable AgroMesh (diseño)

**Fecha:** 2026-06-10 · **Issue:** [AGR-13](https://linear.app/agromeshai/issue/AGR-13) (S0, 5pt) · **Owner:** Ricardo
**Contrato vinculante:** `agromesh/blueprint → 30_integrations/ACCOUNTING_REQUIREMENTS.md`
**Referencia no vinculante:** `10_data_model/accounting/ACCOUNTING_DATA_MODEL.md` + `accounting_schema.sql` (adoptada como base, con adaptaciones — ver §3)
**Terminología:** `docs/GLOSARIO_CONTABLE.md` — jerga contable mexicana en prosa; los identificadores SQL no cambian (contrato fijado por test)

---

## 1 · Decisiones

| Decisión | Elección | Razón |
|---|---|---|
| Punto de partida | Adoptar el modelo de referencia del blueprint y adaptarlo | 11 entidades ya alineadas a NIF/CFDI y al modelo operacional; el valor agregado va en las invariantes en DB y el boundary |
| Integración | Schema `contabilidad` en el Supabase compartido de AgroMesh | Lo que recomienda el contrato: joins nativos, RLS uniforme, cero infra extra |
| Base contable | Base de devengado (NIF) | Obligatoria a la escala de Avoolio (~50 ton/día). Reporte de flujo de efectivo posible como overlay posterior |
| Alcance AGR-13 | Modelo completo: núcleo contable (libro diario + catálogo de cuentas + periodos) + esqueleto CxC/CxP/pagos/CFDI + vistas `in_*` + vistas `out_*` (stubs) en una sola migración | Las `out_*` son contrato estable desde el día 1: Abisai cablea dashboards aunque regresen vacío |
| Boundary | Un solo schema con prefijos (`in_*` / `out_*`) | Un GRANT, una migración, fácil de razonar (vs 3 schemas o todo en `public`) |
| Fuera de alcance | Elección de PAC (AGR-45) · Carta Porte (post-MVP) · posteo automático de asientos (AGR-25/37/44) · seeds del catálogo para Avoolio | |

---

## 2 · Arquitectura del boundary

```
schema contabilidad
├─ TABLAS INTERNAS (10) — escritura solo del módulo contable
│   config_contable · periodo_contable · cuenta_contable · asiento_contable
│   linea_asiento · costo_operativo · cuenta_por_cobrar · cuenta_por_pagar
│   pago · factura_cfdi
│
├─ VISTAS DE ENTRADA in_* (5) — read-only sobre public, security_invoker = true
│   in_acuerdos · in_cortes · in_resultados_seleccion
│   in_ordenes_venta (header + líneas) · in_embarques
│
└─ VISTAS DE OUTPUT out_* (6) — el contrato; lo único que AgroMesh consume
    out_pnl_calibre · out_ar_aging · out_ap_status
    out_salud_negocio · out_cfdi_status · out_cierre_periodo
```

- **`security_invoker = true` en todas las vistas `in_*`** (Postgres 15+). Sin esto la vista corre con los permisos del dueño y se salta el RLS de las tablas base — fuga cross-tenant directa.
- **Exposición API:** Abisai agrega `contabilidad` a los schemas expuestos de PostgREST. Los roles de la app de AgroMesh reciben `GRANT SELECT` únicamente sobre las vistas `out_*`; las tablas internas no se exponen.
- **RLS** habilitado en las 10 tablas con política por `empacadora_id`, espejo de las políticas del schema operacional.
- **Multi-tenant:** toda tabla y toda vista lleva `empacadora_id`; toda `out_*` se keyea por `empacadora_id` + periodo (+ calibre / importador / orden según aplique), como exige el contrato.

## 3 · Entidades core — referencia adoptada + 5 adaptaciones

Las 10 tablas y 13 enums del modelo de referencia se adoptan tal cual en estructura (campos, FKs operacionales, convenciones `_mxn`/`_usd`, nombres en español). Las adaptaciones — todas bajan invariantes contables del app layer a la base de datos:

1. **Partida doble forzada por trigger.** Al pasar `asiento_contable.estado → 'confirmado'`: si `Σ linea.debe_mxn ≠ Σ linea.haber_mxn`, la transición falla (`EXCEPTION 'asiento desbalanceado'`). La referencia lo dejaba al API.
2. **Inmutabilidad real del libro diario.** Trigger que bloquea `UPDATE`/`DELETE` sobre asientos confirmados y sus líneas. Única transición permitida: `confirmado → revertido` mediante asiento de reversa que referencia `asiento_revertido_id`. Cumple el no negociable de libro diario inmutable ("immutable journal" en el contrato) a nivel físico.
3. **Candado de periodo cerrado.** Trigger que rechaza `INSERT` de asientos cuyo `periodo_id` apunte a un `periodo_contable.estado = 'cerrado'`.
4. **`saldo_pendiente` sin drift.** `cuenta_por_cobrar.saldo_pendiente_usd` y `cuenta_por_pagar.saldo_pendiente_mxn` permanecen almacenados (antigüedad de saldos barata de calcular) pero los recalcula un trigger `AFTER INSERT/UPDATE/DELETE` sobre `pago`, que también actualiza `estado` (pendiente/parcial/pagada).
5. **Solo cuentas hoja postean.** Trigger en `linea_asiento` que valida `cuenta_contable.es_hoja = true` y `activa = true`.

**FX (NIF, obligatorio):** toda línea en USD guarda `tipo_cambio` y su equivalente MXN (la balanza de comprobación agrega en MXN, el USD original se preserva para conciliación). El delta entre tipo de cambio de factura y de pago se postea como asiento `ajuste_fx` contra la cuenta `5600 — Diferencia en Tipo de Cambio`. El *modelo* lo soporta desde hoy; la *generación automática* del asiento es parte de AGR-25/44.

**Catálogo de cuentas:** árbol jerárquico por tenant (`cuenta_padre_id`, `es_hoja`), naturaleza deudora/acreedora, códigos estilo SAT (1000 Activo … 5700 Comisiones). El catálogo sugerido de la referencia se documenta como seed de onboarding, pero **sembrarlo para Avoolio queda fuera de AGR-13**.

**`periodo_contable.cerrado_por`:** UUID sin FK hasta que `usuario` exista en `public` (AGR-8, misma semana); se agrega el FK en una migración posterior.

## 4 · Vistas de output — contrato columna por columna

Lo que sigue es el spec a nivel de campo que el contrato pide entregar al equipo. Tipos: dinero `DECIMAL(14,2)`, tasas/por-kg `DECIMAL(8,4)`, porcentajes `DECIMAL(5,2)`.

### `out_pnl_calibre` — Estado de resultados por calibre · Inicio Admin (4 widgets)
Una fila por (empacadora_id, periodo_id, calibre).

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · periodo_id | UUID | keys |
| anio · mes | INT | denormalizados del periodo para filtrar fácil |
| calibre | VARCHAR(10) | "32", "36", "40", … |
| ingresos_usd · ingresos_mxn | DECIMAL(14,2) | MXN convertido al TC promedio del periodo |
| costo_fruta_mxn · costo_acarreo_mxn · costo_cuadrilla_mxn · costo_empaque_mxn · costo_fijo_mxn | DECIMAL(14,2) | Costo de ventas desglosado (de `costo_operativo` + acuerdos) |
| costo_total_mxn | DECIMAL(14,2) | suma |
| margen_bruto_mxn | DECIMAL(14,2) | ingresos_mxn − costo_total_mxn |
| margen_bruto_pct | DECIMAL(5,2) | |
| margen_por_kg_mxn | DECIMAL(8,4) | |
| volumen_kg | DECIMAL(12,2) | de `resultado_seleccion.desglose_calibre` |
| cajas_vendidas | INT | |

### `out_ar_aging` — Antigüedad de saldos de CxC · Embarques (Ventas) + Admin
Una fila por CxC abierta o pagada en el periodo: (empacadora_id, orden_venta_id, importador_id).

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · orden_venta_id · importador_id · cxc_id | UUID | keys |
| monto_usd · saldo_pendiente_usd | DECIMAL(14,2) | |
| fecha_emision · fecha_vencimiento · fecha_pago_real | DATE | vencimiento = entrega real + `dias_vencimiento_cxc` |
| dias_transcurridos | INT | hoy − fecha_emision |
| bucket | TEXT | `corriente` \| `por_vencer_21_25` \| `vencida` |
| estado | TEXT | pendiente / parcial / pagada / vencida / cancelada |

### `out_ap_status` — Estatus de cuentas por pagar · Admin (planeación de caja)
Una fila por CxP: (empacadora_id, acuerdo_id ∥ corte_id, acreedor).

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · cxp_id · acuerdo_id · corte_id | UUID | acuerdo_id para fruta, corte_id para cuadrilla |
| acreedor_tipo | TEXT | `productor` \| `cuadrilla` |
| productor_id · cuadrilla_id | UUID | uno de los dos |
| monto_mxn · saldo_pendiente_mxn | DECIMAL(14,2) | |
| fecha_emision · fecha_vencimiento | DATE | |
| estado | TEXT | |

### `out_salud_negocio` — Salud del negocio · score compuesto del Owner
Una fila por (empacadora_id, periodo_id).

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · periodo_id | UUID | keys |
| anio · mes | INT | denormalizados |
| margen_neto_mxn | DECIMAL(14,2) | nivel del periodo |
| margen_neto_pct | DECIMAL(5,2) | |
| tendencia_margen_pct | DECIMAL(5,2) | delta vs periodo anterior |
| posicion_caja_mxn | DECIMAL(14,2) | saldo de cuentas 1100/1110 (USD convertido) |
| cxc_abierta_usd · cxc_vencida_usd | DECIMAL(14,2) | exposición |
| cxp_abierta_mxn | DECIMAL(14,2) | |

### `out_cfdi_status` — Estatus de timbrado por pedido · Pedidos (Ventas)
Una fila por (empacadora_id, orden_venta_id) con CFDI emitido o faltante.

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · orden_venta_id · factura_cfdi_id | UUID | factura_cfdi_id NULL = sin facturar |
| uuid_fiscal | UUID | NULL = sin facturar |
| serie · folio | VARCHAR | |
| estatus | TEXT | `vigente` \| `cancelado` \| `sin_facturar` |
| total_mxn · total_usd | DECIMAL(14,2) | |
| fecha_timbrado | TIMESTAMPTZ | |
| xml_url · pdf_url | VARCHAR(500) | |

### `out_cierre_periodo` — Cierre mensual · Admin + Owner ("la verdad del mes")
Una fila por (empacadora_id, periodo_id).

| Columna | Tipo | Nota |
|---|---|---|
| empacadora_id · periodo_id | UUID | keys |
| anio · mes | INT | denormalizados |
| estado_periodo | TEXT | abierto / cerrado |
| ingresos_mxn · ingresos_usd | DECIMAL(14,2) | |
| cogs_mxn | DECIMAL(14,2) | |
| opex_mxn | DECIMAL(14,2) | costos no atribuibles a corte |
| ajuste_fx_mxn | DECIMAL(14,2) | neto del periodo |
| neto_mxn | DECIMAL(14,2) | |
| fecha_cierre | TIMESTAMPTZ | NULL si abierto |

Todas son vistas normales en V1. Si `out_pnl_calibre` resulta lenta (joinea el JSONB `desglose_calibre`), se convierte a materialized view con refresh al cierre de periodo — optimización diferida, no decisión de hoy.

## 5 · Flujo de eventos → asientos (diseño hoy, implementación en S1–S3)

| Evento operacional | Efecto contable | Issue |
|---|---|---|
| `acuerdo_compra_venta` confirmado | CxP productor (precio × volumen) + asiento `compra_fruta` | AGR-25 |
| `resultado_seleccion` creado | Costo de ventas asignado por calibre + CxP cuadrilla + asiento `costo_operativo` | AGR-25 / AGR-37 |
| `embarque.estado = 'entregado'` | CxC importador + reconocimiento de ingreso (asiento `venta`); vencimiento = entrega + `dias_vencimiento_cxc` | AGR-44 |
| Pago recibido/emitido | Liquida CxC/CxP (asiento `pago_cxc`/`pago_cxp`) + asiento `ajuste_fx` si TC pago ≠ TC factura | AGR-44 / AGR-68 |
| Cierre de mes | Asiento `cierre_periodo`, candado del periodo | AGR-37 |

El modelo trae desde hoy todos los FKs operacionales (`corte_id`, `acuerdo_id`, `orden_venta_id`, `embarque_id`) para soportar esto sin migraciones futuras.

## 6 · Integridad, errores y testing

**Errores:** las invariantes fallan en la DB con mensajes accionables — `asiento desbalanceado: debe=X haber=Y`, `periodo YYYY-MM cerrado`, `cuenta X no es hoja o está inactiva`, `asiento confirmado es inmutable`.

**Tests (scripts SQL de aserción, corren contra Supabase branch o Postgres local):**
1. Asiento desbalanceado no puede confirmarse.
2. Asiento confirmado rechaza UPDATE/DELETE (y sus líneas también).
3. Periodo cerrado rechaza asientos nuevos.
4. RLS: tenant A no ve filas de tenant B en ninguna tabla ni vista.
5. Pago parcial decrementa `saldo_pendiente` y transiciona estado a `parcial`; pago total a `pagada`.
6. **Test de contrato:** cada `out_*` devuelve exactamente las columnas de §4 (nombre + tipo) — si una migración rompe el contrato, el test truena antes que el dashboard de Abisai.

## 7 · Entregables y coordinación

**Entregables de AGR-13:**
1. Este spec (modelo + contrato de columnas).
2. Una migración SQL: schema `contabilidad` completo (enums, 10 tablas, triggers, RLS, 5 `in_*`, 6 `out_*`, GRANTs).
3. Scripts de test SQL (§6).
4. Nota de boundary para Abisai: exponer `contabilidad` en PostgREST, consumir solo `out_*`.

**Por coordinar con el equipo:**
- Repo donde viven las migraciones de `contabilidad` (el repo de AgroMesh lo monta Abisai en AGR-12; mientras, viven aquí y se mueven después).
- Timing: las vistas `in_*` dependen de que `schema.sql` esté corrido en el Supabase compartido (AGR-7, esta semana). La migración se escribe ya contra `10_data_model/schema.sql` y se aplica cuando AGR-7 cierre.

**Explícitamente fuera:** elección de PAC y todo CFDI funcional (AGR-45 — la tabla `factura_cfdi` existe desde hoy, vacía) · Carta Porte (post-MVP) · posteo automático (S1–S3) · seeds de catálogo para Avoolio (onboarding) · reporte cash-basis (overlay futuro).
