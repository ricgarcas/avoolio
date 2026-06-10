BEGIN;

CREATE TEMP TABLE contrato (vista text, columna text, tipo text);
INSERT INTO contrato VALUES
-- out_pnl_calibre
('out_pnl_calibre','empacadora_id','uuid'),
('out_pnl_calibre','periodo_id','uuid'),
('out_pnl_calibre','anio','integer'),
('out_pnl_calibre','mes','integer'),
('out_pnl_calibre','calibre','text'),
('out_pnl_calibre','ingresos_usd','numeric'),
('out_pnl_calibre','ingresos_mxn','numeric'),
('out_pnl_calibre','costo_fruta_mxn','numeric'),
('out_pnl_calibre','costo_acarreo_mxn','numeric'),
('out_pnl_calibre','costo_cuadrilla_mxn','numeric'),
('out_pnl_calibre','costo_empaque_mxn','numeric'),
('out_pnl_calibre','costo_fijo_mxn','numeric'),
('out_pnl_calibre','costo_total_mxn','numeric'),
('out_pnl_calibre','margen_bruto_mxn','numeric'),
('out_pnl_calibre','margen_bruto_pct','numeric'),
('out_pnl_calibre','margen_por_kg_mxn','numeric'),
('out_pnl_calibre','volumen_kg','numeric'),
('out_pnl_calibre','cajas_vendidas','bigint'),
-- out_ar_aging
('out_ar_aging','empacadora_id','uuid'),
('out_ar_aging','cxc_id','uuid'),
('out_ar_aging','orden_venta_id','uuid'),
('out_ar_aging','importador_id','uuid'),
('out_ar_aging','monto_usd','numeric'),
('out_ar_aging','saldo_pendiente_usd','numeric'),
('out_ar_aging','fecha_emision','date'),
('out_ar_aging','fecha_vencimiento','date'),
('out_ar_aging','fecha_pago_real','date'),
('out_ar_aging','dias_transcurridos','integer'),
('out_ar_aging','bucket','text'),
('out_ar_aging','estado','text'),
-- out_ap_status
('out_ap_status','empacadora_id','uuid'),
('out_ap_status','cxp_id','uuid'),
('out_ap_status','acuerdo_id','uuid'),
('out_ap_status','corte_id','uuid'),
('out_ap_status','acreedor_tipo','text'),
('out_ap_status','productor_id','uuid'),
('out_ap_status','cuadrilla_id','uuid'),
('out_ap_status','monto_mxn','numeric'),
('out_ap_status','saldo_pendiente_mxn','numeric'),
('out_ap_status','fecha_emision','date'),
('out_ap_status','fecha_vencimiento','date'),
('out_ap_status','estado','text'),
-- out_salud_negocio
('out_salud_negocio','empacadora_id','uuid'),
('out_salud_negocio','periodo_id','uuid'),
('out_salud_negocio','anio','integer'),
('out_salud_negocio','mes','integer'),
('out_salud_negocio','margen_neto_mxn','numeric'),
('out_salud_negocio','margen_neto_pct','numeric'),
('out_salud_negocio','tendencia_margen_pct','numeric'),
('out_salud_negocio','posicion_caja_mxn','numeric'),
('out_salud_negocio','cxc_abierta_usd','numeric'),
('out_salud_negocio','cxc_vencida_usd','numeric'),
('out_salud_negocio','cxp_abierta_mxn','numeric'),
-- out_cfdi_status
('out_cfdi_status','empacadora_id','uuid'),
('out_cfdi_status','orden_venta_id','uuid'),
('out_cfdi_status','factura_cfdi_id','uuid'),
('out_cfdi_status','uuid_fiscal','uuid'),
('out_cfdi_status','serie','character varying'),
('out_cfdi_status','folio','character varying'),
('out_cfdi_status','estatus','text'),
('out_cfdi_status','total_mxn','numeric'),
('out_cfdi_status','total_usd','numeric'),
('out_cfdi_status','fecha_timbrado','timestamp with time zone'),
('out_cfdi_status','xml_url','character varying'),
('out_cfdi_status','pdf_url','character varying'),
-- out_cierre_periodo
('out_cierre_periodo','empacadora_id','uuid'),
('out_cierre_periodo','periodo_id','uuid'),
('out_cierre_periodo','anio','integer'),
('out_cierre_periodo','mes','integer'),
('out_cierre_periodo','estado_periodo','text'),
('out_cierre_periodo','ingresos_mxn','numeric'),
('out_cierre_periodo','ingresos_usd','numeric'),
('out_cierre_periodo','cogs_mxn','numeric'),
('out_cierre_periodo','opex_mxn','numeric'),
('out_cierre_periodo','ajuste_fx_mxn','numeric'),
('out_cierre_periodo','neto_mxn','numeric'),
('out_cierre_periodo','fecha_cierre','timestamp with time zone');

-- Diff exacto contrato ↔ realidad (columnas faltantes, sobrantes o de tipo distinto).
DO $$
DECLARE faltan int; sobran int;
BEGIN
  SELECT count(*) INTO faltan FROM contrato k
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
     WHERE c.table_schema = 'contabilidad' AND c.table_name = k.vista
       AND c.column_name = k.columna AND c.data_type = k.tipo);
  SELECT count(*) INTO sobran FROM information_schema.columns c
  WHERE c.table_schema = 'contabilidad' AND c.table_name LIKE 'out\_%'
    AND NOT EXISTS (
      SELECT 1 FROM contrato k
       WHERE k.vista = c.table_name AND k.columna = c.column_name AND k.tipo = c.data_type);
  IF faltan > 0 OR sobran > 0 THEN
    RAISE EXCEPTION 'FALLO contrato out_*: % columnas faltantes/cambiadas, % sobrantes', faltan, sobran;
  END IF;
END $$;

-- Funcional: bucketing del aging con la CxC vencida del seed local.
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000001';
INSERT INTO contabilidad.cuenta_por_cobrar
  (id, empacadora_id, orden_venta_id, importador_id, monto_usd, monto_mxn, tipo_cambio_factura,
   saldo_pendiente_usd, moneda, fecha_emision, fecha_vencimiento, estado, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000063',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000041',
        '00000000-0000-0000-0000-000000000031',
        2000.00, 37000.00, 18.50, 2000.00, 'USD', '2026-05-01', '2026-05-25', 'pendiente',
        '00000000-0000-0000-0000-000000000012');
DO $$
DECLARE v_bucket text;
BEGIN
  SELECT bucket INTO v_bucket FROM contabilidad.out_ar_aging
   WHERE cxc_id = '00000000-0000-0000-0000-000000000063';
  IF v_bucket <> 'vencida' THEN
    RAISE EXCEPTION 'FALLO aging: bucket=% (esperaba vencida)', v_bucket;
  END IF;
END $$;

-- Tenant scoping: las out_* no regresan filas de otros tenants.
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000002';
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.out_ar_aging;
  IF n <> 0 THEN RAISE EXCEPTION 'FALLO: out_ar_aging fuga % filas de otro tenant', n; END IF;
END $$;

ROLLBACK;
