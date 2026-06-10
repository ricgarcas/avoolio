BEGIN;
DO $$
DECLARE v_before timestamptz; v_after timestamptz;
BEGIN
  SELECT updated_at INTO v_before FROM contabilidad.cuenta_contable
   WHERE id = '00000000-0000-0000-0000-000000000021';
  PERFORM pg_sleep(0.05);
  UPDATE contabilidad.cuenta_contable SET nombre = 'Bancos MXN v2'
   WHERE id = '00000000-0000-0000-0000-000000000021';
  SELECT updated_at INTO v_after FROM contabilidad.cuenta_contable
   WHERE id = '00000000-0000-0000-0000-000000000021';
  IF v_after <= v_before THEN
    RAISE EXCEPTION 'updated_at no se actualizó: % <= %', v_after, v_before;
  END IF;
END $$;
ROLLBACK;
