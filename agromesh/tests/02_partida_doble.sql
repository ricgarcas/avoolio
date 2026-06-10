BEGIN;

-- Asiento de trabajo (borrador, periodo abierto de empacadora A).
INSERT INTO contabilidad.asiento_contable (id, empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
VALUES ('00000000-0000-0000-0000-000000000051',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000011',
        '2026-06-10', 'ajuste_manual', 'borrador', 'test partida doble');

-- 1) No se puede insertar un asiento ya confirmado.
DO $$
BEGIN
  BEGIN
    INSERT INTO contabilidad.asiento_contable (empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
    VALUES ('00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000011',
            '2026-06-10', 'ajuste_manual', 'confirmado', 'nace confirmado');
    RAISE EXCEPTION 'FALLO: permitió insertar asiento confirmado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF; -- era nuestro propio assert
  END;
END $$;

-- 2) Asiento vacío no confirma.
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.asiento_contable SET estado = 'confirmado'
     WHERE id = '00000000-0000-0000-0000-000000000051';
    RAISE EXCEPTION 'FALLO: confirmó un asiento sin líneas';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 3) Asiento desbalanceado no confirma.
INSERT INTO contabilidad.linea_asiento (asiento_id, empacadora_id, cuenta_id, debe_mxn, haber_mxn, orden) VALUES
  ('00000000-0000-0000-0000-000000000051', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000021', 100.00, 0, 1),
  ('00000000-0000-0000-0000-000000000051', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000022', 0, 60.00, 2);
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.asiento_contable SET estado = 'confirmado'
     WHERE id = '00000000-0000-0000-0000-000000000051';
    RAISE EXCEPTION 'FALLO: confirmó un asiento desbalanceado (100 vs 60)';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 4) Balanceado sí confirma.
UPDATE contabilidad.linea_asiento SET haber_mxn = 100.00
 WHERE asiento_id = '00000000-0000-0000-0000-000000000051' AND haber_mxn = 60.00;
UPDATE contabilidad.asiento_contable SET estado = 'confirmado'
 WHERE id = '00000000-0000-0000-0000-000000000051';
DO $$
DECLARE v contabilidad.asiento_estado;
BEGIN
  SELECT estado INTO v FROM contabilidad.asiento_contable
   WHERE id = '00000000-0000-0000-0000-000000000051';
  IF v <> 'confirmado' THEN RAISE EXCEPTION 'FALLO: no quedó confirmado (%)', v; END IF;
END $$;

ROLLBACK;
