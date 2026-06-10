BEGIN;

INSERT INTO contabilidad.asiento_contable (id, empacadora_id, periodo_id, fecha, tipo, estado, descripcion)
VALUES ('00000000-0000-0000-0000-000000000054',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000011',
        '2026-06-10', 'ajuste_manual', 'borrador', 'test hojas');

-- 1) Cuenta de grupo (es_hoja = false): rechazada.
DO $$
BEGIN
  BEGIN
    INSERT INTO contabilidad.linea_asiento (asiento_id, empacadora_id, cuenta_id, debe_mxn, haber_mxn, orden)
    VALUES ('00000000-0000-0000-0000-000000000054', '00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000020', 10.00, 0, 1);  -- 1000 Activo, grupo
    RAISE EXCEPTION 'FALLO: posteó a una cuenta de grupo';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 2) Cuenta inactiva: rechazada.
DO $$
BEGIN
  BEGIN
    INSERT INTO contabilidad.linea_asiento (asiento_id, empacadora_id, cuenta_id, debe_mxn, haber_mxn, orden)
    VALUES ('00000000-0000-0000-0000-000000000054', '00000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000023', 10.00, 0, 1);  -- 5999, inactiva
    RAISE EXCEPTION 'FALLO: posteó a una cuenta inactiva';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;

-- 3) Hoja activa: aceptada.
INSERT INTO contabilidad.linea_asiento (asiento_id, empacadora_id, cuenta_id, debe_mxn, haber_mxn, orden)
VALUES ('00000000-0000-0000-0000-000000000054', '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000021', 10.00, 0, 1);

ROLLBACK;
