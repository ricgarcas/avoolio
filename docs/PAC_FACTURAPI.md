# PAC propuesto: FacturAPI — evaluación contra requisitos AgroMesh (AGR-45)

**Fecha:** 2026-06-10 · **Issue:** [AGR-45](https://linear.app/agromeshai/issue/AGR-45) (spike CFDI, S3 — propuesta: adelantar a S1/S2) · **Owner:** Ricardo
**Estatus:** evaluación documental completa ✅ · faltan 2 verificaciones en sandbox (abajo)
**Terminología:** ver `docs/GLOSARIO_CONTABLE.md`

## Por qué FacturAPI

- Ricardo ya lo usó en otros proyectos: API REST/JSON moderna, sin SOAP, buen sandbox, buena documentación.
- El riesgo que había que descartar era el **complemento de comercio exterior** (AgroMesh exporta: venta a importadores US = exportación definitiva clave A1). **Confirmado: lo soporta nativo.**

## Checklist de requisitos

| Requisito AgroMesh | FacturAPI | Estado |
|---|---|---|
| CFDI 4.0 ingreso (venta a importador) | Nativo; timbrado directo o borrador; modo `async` | ✅ |
| **Comercio exterior 2.0** (exportación definitiva A1) | Nativo por API: fracción arancelaria (TIGIE), incoterm, TC del DOF automático, NumRegIdTrib del receptor | ✅ **el crítico** |
| Cliente extranjero | `tax_id` extranjero + `tax_system` + `country` (RFC genérico XEXX010101000) | ✅ |
| Multi-moneda USD | `currency` (ISO 4217) + `exchange` (MXN por unidad de divisa) | ✅ |
| PPD — cobranza a 21–25 días | `payment_method: "PPD"` | ✅ |
| **Complemento de pago (REP)** | `type: "P"` + `complements[].type: "pago"` + `related_documents[]` con `uuid`, `amount`, `installment`, `last_balance` — soporta parcialidades | ✅ |
| Cancelación con motivo | Motivos SAT 01–04 + `substitution` (UUID de sustitución); `cancellation_status`: none/pending/accepted/rejected/expired | ✅ |
| Multi-tenant (varias empacadoras) | **Organizations API**: una organización por RFC, llaves test/live separadas por org | ✅ mapea 1:1 con `empacadora_id` |
| Webhooks | Eventos de creación, cambio de estatus y cancelación | ✅ alimentan `out_cfdi_status` |
| Sandbox | Ambiente Test por organización (catálogos test/live separados); trial 14 días | ✅ |
| XML / PDF | Descargables post-timbrado vía API | ✅ |
| Carta Porte (post-MVP) | También soportado | ✅ bonus |

## Mapeo `contabilidad.factura_cfdi` ↔ FacturAPI

| Columna nuestra | Campo FacturAPI (invoice object) | Nota |
|---|---|---|
| `uuid_fiscal` | `uuid` | folio fiscal asignado al timbrar |
| `serie` / `folio` | `series` / `folio_number` | serie se configura por organización |
| `estatus` (vigente/cancelado) | `status` + `cancellation_status` | mapear: accepted → cancelado |
| `tipo_comprobante` | `type` (`I` ingreso / `E` egreso / `P` pago) | |
| `total_mxn` / `total_usd` / `tipo_cambio` | `total` + `currency` + `exchange` | si currency=USD: total_usd=total, total_mxn=total×exchange |
| `metodo_pago` (PUE/PPD) | `payment_method` | |
| `forma_pago` | `payment_form` (catálogo SAT: 03 transferencia…) | |
| `fecha_timbrado` | fecha del timbre en la respuesta | verificar nombre exacto en sandbox |
| `xml_url` / `pdf_url` | endpoints de descarga (`GET /invoices/{id}/xml\|pdf`) | descargamos y guardamos copia propia en storage; las columnas apuntan a NUESTRO storage, no a FacturAPI |
| `uuid_sustitucion` / `motivo_cancelacion` | `substitution` / motivo en la cancelación | |
| `complementos` (JSONB) | `complements[]` del request | guardar el payload del complemento de comercio exterior / pago |

**Arquitectura multi-tenant:** una organización FacturAPI por empacadora (su RFC + sus CSD). La API key live de cada org se guarda cifrada asociada al tenant; los webhooks llegan con el contexto de la org → resolver `empacadora_id`.

## Pendientes de verificar en sandbox (parte del spike)

1. **REP en USD** — la doc del complemento de pago solo muestra ejemplos MXN. El estándar CFDI 4.0 soporta `MonedaP`/`TipoCambioP`, así que casi seguro está; timbrar un REP de prueba en USD para confirmar campos.
2. **Nombre exacto del campo de fecha de timbrado** en la respuesta del invoice object.

## Pregunta de negocio abierta (NO es gap de FacturAPI)

**Compra de fruta a productores:** muchos productores del sector primario no facturan. ¿Cómo se documenta fiscalmente la compra? Opciones: autofactura vía certificación de sector primario (PCGCFDISP), CFDI de egreso, o el productor sí emite factura. **Decisión de Mariano / contador del cliente** — afecta AGR-44, no el timbrado de ventas.

## Precio (para el pitch)

Suscripción API desde ~$299 MXN/mes + timbres como consumible mensual por organización. Trial de 14 días con timbres de prueba. Detalle fino: [facturapi.io/precios](https://www.facturapi.io/precios).

## Plan del spike (cuando se apruebe)

1. Cuenta sandbox + organización de prueba (RFC de pruebas del SAT).
2. Timbrar: CFDI ingreso USD con complemento de comercio exterior (receptor extranjero, fracción arancelaria del aguacate `0804.40.01`, incoterm del pedido).
3. Timbrar su REP en USD (pago parcial + liquidación) → valida pendiente #1.
4. Cancelar con motivo 02 → verificar webhook.
5. Documentar payloads reales junto a este doc y cerrar AGR-45.

## Fuentes

- [Complemento de Comercio Exterior 2.0 — blog FacturAPI](https://www.facturapi.io/en/blog/cexterior-complement)
- [CFDI de Traslado con Comercio Exterior — blog FacturAPI](https://www.facturapi.io/en/blog/cfdi-export-transfer)
- [Documentación FacturAPI](https://docs.facturapi.io/) · [Referencia API](https://docs.facturapi.io/api/)
- [Guía complemento de pago](https://docs.facturapi.io/docs/guides/invoices/pago/)
- [Precios](https://www.facturapi.io/precios)
