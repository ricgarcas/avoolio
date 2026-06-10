BEGIN;

-- CxC de 1000 USD sobre la orden de venta del seed.
INSERT INTO contabilidad.cuenta_por_cobrar
  (id, empacadora_id, orden_venta_id, importador_id, monto_usd, monto_mxn, tipo_cambio_factura,
   saldo_pendiente_usd, moneda, fecha_emision, fecha_vencimiento, estado, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000061',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000041',
        '00000000-0000-0000-0000-000000000031',
        1000.00, 18500.00, 18.50, 1000.00, 'USD', '2026-06-01', '2026-06-25', 'pendiente',
        '00000000-0000-0000-0000-000000000011');

-- Pago parcial de 400 → saldo 600, estado parcial.
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxc_id, monto_usd, moneda, tipo_cambio, fecha_pago, metodo, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxc',
        '00000000-0000-0000-0000-000000000061', 400.00, 'USD', 18.50, '2026-06-10', 'transferencia',
        '00000000-0000-0000-0000-000000000011');
DO $$
DECLARE v_saldo numeric; v_estado contabilidad.cxc_estado;
BEGIN
  SELECT saldo_pendiente_usd, estado INTO v_saldo, v_estado
    FROM contabilidad.cuenta_por_cobrar WHERE id = '00000000-0000-0000-0000-000000000061';
  IF v_saldo <> 600.00 OR v_estado <> 'parcial' THEN
    RAISE EXCEPTION 'FALLO pago parcial: saldo=% estado=%', v_saldo, v_estado;
  END IF;
END $$;

-- Pago del resto → saldo 0, estado pagada, fecha_pago_real seteada.
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxc_id, monto_usd, moneda, tipo_cambio, fecha_pago, metodo, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxc',
        '00000000-0000-0000-0000-000000000061', 600.00, 'USD', 18.70, '2026-06-12', 'transferencia',
        '00000000-0000-0000-0000-000000000011');
DO $$
DECLARE v_saldo numeric; v_estado contabilidad.cxc_estado; v_fecha date;
BEGIN
  SELECT saldo_pendiente_usd, estado, fecha_pago_real INTO v_saldo, v_estado, v_fecha
    FROM contabilidad.cuenta_por_cobrar WHERE id = '00000000-0000-0000-0000-000000000061';
  IF v_saldo <> 0 OR v_estado <> 'pagada' OR v_fecha <> '2026-06-12' THEN
    RAISE EXCEPTION 'FALLO pago total: saldo=% estado=% fecha=%', v_saldo, v_estado, v_fecha;
  END IF;
END $$;

-- Borrar un pago restaura el saldo (corrección antes de confirmar el asiento).
DELETE FROM contabilidad.pago
 WHERE cxc_id = '00000000-0000-0000-0000-000000000061' AND monto_usd = 600.00;
DO $$
DECLARE v_saldo numeric; v_estado contabilidad.cxc_estado;
BEGIN
  SELECT saldo_pendiente_usd, estado INTO v_saldo, v_estado
    FROM contabilidad.cuenta_por_cobrar WHERE id = '00000000-0000-0000-0000-000000000061';
  IF v_saldo <> 600.00 OR v_estado <> 'parcial' THEN
    RAISE EXCEPTION 'FALLO al borrar pago: saldo=% estado=%', v_saldo, v_estado;
  END IF;
END $$;

-- Mismo mecanismo del lado CxP (MXN, acreedor productor, sin acuerdo).
INSERT INTO contabilidad.cuenta_por_pagar
  (id, empacadora_id, productor_id, monto_mxn, saldo_pendiente_mxn,
   moneda, fecha_emision, fecha_vencimiento, estado, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000062',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000032',
        5000.00, 5000.00, 'MXN', '2026-06-01', '2026-06-15', 'pendiente',
        '00000000-0000-0000-0000-000000000011');
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxp_id, monto_mxn, moneda, fecha_pago, metodo, periodo_id)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxp',
        '00000000-0000-0000-0000-000000000062', 5000.00, 'MXN', '2026-06-10', 'transferencia',
        '00000000-0000-0000-0000-000000000011');
DO $$
DECLARE v_saldo numeric; v_estado contabilidad.cxp_estado;
BEGIN
  SELECT saldo_pendiente_mxn, estado INTO v_saldo, v_estado
    FROM contabilidad.cuenta_por_pagar WHERE id = '00000000-0000-0000-0000-000000000062';
  IF v_saldo <> 0 OR v_estado <> 'pagada' THEN
    RAISE EXCEPTION 'FALLO cxp: saldo=% estado=%', v_saldo, v_estado;
  END IF;
END $$;

ROLLBACK;
