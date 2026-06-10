BEGIN;
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.tables
  WHERE table_schema = 'contabilidad' AND table_type = 'BASE TABLE';
  IF n <> 10 THEN
    RAISE EXCEPTION 'esperaba 10 tablas en contabilidad, hay %', n;
  END IF;
END $$;
ROLLBACK;
