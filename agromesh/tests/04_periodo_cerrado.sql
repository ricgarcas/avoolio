BEGIN;

-- 1) Insertar asiento en periodo cerrado (mayo): rechazado.
DO $$
BEGIN
  BEGIN
    INSERT INTO contabilidad.asiento_contable (empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
    VALUES ('00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000012',  -- mayo, cerrado
            '2026-05-15', 'ajuste_manual', 'borrador', 'asiento en cerrado');
    RAISE EXCEPTION 'FALLO: insertó asiento en periodo cerrado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 2) Mover un asiento existente a un periodo cerrado: rechazado.
INSERT INTO contabilidad.asiento_contable (id, empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
VALUES ('00000000-0000-0000-0000-000000000053',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000011',  -- junio, abierto
        '2026-06-10', 'ajuste_manual', 'borrador', 'test periodo');
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.asiento_contable
       SET periodo_id = '00000000-0000-0000-0000-000000000012'
     WHERE id = '00000000-0000-0000-0000-000000000053';
    RAISE EXCEPTION 'FALLO: movió asiento a periodo cerrado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
