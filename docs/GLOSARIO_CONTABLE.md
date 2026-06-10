# Glosario contable AgroMesh — EN ↔ jerga mexicana

> **Fuente de verdad de terminología.** En prosa (docs, Linear, demos, conversaciones con el contador del cliente) se usa SIEMPRE el término mexicano. Los identificadores SQL (`out_pnl_calibre`, `debe_mxn`, …) NO cambian: están fijados por el test de contrato (`agromesh/tests/09_contrato_outputs.sql`).

## El libro contable

| Inglés | Término mexicano | Qué es | En el schema |
|---|---|---|---|
| Chart of accounts | **Catálogo de cuentas** | Lista jerárquica de cuentas (1000 Activo → 1100 Bancos) | `cuenta_contable` |
| Ledger / general ledger | **Libro mayor** | Saldos acumulados por cuenta | se deriva de `linea_asiento` |
| Journal | **Libro diario** | Registro cronológico de todos los movimientos | `asiento_contable` + `linea_asiento` |
| Journal entry | **Asiento contable** (los contadores dicen **póliza**) | Un movimiento completo: fecha + líneas que balancean | `asiento_contable` |
| Journal line | **Línea / movimiento** (de la póliza) | Un cargo o abono a una cuenta | `linea_asiento` |
| Debit / Credit | **Cargo / Abono** (las columnas: **debe / haber**) | Los dos lados de la partida doble | `debe_mxn` / `haber_mxn` |
| Double-entry | **Partida doble** | Σcargos = Σabonos en todo asiento | trigger `check_asiento_balanceado` |
| Trial balance | **Balanza de comprobación** | Verificación de que el mayor balancea (en MXN) | agregación sobre `linea_asiento` |
| Immutable journal | **Libro diario inmutable** | Confirmado no se edita ni borra; se corrige con reversa | trigger `bloquear_asiento_inmutable` |
| Reversal entry | **Asiento de reversa** (o **contrapóliza**) | Asiento nuevo que cancela uno confirmado | `asiento_revertido_id` |
| Draft / posted / reversed | **Borrador / confirmado / revertido** | Ciclo de vida del asiento | enum `asiento_estado` |
| Leaf account | **Cuenta de detalle** (vs **cuenta acumulativa**) | Solo las de detalle reciben movimientos | `es_hoja` |
| Accounting period | **Periodo contable** | El mes contable; cerrado = candado | `periodo_contable` |
| Period close | **Cierre mensual** (cierre del periodo) | Congelar el mes: ya no entran asientos | enum `periodo_estado`, trigger `check_periodo_abierto` |
| Accrual basis | **Base de devengado** (NIF) | Se reconoce al facturar/incurrir, no al cobrar/pagar | decisión de diseño del módulo |
| Cash basis | **Base de flujo de efectivo** | Se reconoce al cobrar/pagar (NO usamos esta) | — |

## Cobrar, pagar y vender

| Inglés | Término mexicano | Qué es | En el schema |
|---|---|---|---|
| Accounts receivable (AR) | **Cuentas por cobrar (CxC)** | Lo que los importadores nos deben (USD) | `cuenta_por_cobrar` |
| Accounts payable (AP) | **Cuentas por pagar (CxP)** | Lo que debemos a productores/cuadrillas (MXN) | `cuenta_por_pagar` |
| AR aging | **Antigüedad de saldos** (de CxC) | CxC clasificadas por cuánto llevan vencidas | `out_ar_aging` |
| Aging bucket | **Rango de antigüedad** | Corriente / por vencer / vencida | columna `bucket` |
| Outstanding balance | **Saldo pendiente** | Lo que falta por cobrar/pagar de un documento | `saldo_pendiente_usd` / `_mxn` |
| Payment | **Pago** (CxC: **cobranza**; CxP: **pago a proveedores**) | Aplicación de dinero a un documento | `pago` |
| Partial payment | **Pago parcial / abono a cuenta** | Pago que no liquida el documento | estado `parcial` |
| P&L / income statement | **Estado de resultados** | Ingresos − costos − gastos = utilidad | `out_pnl_calibre`, `out_cierre_periodo` |
| COGS | **Costo de ventas** | Fruta + acarreo + cuadrilla + empaque | `costo_operativo` + prorrateo |
| Gross margin | **Utilidad bruta / margen bruto** | Ingresos − costo de ventas | `margen_bruto_mxn` |
| Net margin | **Utilidad neta / margen neto** | Después de todos los gastos | `margen_neto_mxn` |
| FX gain/loss | **Utilidad o pérdida cambiaria** (fluctuación cambiaria) | Delta entre TC de factura y TC de cobro (NIF) | asiento tipo `ajuste_fx`, cuenta 5600 |
| Exchange rate | **Tipo de cambio (TC)** | MXN por USD | `tipo_cambio`, `tipo_cambio_factura` |
| Cash position | **Posición de caja** | Saldo en bancos al corte | `posicion_caja_mxn` (cuentas 11xx) |

## Fiscal mexicano (no tiene equivalente gringo — así se dice y punto)

| Término | Qué es |
|---|---|
| **CFDI 4.0** | Comprobante Fiscal Digital por Internet — LA factura electrónica obligatoria (XML) |
| **Timbrado / timbrar** | Certificación del CFDI ante el SAT; "estatus de timbrado" = si la factura ya es válida fiscalmente |
| **PAC** | Proveedor Autorizado de Certificación — el tercero que timbra (Facturama, SW Sapien, Finkok…) |
| **SAT** | Servicio de Administración Tributaria — el fisco |
| **UUID fiscal (folio fiscal)** | Identificador único que el SAT asigna al timbrar | 
| **Serie y folio** | Numeración interna de la factura (A-001) |
| **PUE / PPD** | Pago en Una sola Exhibición / Pago en Parcialidades o Diferido — método de pago del CFDI |
| **Complemento de pago** | CFDI adicional obligatorio cuando cobras una factura PPD |
| **Cancelación** | Anular un CFDI ante el SAT (con motivo y, a veces, UUID de sustitución) |
| **NIF** | Normas de Información Financiera — el "GAAP mexicano" (la B-15 rige lo cambiario) |
| **RESICO** | Régimen Simplificado de Confianza (régimen fiscal — el de Ricardo, no del cliente) |

## Los 6 reportes del contrato (nombre para humanos)

| Vista SQL | En prosa decimos |
|---|---|
| `out_pnl_calibre` | **Estado de resultados por calibre** |
| `out_ar_aging` | **Antigüedad de saldos de cuentas por cobrar** |
| `out_ap_status` | **Estatus de cuentas por pagar** |
| `out_salud_negocio` | **Salud del negocio** |
| `out_cfdi_status` | **Estatus de timbrado por pedido** |
| `out_cierre_periodo` | **Cierre mensual** |

## Operación aguacatera (contexto para no perderse)

| Término | Qué es |
|---|---|
| **Empacadora** | La planta que compra, selecciona, empaca y exporta — el tenant del sistema |
| **Acopio** | Centro de recepción de fruta en campo (Avoolio tiene 3) |
| **Calibre** | Tamaño del aguacate = piezas por caja de ~11.34 kg (48 grande, 60 chico; menor número = mayor tamaño = más caro) |
| **Corte** | Evento de cosecha en una huerta; la unidad de costeo |
| **Cuadrilla** | Equipo de cortadores (se les paga por kg) |
| **Acarreo** | Flete huerta → empacadora |
| **Desglose de calibres** | Resultado de la seleccionadora: cuántos kg salieron de cada calibre (con esto se prorratea el costo del corte) |
