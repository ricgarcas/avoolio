BEGIN;
-- 1) Existen las 5 vistas y todas son security_invoker.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM pg_class c
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE ns.nspname = 'contabilidad'
     AND c.relkind = 'v'
     AND c.relname LIKE 'in\_%'
     AND c.reloptions @> ARRAY['security_invoker=true'];
  IF n <> 5 THEN
    RAISE EXCEPTION 'FALLO: % vistas in_* con security_invoker (esperaba 5)', n;
  END IF;
END $$;

-- 2) Toda vista in_* expone empacadora_id (la llave de tenant del contrato).
DO $$
DECLARE v record;
BEGIN
  FOR v IN
    SELECT table_name FROM information_schema.views
     WHERE table_schema = 'contabilidad' AND table_name LIKE 'in\_%'
  LOOP
    PERFORM 1 FROM information_schema.columns
     WHERE table_schema = 'contabilidad' AND table_name = v.table_name
       AND column_name = 'empacadora_id';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'FALLO: % no expone empacadora_id', v.table_name;
    END IF;
  END LOOP;
END $$;

-- 3) in_ordenes_venta junta header + líneas (la orden del seed aparece aunque no tenga líneas).
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.in_ordenes_venta
   WHERE orden_venta_id = '00000000-0000-0000-0000-000000000041';
  IF n < 1 THEN RAISE EXCEPTION 'FALLO: in_ordenes_venta no trae la orden del seed'; END IF;
END $$;
ROLLBACK;
