-- Roles supabase-like para el ambiente de test (en Supabase ya existen).
-- Se crean a nivel cluster: idempotente, NOLOGIN, inofensivos en el Postgres local.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN BYPASSRLS;
  END IF;
  -- Rol de prueba para verificar RLS (no existe en Supabase; solo tests).
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user_test') THEN
    CREATE ROLE app_user_test NOLOGIN;
  END IF;
END $$;
