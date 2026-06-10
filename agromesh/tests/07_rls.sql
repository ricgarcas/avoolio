BEGIN;
-- Permisos de prueba (superuser los otorga; en Supabase el rol real es authenticated).
GRANT USAGE ON SCHEMA contabilidad TO app_user_test;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA contabilidad TO app_user_test;

SET LOCAL ROLE app_user_test;
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000001';

-- 1) Tenant A solo ve sus cuentas (el seed tiene 4 de A y 1 de B).
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.cuenta_contable;
  IF n <> 4 THEN
    RAISE EXCEPTION 'FALLO RLS: tenant A ve % cuentas (esperaba 4: las suyas)', n;
  END IF;
END $$;

-- 2) Tenant A no puede insertar filas de B.
DO $$
BEGIN
  BEGIN
    INSERT INTO contabilidad.cuenta_contable (empacadora_id, codigo, nombre, tipo, naturaleza, es_hoja, activa)
    VALUES ('00000000-0000-0000-0000-000000000002', '6666', 'Intrusa', 'egreso', 'deudora', TRUE, TRUE);
    RAISE EXCEPTION 'FALLO RLS: insertó en otro tenant';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'FALLO RLS:%' THEN RAISE; END IF;
  WHEN insufficient_privilege OR check_violation THEN
    NULL;  -- esperado: la política WITH CHECK lo rechaza
  END;
END $$;

-- 3) Sin tenant seteado no se ve nada.
SET LOCAL app.empacadora_id = '';
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.cuenta_contable;
  IF n <> 0 THEN
    RAISE EXCEPTION 'FALLO RLS: sin tenant ve % filas', n;
  END IF;
END $$;

ROLLBACK;
