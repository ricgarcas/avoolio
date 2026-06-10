BEGIN;

-- Fixture local: asiento balanceado y confirmado.
INSERT INTO contabilidad.asiento_contable (id, empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
VALUES ('00000000-0000-0000-0000-000000000052',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000011',
        '2026-06-10', 'ajuste_manual', 'borrador', 'test inmutabilidad');
INSERT INTO contabilidad.linea_asiento (asiento_id, empacadora_id, cuenta_id, debe_mxn, haber_mxn, orden) VALUES
  ('00000000-0000-0000-0000-000000000052', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000021', 50.00, 0, 1),
  ('00000000-0000-0000-0000-000000000052', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000022', 0, 50.00, 2);
UPDATE contabilidad.asiento_contable SET estado = 'confirmado'
 WHERE id = '00000000-0000-0000-0000-000000000052';

-- 1) UPDATE de un campo cualquiera sobre confirmado: rechazado.
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.asiento_contable SET descripcion = 'hackeado'
     WHERE id = '00000000-0000-0000-0000-000000000052';
    RAISE EXCEPTION 'FALLO: editó un asiento confirmado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 2) DELETE sobre confirmado: rechazado.
DO $$
BEGIN
  BEGIN
    DELETE FROM contabilidad.asiento_contable
     WHERE id = '00000000-0000-0000-0000-000000000052';
    RAISE EXCEPTION 'FALLO: borró un asiento confirmado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 3) Las líneas de un confirmado también son inmutables.
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.linea_asiento SET debe_mxn = 999
     WHERE asiento_id = '00000000-0000-0000-0000-000000000052' AND debe_mxn > 0;
    RAISE EXCEPTION 'FALLO: editó líneas de un asiento confirmado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 4) La única transición permitida: confirmado → revertido (solo estado).
UPDATE contabilidad.asiento_contable SET estado = 'revertido'
 WHERE id = '00000000-0000-0000-0000-000000000052';
DO $$
DECLARE v contabilidad.asiento_estado;
BEGIN
  SELECT estado INTO v FROM contabilidad.asiento_contable
   WHERE id = '00000000-0000-0000-0000-000000000052';
  IF v <> 'revertido' THEN RAISE EXCEPTION 'FALLO: no permitió revertir (%)', v; END IF;
END $$;

-- 5) Un revertido ya no se toca.
DO $$
BEGIN
  BEGIN
    UPDATE contabilidad.asiento_contable SET estado = 'borrador'
     WHERE id = '00000000-0000-0000-0000-000000000052';
    RAISE EXCEPTION 'FALLO: resucitó un asiento revertido';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

ROLLBACK;
