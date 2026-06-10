# AGR-13 — Schema `contabilidad`: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Una migración SQL que crea el schema `contabilidad` completo (enums, 10 tablas, triggers de invariantes, RLS, vistas `in_*`/`out_*`, GRANTs) + suite de tests SQL de aserción, según `docs/superpowers/specs/2026-06-10-accounting-data-model-design.md`.

**Architecture:** El DDL base se vendorea del modelo de referencia del blueprint (`accounting_schema.sql`) y se transforma al schema `contabilidad`; encima se agregan las 5 invariantes como triggers, RLS por tenant vía `contabilidad.current_empacadora()`, 5 vistas de entrada `security_invoker` y 6 vistas de output que filtran por tenant. Los tests corren contra un Postgres 17 efímero en Docker: se aplica el schema operacional del blueprint (prerequisito), luego la migración, luego cada test en una transacción con ROLLBACK.

**Tech Stack:** PostgreSQL 17 (Docker `postgres:17-alpine`), psql, bash. Sin dependencias de Node/npm.

**Convenciones del plan:**
- Todo vive bajo `agromesh/` en la raíz del repo — **separado de `supabase/migrations/`**, que pertenece al CRM AvoOlio (otro proyecto Supabase). Esta migración se aplicará al Supabase compartido de AgroMesh cuando Abisai cierre AGR-7.
- La migración es UN solo archivo (`0001_contabilidad.sql`) que crece tarea por tarea. No está aplicada en ningún ambiente real, así que editarla (no crear 0002, 0003…) es correcto hasta el primer deploy.
- Cada test es un `.sql` independiente: abre `BEGIN;`, hace asserts con bloques `DO`, cierra `ROLLBACK;`. Un assert que truena aborta el archivo y el harness lo reporta como FAIL.
- Docker debe estar corriendo (`open -a Docker` si está apagado).

**Estructura de archivos final:**

```
agromesh/
├── README.md                      # nota de boundary para Abisai (Task 12)
├── test.sh                        # harness (Task 1)
├── fixtures/
│   ├── 00_roles.sql               # roles supabase-like para el Postgres efímero
│   ├── 10_operational_schema.sql  # copia vendoreada de blueprint schema.sql
│   └── 20_test_seed.sql           # seed mínimo con UUIDs fijos para tests
├── migrations/
│   └── 0001_contabilidad.sql      # LA migración (crece en Tasks 2–11)
└── tests/
    ├── 00_smoke.sql
    ├── 01_updated_at.sql
    ├── 02_partida_doble.sql
    ├── 03_inmutabilidad.sql
    ├── 04_periodo_cerrado.sql
    ├── 05_cuentas_hoja.sql
    ├── 06_pagos_saldos.sql
    ├── 07_rls.sql
    ├── 08_vistas_in.sql
    └── 09_contrato_outputs.sql
```

---

### Task 1: Scaffolding, fixtures y harness

**Files:**
- Create: `agromesh/test.sh`
- Create: `agromesh/fixtures/00_roles.sql`
- Create: `agromesh/fixtures/10_operational_schema.sql` (copia)
- Create: `agromesh/fixtures/20_test_seed.sql`
- Create: `agromesh/tests/00_smoke.sql`

- [ ] **Step 1: Crear directorios y vendorear el schema operacional**

```bash
cd "/Volumes/VELLENT USB/Sites/avoolio"
mkdir -p agromesh/fixtures agromesh/migrations agromesh/tests
# El clone del blueprint vive en /tmp; si no existe, re-clonar:
[ -d /tmp/agromesh-blueprint ] || git clone https://github.com/agromesh/blueprint.git /tmp/agromesh-blueprint
cp /tmp/agromesh-blueprint/10_data_model/schema.sql agromesh/fixtures/10_operational_schema.sql
```

- [ ] **Step 2: Crear `agromesh/fixtures/00_roles.sql`**

Roles que existen en Supabase pero no en un Postgres vanilla. Idempotente para poder re-correr.

```sql
-- Roles supabase-like para el ambiente de test (en Supabase ya existen).
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
```

- [ ] **Step 3: Crear `agromesh/fixtures/20_test_seed.sql`**

Seed mínimo con UUIDs fijos (se aplica una vez después de la migración; los tests lo asumen presente). Solo tablas operacionales + catálogo contable mínimo.

```sql
-- Seed de test con UUIDs fijos. Convención:
--   ...0001/0002 empacadoras · ...001x periodos · ...002x cuentas
--   ...003x actores · ...004x ordenes
INSERT INTO public.empacadora (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Empacadora A (test)'),
  ('00000000-0000-0000-0000-000000000002', 'Empacadora B (test)');

INSERT INTO public.importador (id, nombre_empresa) VALUES
  ('00000000-0000-0000-0000-000000000031', 'Importador Test LLC');

INSERT INTO public.productor (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000032', 'Productor Test');

INSERT INTO public.cuadrilla (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000033', 'Cuadrilla Test');

INSERT INTO public.orden_venta (id, empacadora_id, importador_id, total_usd, fecha_entrega_real) VALUES
  ('00000000-0000-0000-0000-000000000041',
   '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000031',
   10000.00, '2026-06-01');

-- Periodos para empacadora A: junio abierto, mayo cerrado.
INSERT INTO contabilidad.periodo_contable (id, empacadora_id, anio, mes, fecha_inicio, fecha_fin, estado) VALUES
  ('00000000-0000-0000-0000-000000000011',
   '00000000-0000-0000-0000-000000000001', 2026, 6, '2026-06-01', '2026-06-30', 'abierto'),
  ('00000000-0000-0000-0000-000000000012',
   '00000000-0000-0000-0000-000000000001', 2026, 5, '2026-05-01', '2026-05-31', 'cerrado');

-- Catálogo mínimo para A: grupo (no hoja), dos hojas activas, una hoja inactiva.
INSERT INTO contabilidad.cuenta_contable (id, empacadora_id, codigo, nombre, tipo, naturaleza, cuenta_padre_id, es_hoja, activa) VALUES
  ('00000000-0000-0000-0000-000000000020',
   '00000000-0000-0000-0000-000000000001', '1000', 'Activo', 'activo', 'deudora', NULL, FALSE, TRUE),
  ('00000000-0000-0000-0000-000000000021',
   '00000000-0000-0000-0000-000000000001', '1100', 'Bancos MXN', 'activo', 'deudora',
   '00000000-0000-0000-0000-000000000020', TRUE, TRUE),
  ('00000000-0000-0000-0000-000000000022',
   '00000000-0000-0000-0000-000000000001', '4100', 'Venta Export USD', 'ingreso', 'acreedora', NULL, TRUE, TRUE),
  ('00000000-0000-0000-0000-000000000023',
   '00000000-0000-0000-0000-000000000001', '5999', 'Cuenta Inactiva', 'egreso', 'deudora', NULL, TRUE, FALSE);

-- Una fila contable por tenant para los tests de RLS.
INSERT INTO contabilidad.cuenta_contable (id, empacadora_id, codigo, nombre, tipo, naturaleza, es_hoja, activa) VALUES
  ('00000000-0000-0000-0000-000000000024',
   '00000000-0000-0000-0000-000000000002', '1100', 'Bancos MXN (B)', 'activo', 'deudora', TRUE, TRUE);
```

- [ ] **Step 4: Crear `agromesh/test.sh`** (ejecutable)

```bash
#!/usr/bin/env bash
# Harness de tests del schema contabilidad.
# Uso: ./test.sh                 -> corre toda la suite
#      ./test.sh tests/03_*.sql  -> corre solo esos archivos
# Requiere Docker corriendo.
set -euo pipefail
cd "$(dirname "$0")"

CONTAINER=agromesh-contabilidad-test
PSQL="docker exec -i $CONTAINER psql -U postgres -v ON_ERROR_STOP=1 -q"

cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

echo "→ Levantando postgres:17-alpine…"
docker run -d --name "$CONTAINER" -e POSTGRES_PASSWORD=postgres postgres:17-alpine >/dev/null
until docker exec "$CONTAINER" pg_isready -U postgres -q 2>/dev/null; do sleep 0.5; done

echo "→ Aplicando fixtures + migración…"
$PSQL -f - < fixtures/00_roles.sql
$PSQL -f - < fixtures/10_operational_schema.sql
$PSQL -f - < migrations/0001_contabilidad.sql
$PSQL -f - < fixtures/20_test_seed.sql

FILES=("${@:-}")
if [ -z "${FILES[0]:-}" ]; then FILES=(tests/*.sql); fi

PASS=0; FAIL=0
for f in "${FILES[@]}"; do
  if $PSQL -f - < "$f" >/dev/null 2>/tmp/agromesh-test-err.txt; then
    echo "  PASS $f"; PASS=$((PASS+1))
  else
    echo "  FAIL $f"; sed 's/^/       /' /tmp/agromesh-test-err.txt; FAIL=$((FAIL+1))
  fi
done

echo "→ $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
```

```bash
chmod +x agromesh/test.sh
```

- [ ] **Step 5: Escribir el smoke test `agromesh/tests/00_smoke.sql` (falla primero)**

```sql
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
```

- [ ] **Step 6: Correr el harness y verificar que falla por la razón correcta**

Crear primero una migración vacía para que el harness llegue a los tests:

```bash
echo "-- AGR-13 · schema contabilidad (se construye en tasks 2-11)" > agromesh/migrations/0001_contabilidad.sql
./agromesh/test.sh
```

Expected: `FAIL tests/00_smoke.sql` con "esperaba 10 tablas en contabilidad, hay 0". Si Docker está apagado: `open -a Docker`, esperar, reintentar.

- [ ] **Step 7: Commit**

```bash
git add agromesh/
git commit -m "test: AGR-13 harness + fixtures + smoke test (red)"
```

---

### Task 2: DDL base — enums, 10 tablas, índices en schema `contabilidad`

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (reemplazar contenido)

- [ ] **Step 1: Generar el DDL base desde la referencia vendoreada**

```bash
cp /tmp/agromesh-blueprint/10_data_model/accounting/accounting_schema.sql /tmp/contabilidad_base.sql
```

Editar `/tmp/contabilidad_base.sql`:

1. **Eliminar el bloque del materialized view completo**: desde la línea `-- MATERIALIZED VIEW — Resultado_Calibre (per-calibre P&L)` (incluyendo su banner de `====`) hasta `CREATE UNIQUE INDEX idx_resultado_calibre_emp_cal ON resultado_calibre (empacadora_id, calibre);` inclusive. Se reemplaza por `out_pnl_calibre` en Task 10.

2. **Verificar que no quede ninguna referencia a `resultado_calibre`**: `grep -n resultado_calibre /tmp/contabilidad_base.sql` debe regresar vacío.

- [ ] **Step 2: Armar `agromesh/migrations/0001_contabilidad.sql`**

El archivo final = header siguiente + contenido completo de `/tmp/contabilidad_base.sql`:

```sql
-- =====================================================================
-- AGR-13 · Schema contabilidad — AgroMesh accounting module
-- Owner: Ricardo (contractor boundary). Contrato vinculante:
--   blueprint/30_integrations/ACCOUNTING_REQUIREMENTS.md
-- Spec: docs/superpowers/specs/2026-06-10-accounting-data-model-design.md
-- PREREQUISITO: blueprint schema.sql aplicado en el mismo database (public).
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS contabilidad;

-- Todo lo que sigue (tipos, tablas, índices, funciones, vistas) se crea en
-- `contabilidad`; las FKs a tablas operacionales resuelven a `public`.
SET search_path = contabilidad, public;

-- <<< AQUÍ va el contenido íntegro de /tmp/contabilidad_base.sql >>>
```

Comando para ensamblarlo:

```bash
cat > agromesh/migrations/0001_contabilidad.sql <<'HEADER'
-- =====================================================================
-- AGR-13 · Schema contabilidad — AgroMesh accounting module
-- Owner: Ricardo (contractor boundary). Contrato vinculante:
--   blueprint/30_integrations/ACCOUNTING_REQUIREMENTS.md
-- Spec: docs/superpowers/specs/2026-06-10-accounting-data-model-design.md
-- PREREQUISITO: blueprint schema.sql aplicado en el mismo database (public).
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS contabilidad;

SET search_path = contabilidad, public;

HEADER
cat /tmp/contabilidad_base.sql >> agromesh/migrations/0001_contabilidad.sql
```

- [ ] **Step 3: Agregar CHECKs de integridad al final de la migración**

Append al final del archivo:

```sql
-- =====================================================================
-- CHECKs adicionales (no estaban en la referencia)
-- =====================================================================
-- Una línea es debe XOR haber (en MXN, la moneda del trial balance).
ALTER TABLE contabilidad.linea_asiento
  ADD CONSTRAINT chk_linea_un_lado CHECK (
    (COALESCE(debe_mxn, 0) > 0 AND COALESCE(haber_mxn, 0) = 0) OR
    (COALESCE(haber_mxn, 0) > 0 AND COALESCE(debe_mxn, 0) = 0)
  );

-- Un pago aplica a exactamente un documento, consistente con aplicado_a.
ALTER TABLE contabilidad.pago
  ADD CONSTRAINT chk_pago_destino CHECK (
    (aplicado_a = 'cxc' AND cxc_id IS NOT NULL AND cxp_id IS NULL) OR
    (aplicado_a = 'cxp' AND cxp_id IS NOT NULL AND cxc_id IS NULL)
  );

-- Un periodo por (tenant, año, mes).
ALTER TABLE contabilidad.periodo_contable
  ADD CONSTRAINT uq_periodo_tenant_mes UNIQUE (empacadora_id, anio, mes);
```

Nota: si la referencia ya trae el UNIQUE de periodo (`grep -n "UNIQUE" agromesh/migrations/0001_contabilidad.sql`), omitir ese tercer ALTER.

- [ ] **Step 4: Correr el smoke test**

```bash
./agromesh/test.sh agromesh/tests/00_smoke.sql 2>/dev/null || ./agromesh/test.sh tests/00_smoke.sql
```

Expected: `PASS tests/00_smoke.sql` (el harness corre desde `agromesh/`, los paths de tests son relativos a ese dir).

- [ ] **Step 5: Commit**

```bash
git add agromesh/migrations/0001_contabilidad.sql
git commit -m "feat: AGR-13 DDL base del schema contabilidad (enums, 10 tablas, indices, checks)"
```

---

### Task 3: Trigger `updated_at`

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/01_updated_at.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/01_updated_at.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
cd agromesh && ./test.sh tests/01_updated_at.sql
```

Expected: FAIL ("updated_at no se actualizó").

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — updated_at
-- =====================================================================
CREATE FUNCTION contabilidad.set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'config_contable','periodo_contable','cuenta_contable','asiento_contable',
    'costo_operativo','cuenta_por_cobrar','cuenta_por_pagar','pago','factura_cfdi'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON contabilidad.%I
       FOR EACH ROW EXECUTE FUNCTION contabilidad.set_updated_at()', t, t);
  END LOOP;
END $$;
```

(`linea_asiento` no lleva trigger: solo tiene `created_at`.)

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/01_updated_at.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 trigger updated_at en tablas contables"
```

---

### Task 4: Ciclo de vida del asiento — nace en borrador, confirma solo balanceado

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/02_partida_doble.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/02_partida_doble.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/02_partida_doble.sql
```

Expected: FAIL en el assert 1 ("permitió insertar asiento confirmado").

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — ciclo de vida del asiento (partida doble)
-- =====================================================================
-- Los asientos nacen en borrador; las líneas se insertan después.
CREATE FUNCTION contabilidad.asiento_nace_borrador() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.estado <> 'borrador' THEN
    RAISE EXCEPTION 'los asientos nacen en borrador (recibí %)', NEW.estado;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_nace_borrador
  BEFORE INSERT ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.asiento_nace_borrador();

-- Confirmar exige: tiene líneas y Σdebe = Σhaber (en MXN, moneda del trial balance).
CREATE FUNCTION contabilidad.check_asiento_balanceado() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_debe numeric; v_haber numeric;
BEGIN
  SELECT COALESCE(SUM(debe_mxn), 0), COALESCE(SUM(haber_mxn), 0)
    INTO v_debe, v_haber
    FROM contabilidad.linea_asiento WHERE asiento_id = NEW.id;
  IF v_debe = 0 AND v_haber = 0 THEN
    RAISE EXCEPTION 'asiento % sin líneas no puede confirmarse', NEW.id;
  END IF;
  IF v_debe IS DISTINCT FROM v_haber THEN
    RAISE EXCEPTION 'asiento desbalanceado: debe=% haber=%', v_debe, v_haber;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_balanceado
  BEFORE UPDATE OF estado ON contabilidad.asiento_contable
  FOR EACH ROW
  WHEN (OLD.estado = 'borrador' AND NEW.estado = 'confirmado')
  EXECUTE FUNCTION contabilidad.check_asiento_balanceado();
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/02_partida_doble.sql tests/00_smoke.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 partida doble forzada por trigger (nace borrador, confirma balanceado)"
```

---

### Task 5: Inmutabilidad del journal

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/03_inmutabilidad.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/03_inmutabilidad.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/03_inmutabilidad.sql
```

Expected: FAIL en assert 1 ("editó un asiento confirmado").

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — inmutabilidad del journal
-- =====================================================================
-- Confirmado: solo se permite la transición a revertido sin tocar nada más.
-- Revertido: intocable. Borrador: libre. Corrección = asiento de reversa
-- nuevo apuntando asiento_revertido_id al original.
CREATE FUNCTION contabilidad.bloquear_asiento_inmutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.estado <> 'borrador' THEN
      RAISE EXCEPTION 'asiento % es inmutable (estado %): usa un asiento de reversa', OLD.id, OLD.estado;
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.estado = 'revertido' THEN
    RAISE EXCEPTION 'asiento % está revertido y es inmutable', OLD.id;
  END IF;

  IF OLD.estado = 'confirmado' THEN
    IF NOT (NEW.estado = 'revertido'
            AND (to_jsonb(NEW) - 'estado' - 'updated_at')
              = (to_jsonb(OLD) - 'estado' - 'updated_at')) THEN
      RAISE EXCEPTION 'asiento % confirmado es inmutable: usa un asiento de reversa', OLD.id;
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_inmutable
  BEFORE UPDATE OR DELETE ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.bloquear_asiento_inmutable();

-- Las líneas solo se tocan mientras el asiento está en borrador.
CREATE FUNCTION contabilidad.bloquear_lineas_confirmadas() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_estado contabilidad.asiento_estado;
BEGIN
  SELECT estado INTO v_estado FROM contabilidad.asiento_contable
   WHERE id = COALESCE(NEW.asiento_id, OLD.asiento_id);
  IF v_estado <> 'borrador' THEN
    RAISE EXCEPTION 'las líneas del asiento % son inmutables (estado %)',
      COALESCE(NEW.asiento_id, OLD.asiento_id), v_estado;
  END IF;
  RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_lineas_inmutables
  BEFORE INSERT OR UPDATE OR DELETE ON contabilidad.linea_asiento
  FOR EACH ROW EXECUTE FUNCTION contabilidad.bloquear_lineas_confirmadas();
```

**Ojo (ordering de triggers):** los triggers BEFORE del mismo evento disparan en orden alfabético. `trg_asiento_balanceado` < `trg_asiento_inmutable` < `trg_asiento_nace_borrador` — el balance check corre antes que el de inmutabilidad en el UPDATE de confirmación; la transición borrador→confirmado pasa el check de inmutabilidad (OLD.estado='borrador' es libre). Correcto tal cual.

- [ ] **Step 4: Correr y verificar PASS (incluyendo que Task 4 no se rompió)**

```bash
./test.sh tests/02_partida_doble.sql tests/03_inmutabilidad.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 inmutabilidad fisica del journal (asientos y lineas)"
```

---

### Task 6: Candado de periodo cerrado

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/04_periodo_cerrado.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/04_periodo_cerrado.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/04_periodo_cerrado.sql
```

Expected: FAIL en assert 1.

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — candado de periodo cerrado
-- =====================================================================
CREATE FUNCTION contabilidad.check_periodo_abierto() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_estado contabilidad.periodo_estado; v_anio int; v_mes int;
BEGIN
  SELECT estado, anio, mes INTO v_estado, v_anio, v_mes
    FROM contabilidad.periodo_contable WHERE id = NEW.periodo_id;
  IF v_estado = 'cerrado' THEN
    RAISE EXCEPTION 'periodo %-% está cerrado: no admite asientos', v_anio, lpad(v_mes::text, 2, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_asiento_periodo_abierto
  BEFORE INSERT OR UPDATE OF periodo_id ON contabilidad.asiento_contable
  FOR EACH ROW EXECUTE FUNCTION contabilidad.check_periodo_abierto();
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/04_periodo_cerrado.sql tests/03_inmutabilidad.sql tests/02_partida_doble.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 candado de periodo cerrado"
```

---

### Task 7: Solo cuentas hoja activas postean

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/05_cuentas_hoja.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/05_cuentas_hoja.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/05_cuentas_hoja.sql
```

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — solo cuentas hoja activas reciben líneas
-- =====================================================================
CREATE FUNCTION contabilidad.check_cuenta_posteable() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_hoja boolean; v_activa boolean; v_codigo text;
BEGIN
  SELECT es_hoja, activa, codigo INTO v_hoja, v_activa, v_codigo
    FROM contabilidad.cuenta_contable WHERE id = NEW.cuenta_id;
  IF NOT v_hoja OR NOT v_activa THEN
    RAISE EXCEPTION 'cuenta % no es posteable (es_hoja=%, activa=%)', v_codigo, v_hoja, v_activa;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_linea_cuenta_posteable
  BEFORE INSERT OR UPDATE OF cuenta_id ON contabilidad.linea_asiento
  FOR EACH ROW EXECUTE FUNCTION contabilidad.check_cuenta_posteable();
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/05_cuentas_hoja.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 solo cuentas hoja activas postean"
```

---

### Task 8: Pagos mantienen `saldo_pendiente` y `estado` sin drift

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/06_pagos_saldos.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/06_pagos_saldos.sql`:

```sql
BEGIN;

-- CxC de 1000 USD sobre la orden de venta del seed.
INSERT INTO contabilidad.cuenta_por_cobrar
  (id, empacadora_id, orden_venta_id, importador_id, monto_usd, saldo_pendiente_usd,
   moneda, fecha_emision, fecha_vencimiento, estado)
VALUES ('00000000-0000-0000-0000-000000000061',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000041',
        '00000000-0000-0000-0000-000000000031',
        1000.00, 1000.00, 'USD', '2026-06-01', '2026-06-25', 'pendiente');

-- Pago parcial de 400 → saldo 600, estado parcial.
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxc_id, monto_usd, moneda, tipo_cambio, fecha_pago, metodo)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxc',
        '00000000-0000-0000-0000-000000000061', 400.00, 'USD', 18.50, '2026-06-10', 'transferencia');
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
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxc_id, monto_usd, moneda, tipo_cambio, fecha_pago, metodo)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxc',
        '00000000-0000-0000-0000-000000000061', 600.00, 'USD', 18.70, '2026-06-12', 'transferencia');
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
   moneda, fecha_emision, fecha_vencimiento, estado)
VALUES ('00000000-0000-0000-0000-000000000062',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000032',
        5000.00, 5000.00, 'MXN', '2026-06-01', '2026-06-15', 'pendiente');
INSERT INTO contabilidad.pago (empacadora_id, aplicado_a, cxp_id, monto_mxn, moneda, fecha_pago, metodo)
VALUES ('00000000-0000-0000-0000-000000000001', 'cxp',
        '00000000-0000-0000-0000-000000000062', 5000.00, 'MXN', '2026-06-10', 'transferencia');
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/06_pagos_saldos.sql
```

Expected: FAIL ("FALLO pago parcial: saldo=1000.00 estado=pendiente").

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- TRIGGERS — pagos recalculan saldo y estado (sin drift)
-- =====================================================================
CREATE FUNCTION contabilidad.aplicar_pago() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE v_cxc uuid; v_cxp uuid;
BEGIN
  v_cxc := COALESCE(NEW.cxc_id, OLD.cxc_id);
  v_cxp := COALESCE(NEW.cxp_id, OLD.cxp_id);

  IF v_cxc IS NOT NULL THEN
    UPDATE contabilidad.cuenta_por_cobrar c SET
      saldo_pendiente_usd = c.monto_usd - pagado.total,
      estado = CASE
        WHEN c.estado = 'cancelada' THEN c.estado
        WHEN pagado.total >= c.monto_usd THEN 'pagada'::contabilidad.cxc_estado
        WHEN pagado.total > 0 THEN 'parcial'::contabilidad.cxc_estado
        ELSE 'pendiente'::contabilidad.cxc_estado
      END,
      fecha_pago_real = CASE WHEN pagado.total >= c.monto_usd THEN pagado.ultima ELSE NULL END
    FROM (
      SELECT COALESCE(SUM(p.monto_usd), 0) AS total, MAX(p.fecha_pago) AS ultima
        FROM contabilidad.pago p WHERE p.cxc_id = v_cxc
    ) pagado
    WHERE c.id = v_cxc;
  END IF;

  IF v_cxp IS NOT NULL THEN
    UPDATE contabilidad.cuenta_por_pagar c SET
      saldo_pendiente_mxn = c.monto_mxn - pagado.total,
      estado = CASE
        WHEN c.estado = 'cancelada' THEN c.estado
        WHEN pagado.total >= c.monto_mxn THEN 'pagada'::contabilidad.cxp_estado
        WHEN pagado.total > 0 THEN 'parcial'::contabilidad.cxp_estado
        ELSE 'pendiente'::contabilidad.cxp_estado
      END,
      fecha_pago_real = CASE WHEN pagado.total >= c.monto_mxn THEN pagado.ultima ELSE NULL END
    FROM (
      SELECT COALESCE(SUM(p.monto_mxn), 0) AS total, MAX(p.fecha_pago) AS ultima
        FROM contabilidad.pago p WHERE p.cxp_id = v_cxp
    ) pagado
    WHERE c.id = v_cxp;
  END IF;

  RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_pago_aplica
  AFTER INSERT OR UPDATE OR DELETE ON contabilidad.pago
  FOR EACH ROW EXECUTE FUNCTION contabilidad.aplicar_pago();
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/06_pagos_saldos.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 pagos recalculan saldo_pendiente y estado via trigger"
```

---

### Task 9: RLS por tenant + `current_empacadora()`

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/07_rls.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/07_rls.sql`:

```sql
BEGIN;
-- Permisos de prueba (superuser los otorga; en Supabase el rol real es authenticated).
GRANT USAGE ON SCHEMA contabilidad TO app_user_test;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA contabilidad TO app_user_test;

SET LOCAL ROLE app_user_test;
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000001';

-- 1) Tenant A solo ve sus cuentas (el seed tiene 5 de A y 1 de B).
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.cuenta_contable;
  IF n <> 5 THEN
    RAISE EXCEPTION 'FALLO RLS: tenant A ve % cuentas (esperaba 5: las suyas)', n;
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/07_rls.sql
```

Expected: FAIL en assert 1 (sin RLS, A ve las 6 cuentas).

- [ ] **Step 3: Implementar — append a la migración**

```sql
-- =====================================================================
-- RLS — aislamiento por tenant
-- =====================================================================
-- El tenant actual se resuelve vía esta función. HOY lee el setting
-- app.empacadora_id; cuando AGR-8 defina el modelo usuario/JWT en Supabase,
-- SOLO se cambia el cuerpo de esta función (las políticas no se tocan):
--   p.ej. (current_setting('request.jwt.claims', true)::jsonb ->> 'empacadora_id')::uuid
CREATE FUNCTION contabilidad.current_empacadora() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.empacadora_id', true), '')::uuid
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'config_contable','periodo_contable','cuenta_contable','asiento_contable',
    'linea_asiento','costo_operativo','cuenta_por_cobrar','cuenta_por_pagar',
    'pago','factura_cfdi'
  ] LOOP
    EXECUTE format('ALTER TABLE contabilidad.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON contabilidad.%I
         USING (empacadora_id = contabilidad.current_empacadora())
         WITH CHECK (empacadora_id = contabilidad.current_empacadora())', t);
  END LOOP;
END $$;
```

- [ ] **Step 4: Correr y verificar PASS + suite completa**

```bash
./test.sh
```

Expected: todos PASS. **Ojo:** si los tests 01–06 fallan ahora es porque corren como superuser del contenedor (que bypasea RLS por ser owner — los superusers no son afectados por RLS salvo FORCE). No usamos `FORCE ROW LEVEL SECURITY` precisamente para que el owner (jobs internos del módulo) opere cross-tenant.

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 RLS por tenant via current_empacadora()"
```

---

### Task 10: Vistas de entrada `in_*` (security_invoker)

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/08_vistas_in.sql`

- [ ] **Step 1: Escribir el test (falla primero)**

`agromesh/tests/08_vistas_in.sql`:

```sql
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
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/08_vistas_in.sql
```

- [ ] **Step 3: Implementar — append a la migración**

Nota clave del modelo operacional: `corte` y `resultado_seleccion` **no tienen `empacadora_id`** — se resuelve vía join a `acuerdo_compra_venta`.

```sql
-- =====================================================================
-- VISTAS DE ENTRADA in_* — lectura del modelo operacional (public)
-- security_invoker: el RLS de las tablas base aplica al consultante.
-- =====================================================================
CREATE VIEW contabilidad.in_acuerdos WITH (security_invoker = true) AS
SELECT a.id, a.empacadora_id, a.productor_id, a.huerta_id,
       a.precio_por_kg, a.volumen_acordado_ton, a.estado,
       a.fecha_corte_programada, a.created_at, a.updated_at
  FROM public.acuerdo_compra_venta a;

CREATE VIEW contabilidad.in_cortes WITH (security_invoker = true) AS
SELECT c.id, a.empacadora_id, c.acuerdo_id, c.huerta_id, c.cuadrilla_id,
       c.acopio_id, c.fecha, c.volumen_cortado_ton, c.costo_cuadrilla_por_kg,
       c.estado, c.created_at, c.updated_at
  FROM public.corte c
  JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id;

CREATE VIEW contabilidad.in_resultados_seleccion WITH (security_invoker = true) AS
SELECT rs.id, a.empacadora_id, rs.corte_id, rs.volumen_total_kg,
       rs.pct_exportacion_real, rs.pct_nacional_real,
       rs.desglose_calibre, rs.desglose_calidad, rs.fecha_proceso, rs.created_at
  FROM public.resultado_seleccion rs
  JOIN public.corte c ON c.id = rs.corte_id
  JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id;

CREATE VIEW contabilidad.in_ordenes_venta WITH (security_invoker = true) AS
SELECT ov.id AS orden_venta_id, ov.empacadora_id, ov.importador_id,
       ov.estado, ov.total_usd, ov.condiciones_pago, ov.incoterm,
       ov.fecha_orden, ov.fecha_entrega_real,
       lo.id AS linea_id, lo.calibre, lo.calidad, lo.cantidad_cajas,
       lo.precio_caja_usd, lo.corte_origen_id
  FROM public.orden_venta ov
  LEFT JOIN public.linea_orden_venta lo ON lo.orden_id = ov.id;

CREATE VIEW contabilidad.in_embarques WITH (security_invoker = true) AS
SELECT e.id, e.empacadora_id, e.orden_venta_id, e.fecha_salida,
       e.fecha_llegada_est, e.fecha_llegada_real, e.total_cajas,
       e.estado, e.created_at, e.updated_at
  FROM public.embarque e;
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/08_vistas_in.sql
```

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 vistas de entrada in_* con security_invoker"
```

---

### Task 11: Vistas de output `out_*` — el contrato

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Test: `agromesh/tests/09_contrato_outputs.sql`

- [ ] **Step 1: Escribir el test de contrato (falla primero)**

El test fija **nombre y tipo de cada columna** de las 6 vistas. Si una migración futura rompe el contrato, este test truena antes que el dashboard de Abisai.

`agromesh/tests/09_contrato_outputs.sql`:

```sql
BEGIN;

CREATE TEMP TABLE contrato (vista text, columna text, tipo text);
INSERT INTO contrato VALUES
-- out_pnl_calibre
('out_pnl_calibre','empacadora_id','uuid'),
('out_pnl_calibre','periodo_id','uuid'),
('out_pnl_calibre','anio','integer'),
('out_pnl_calibre','mes','integer'),
('out_pnl_calibre','calibre','text'),
('out_pnl_calibre','ingresos_usd','numeric'),
('out_pnl_calibre','ingresos_mxn','numeric'),
('out_pnl_calibre','costo_fruta_mxn','numeric'),
('out_pnl_calibre','costo_acarreo_mxn','numeric'),
('out_pnl_calibre','costo_cuadrilla_mxn','numeric'),
('out_pnl_calibre','costo_empaque_mxn','numeric'),
('out_pnl_calibre','costo_fijo_mxn','numeric'),
('out_pnl_calibre','costo_total_mxn','numeric'),
('out_pnl_calibre','margen_bruto_mxn','numeric'),
('out_pnl_calibre','margen_bruto_pct','numeric'),
('out_pnl_calibre','margen_por_kg_mxn','numeric'),
('out_pnl_calibre','volumen_kg','numeric'),
('out_pnl_calibre','cajas_vendidas','bigint'),
-- out_ar_aging
('out_ar_aging','empacadora_id','uuid'),
('out_ar_aging','cxc_id','uuid'),
('out_ar_aging','orden_venta_id','uuid'),
('out_ar_aging','importador_id','uuid'),
('out_ar_aging','monto_usd','numeric'),
('out_ar_aging','saldo_pendiente_usd','numeric'),
('out_ar_aging','fecha_emision','date'),
('out_ar_aging','fecha_vencimiento','date'),
('out_ar_aging','fecha_pago_real','date'),
('out_ar_aging','dias_transcurridos','integer'),
('out_ar_aging','bucket','text'),
('out_ar_aging','estado','text'),
-- out_ap_status
('out_ap_status','empacadora_id','uuid'),
('out_ap_status','cxp_id','uuid'),
('out_ap_status','acuerdo_id','uuid'),
('out_ap_status','corte_id','uuid'),
('out_ap_status','acreedor_tipo','text'),
('out_ap_status','productor_id','uuid'),
('out_ap_status','cuadrilla_id','uuid'),
('out_ap_status','monto_mxn','numeric'),
('out_ap_status','saldo_pendiente_mxn','numeric'),
('out_ap_status','fecha_emision','date'),
('out_ap_status','fecha_vencimiento','date'),
('out_ap_status','estado','text'),
-- out_salud_negocio
('out_salud_negocio','empacadora_id','uuid'),
('out_salud_negocio','periodo_id','uuid'),
('out_salud_negocio','anio','integer'),
('out_salud_negocio','mes','integer'),
('out_salud_negocio','margen_neto_mxn','numeric'),
('out_salud_negocio','margen_neto_pct','numeric'),
('out_salud_negocio','tendencia_margen_pct','numeric'),
('out_salud_negocio','posicion_caja_mxn','numeric'),
('out_salud_negocio','cxc_abierta_usd','numeric'),
('out_salud_negocio','cxc_vencida_usd','numeric'),
('out_salud_negocio','cxp_abierta_mxn','numeric'),
-- out_cfdi_status
('out_cfdi_status','empacadora_id','uuid'),
('out_cfdi_status','orden_venta_id','uuid'),
('out_cfdi_status','factura_cfdi_id','uuid'),
('out_cfdi_status','uuid_fiscal','uuid'),
('out_cfdi_status','serie','character varying'),
('out_cfdi_status','folio','character varying'),
('out_cfdi_status','estatus','text'),
('out_cfdi_status','total_mxn','numeric'),
('out_cfdi_status','total_usd','numeric'),
('out_cfdi_status','fecha_timbrado','timestamp with time zone'),
('out_cfdi_status','xml_url','character varying'),
('out_cfdi_status','pdf_url','character varying'),
-- out_cierre_periodo
('out_cierre_periodo','empacadora_id','uuid'),
('out_cierre_periodo','periodo_id','uuid'),
('out_cierre_periodo','anio','integer'),
('out_cierre_periodo','mes','integer'),
('out_cierre_periodo','estado_periodo','text'),
('out_cierre_periodo','ingresos_mxn','numeric'),
('out_cierre_periodo','ingresos_usd','numeric'),
('out_cierre_periodo','cogs_mxn','numeric'),
('out_cierre_periodo','opex_mxn','numeric'),
('out_cierre_periodo','ajuste_fx_mxn','numeric'),
('out_cierre_periodo','neto_mxn','numeric'),
('out_cierre_periodo','fecha_cierre','timestamp with time zone');

-- Diff exacto contrato ↔ realidad (columnas faltantes, sobrantes o de tipo distinto).
DO $$
DECLARE faltan int; sobran int;
BEGIN
  SELECT count(*) INTO faltan FROM contrato k
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
     WHERE c.table_schema = 'contabilidad' AND c.table_name = k.vista
       AND c.column_name = k.columna AND c.data_type = k.tipo);
  SELECT count(*) INTO sobran FROM information_schema.columns c
  WHERE c.table_schema = 'contabilidad' AND c.table_name LIKE 'out\_%'
    AND NOT EXISTS (
      SELECT 1 FROM contrato k
       WHERE k.vista = c.table_name AND k.columna = c.column_name AND k.tipo = c.data_type);
  IF faltan > 0 OR sobran > 0 THEN
    RAISE EXCEPTION 'FALLO contrato out_*: % columnas faltantes/cambiadas, % sobrantes', faltan, sobran;
  END IF;
END $$;

-- Funcional: bucketing del aging con la CxC vencida del seed local.
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000001';
INSERT INTO contabilidad.cuenta_por_cobrar
  (id, empacadora_id, orden_venta_id, importador_id, monto_usd, saldo_pendiente_usd,
   moneda, fecha_emision, fecha_vencimiento, estado)
VALUES ('00000000-0000-0000-0000-000000000063',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000041',
        '00000000-0000-0000-0000-000000000031',
        2000.00, 2000.00, 'USD', '2026-05-01', '2026-05-25', 'pendiente');
DO $$
DECLARE v_bucket text;
BEGIN
  SELECT bucket INTO v_bucket FROM contabilidad.out_ar_aging
   WHERE cxc_id = '00000000-0000-0000-0000-000000000063';
  IF v_bucket <> 'vencida' THEN
    RAISE EXCEPTION 'FALLO aging: bucket=% (esperaba vencida)', v_bucket;
  END IF;
END $$;

-- Tenant scoping: las out_* no regresan filas de otros tenants.
SET LOCAL app.empacadora_id = '00000000-0000-0000-0000-000000000002';
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM contabilidad.out_ar_aging;
  IF n <> 0 THEN RAISE EXCEPTION 'FALLO: out_ar_aging fuga % filas de otro tenant', n; END IF;
END $$;

ROLLBACK;
```

- [ ] **Step 2: Correr y verificar FAIL**

```bash
./test.sh tests/09_contrato_outputs.sql
```

- [ ] **Step 3: Implementar — append a la migración**

Todas las `out_*` filtran por `contabilidad.current_empacadora()`: son owner-security (los consumidores no necesitan permisos sobre las tablas internas) pero **siempre tenant-scoped**.

```sql
-- =====================================================================
-- VISTAS DE OUTPUT out_* — EL CONTRATO con AgroMesh
-- (ACCOUNTING_REQUIREMENTS.md §"HARD DATA — what AgroMesh NEEDS BACK")
-- Owner-security + filtro por current_empacadora(): tenant-scoped siempre.
-- Cambiar columnas aquí = romper el contrato -> coordinar con Abisai.
-- =====================================================================

-- P&L por calibre · consume: Admin Inicio (4 widgets)
CREATE VIEW contabilidad.out_pnl_calibre AS
WITH vol AS (
  -- kg por (corte, calibre) desde el JSONB de la seleccionadora,
  -- con el share del calibre dentro del corte para prorratear costos.
  SELECT a.empacadora_id, c.id AS corte_id, rs.fecha_proceso::date AS fecha,
         kv.key AS calibre,
         (kv.value #>> '{}')::numeric AS kg,
         SUM((kv.value #>> '{}')::numeric) OVER (PARTITION BY c.id) AS kg_corte
    FROM public.resultado_seleccion rs
    JOIN public.corte c ON c.id = rs.corte_id
    JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id
   CROSS JOIN LATERAL jsonb_each(rs.desglose_calibre) kv
),
costos_corte AS (
  SELECT co.corte_id,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'acarreo')            AS acarreo,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'corte_cuadrilla')    AS cuadrilla,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'empaque_materiales') AS empaque,
         SUM(co.monto_mxn) FILTER (WHERE co.tipo_costo = 'costo_fijo_empaque') AS fijo
    FROM contabilidad.costo_operativo co
   WHERE co.corte_id IS NOT NULL
   GROUP BY co.corte_id
),
fruta_corte AS (
  SELECT c.id AS corte_id,
         (a.precio_por_kg * c.volumen_cortado_ton * 1000)::numeric AS costo_fruta
    FROM public.corte c
    JOIN public.acuerdo_compra_venta a ON a.id = c.acuerdo_id
),
costos_calibre AS (
  -- prorrateo por share de kg del calibre dentro del corte
  SELECT v.empacadora_id, v.fecha, v.calibre,
         SUM(v.kg) AS volumen_kg,
         SUM(COALESCE(fc.costo_fruta, 0) * v.kg / NULLIF(v.kg_corte, 0)) AS costo_fruta_mxn,
         SUM(COALESCE(cc.acarreo, 0)     * v.kg / NULLIF(v.kg_corte, 0)) AS costo_acarreo_mxn,
         SUM(COALESCE(cc.cuadrilla, 0)   * v.kg / NULLIF(v.kg_corte, 0)) AS costo_cuadrilla_mxn,
         SUM(COALESCE(cc.empaque, 0)     * v.kg / NULLIF(v.kg_corte, 0)) AS costo_empaque_mxn,
         SUM(COALESCE(cc.fijo, 0)        * v.kg / NULLIF(v.kg_corte, 0)) AS costo_fijo_mxn
    FROM vol v
    LEFT JOIN costos_corte cc ON cc.corte_id = v.corte_id
    LEFT JOIN fruta_corte fc  ON fc.corte_id = v.corte_id
   GROUP BY v.empacadora_id, v.fecha, v.calibre
),
ingresos AS (
  SELECT ov.empacadora_id,
         COALESCE(ov.fecha_entrega_real, ov.fecha_orden::date) AS fecha,
         lo.calibre,
         SUM(lo.cantidad_cajas * lo.precio_caja_usd) AS ingresos_usd,
         SUM(lo.cantidad_cajas)                      AS cajas_vendidas
    FROM public.linea_orden_venta lo
    JOIN public.orden_venta ov ON ov.id = lo.orden_id
   WHERE lo.calibre IS NOT NULL
   GROUP BY 1, 2, 3
),
fx_periodo AS (
  -- TC promedio del periodo desde las CxC facturadas; fallback al TC ref del tenant.
  SELECT cxc.empacadora_id, p.id AS periodo_id, AVG(cxc.tipo_cambio_factura) AS tc
    FROM contabilidad.cuenta_por_cobrar cxc
    JOIN contabilidad.periodo_contable p
      ON p.empacadora_id = cxc.empacadora_id
     AND cxc.fecha_emision BETWEEN p.fecha_inicio AND p.fecha_fin
   GROUP BY 1, 2
)
SELECT p.empacadora_id,
       p.id                                            AS periodo_id,
       p.anio, p.mes,
       COALESCE(i.calibre, cx.calibre)::text           AS calibre,
       COALESCE(i.ingresos_usd, 0)::numeric            AS ingresos_usd,
       (COALESCE(i.ingresos_usd, 0)
         * COALESCE(fx.tc, e.tipo_cambio_ref, 0))::numeric AS ingresos_mxn,
       COALESCE(cx.costo_fruta_mxn, 0)::numeric        AS costo_fruta_mxn,
       COALESCE(cx.costo_acarreo_mxn, 0)::numeric      AS costo_acarreo_mxn,
       COALESCE(cx.costo_cuadrilla_mxn, 0)::numeric    AS costo_cuadrilla_mxn,
       COALESCE(cx.costo_empaque_mxn, 0)::numeric      AS costo_empaque_mxn,
       COALESCE(cx.costo_fijo_mxn, 0)::numeric         AS costo_fijo_mxn,
       (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
        + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
        + COALESCE(cx.costo_fijo_mxn,0))::numeric      AS costo_total_mxn,
       (COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
        - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
           + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
           + COALESCE(cx.costo_fijo_mxn,0)))::numeric  AS margen_bruto_mxn,
       CASE WHEN COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0) > 0
            THEN ((COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
                   - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
                      + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
                      + COALESCE(cx.costo_fijo_mxn,0)))
                  / (COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)) * 100)
       END::numeric                                    AS margen_bruto_pct,
       CASE WHEN COALESCE(cx.volumen_kg, 0) > 0
            THEN ((COALESCE(i.ingresos_usd,0) * COALESCE(fx.tc, e.tipo_cambio_ref, 0)
                   - (COALESCE(cx.costo_fruta_mxn,0) + COALESCE(cx.costo_acarreo_mxn,0)
                      + COALESCE(cx.costo_cuadrilla_mxn,0) + COALESCE(cx.costo_empaque_mxn,0)
                      + COALESCE(cx.costo_fijo_mxn,0))) / cx.volumen_kg)
       END::numeric                                    AS margen_por_kg_mxn,
       COALESCE(cx.volumen_kg, 0)::numeric             AS volumen_kg,
       COALESCE(i.cajas_vendidas, 0)::bigint           AS cajas_vendidas
  FROM contabilidad.periodo_contable p
  JOIN public.empacadora e ON e.id = p.empacadora_id
  LEFT JOIN ingresos i
    ON i.empacadora_id = p.empacadora_id
   AND i.fecha BETWEEN p.fecha_inicio AND p.fecha_fin
  LEFT JOIN costos_calibre cx
    ON cx.empacadora_id = p.empacadora_id
   AND cx.fecha BETWEEN p.fecha_inicio AND p.fecha_fin
   AND cx.calibre = i.calibre
  LEFT JOIN fx_periodo fx
    ON fx.empacadora_id = p.empacadora_id AND fx.periodo_id = p.id
 WHERE p.empacadora_id = contabilidad.current_empacadora()
   AND COALESCE(i.calibre, cx.calibre) IS NOT NULL;

-- AR aging · consume: Ventas Embarques + Admin
CREATE VIEW contabilidad.out_ar_aging AS
SELECT cxc.empacadora_id,
       cxc.id              AS cxc_id,
       cxc.orden_venta_id,
       cxc.importador_id,
       cxc.monto_usd,
       cxc.saldo_pendiente_usd,
       cxc.fecha_emision,
       cxc.fecha_vencimiento,
       cxc.fecha_pago_real,
       (current_date - cxc.fecha_emision)::int AS dias_transcurridos,
       CASE
         WHEN cxc.estado IN ('pagada', 'cancelada')          THEN cxc.estado::text
         WHEN current_date >  cxc.fecha_vencimiento          THEN 'vencida'
         WHEN current_date >= cxc.fecha_vencimiento - 4      THEN 'por_vencer_21_25'
         ELSE 'corriente'
       END::text AS bucket,
       cxc.estado::text AS estado
  FROM contabilidad.cuenta_por_cobrar cxc
 WHERE cxc.empacadora_id = contabilidad.current_empacadora();

-- AP status · consume: Admin (cash planning)
CREATE VIEW contabilidad.out_ap_status AS
SELECT cxp.empacadora_id,
       cxp.id AS cxp_id,
       cxp.acuerdo_id,
       cxp.corte_id,
       CASE WHEN cxp.productor_id IS NOT NULL THEN 'productor' ELSE 'cuadrilla' END::text AS acreedor_tipo,
       cxp.productor_id,
       cxp.cuadrilla_id,
       cxp.monto_mxn,
       cxp.saldo_pendiente_mxn,
       cxp.fecha_emision,
       cxp.fecha_vencimiento,
       cxp.estado::text AS estado
  FROM contabilidad.cuenta_por_pagar cxp
 WHERE cxp.empacadora_id = contabilidad.current_empacadora();

-- Salud del negocio · consume: Owner hero metric
CREATE VIEW contabilidad.out_salud_negocio AS
WITH resultado AS (
  SELECT p.empacadora_id, p.id AS periodo_id, p.anio, p.mes,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN la.haber_mxn - la.debe_mxn ELSE 0 END) AS ingresos,
         SUM(CASE WHEN cu.tipo = 'egreso'  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS egresos
    FROM contabilidad.periodo_contable p
    LEFT JOIN contabilidad.asiento_contable a
      ON a.periodo_id = p.id AND a.estado = 'confirmado'
    LEFT JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    LEFT JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id
   GROUP BY 1, 2, 3, 4
),
caja AS (
  -- saldo acumulado de cuentas de bancos (códigos 11xx) hasta el fin de cada periodo
  SELECT p.id AS periodo_id,
         SUM(la.debe_mxn - la.haber_mxn) AS saldo
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.asiento_contable a
      ON a.empacadora_id = p.empacadora_id AND a.estado = 'confirmado'
     AND a.fecha <= p.fecha_fin
    JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id AND cu.codigo LIKE '11%'
   GROUP BY 1
),
exposicion AS (
  SELECT p.id AS periodo_id,
         SUM(cxc.saldo_pendiente_usd) FILTER (WHERE cxc.estado IN ('pendiente','parcial')) AS cxc_abierta,
         SUM(cxc.saldo_pendiente_usd) FILTER (
           WHERE cxc.estado IN ('pendiente','parcial') AND cxc.fecha_vencimiento < current_date) AS cxc_vencida
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.cuenta_por_cobrar cxc
      ON cxc.empacadora_id = p.empacadora_id
     AND cxc.fecha_emision <= p.fecha_fin
   GROUP BY 1
),
deuda AS (
  SELECT p.id AS periodo_id,
         SUM(cxp.saldo_pendiente_mxn) FILTER (WHERE cxp.estado IN ('pendiente','parcial')) AS cxp_abierta
    FROM contabilidad.periodo_contable p
    JOIN contabilidad.cuenta_por_pagar cxp
      ON cxp.empacadora_id = p.empacadora_id
     AND cxp.fecha_emision <= p.fecha_fin
   GROUP BY 1
)
SELECT r.empacadora_id, r.periodo_id, r.anio, r.mes,
       (r.ingresos - r.egresos)::numeric AS margen_neto_mxn,
       CASE WHEN r.ingresos > 0
            THEN ((r.ingresos - r.egresos) / r.ingresos * 100) END::numeric AS margen_neto_pct,
       (CASE WHEN r.ingresos > 0 THEN (r.ingresos - r.egresos) / r.ingresos * 100 END
        - LAG(CASE WHEN r.ingresos > 0 THEN (r.ingresos - r.egresos) / r.ingresos * 100 END)
          OVER (PARTITION BY r.empacadora_id ORDER BY r.anio, r.mes))::numeric AS tendencia_margen_pct,
       COALESCE(c.saldo, 0)::numeric        AS posicion_caja_mxn,
       COALESCE(x.cxc_abierta, 0)::numeric  AS cxc_abierta_usd,
       COALESCE(x.cxc_vencida, 0)::numeric  AS cxc_vencida_usd,
       COALESCE(d.cxp_abierta, 0)::numeric  AS cxp_abierta_mxn
  FROM resultado r
  LEFT JOIN caja c       ON c.periodo_id = r.periodo_id
  LEFT JOIN exposicion x ON x.periodo_id = r.periodo_id
  LEFT JOIN deuda d      ON d.periodo_id = r.periodo_id
 WHERE r.empacadora_id = contabilidad.current_empacadora();

-- CFDI status por orden · consume: Ventas Pedidos
CREATE VIEW contabilidad.out_cfdi_status AS
SELECT ov.empacadora_id,
       ov.id AS orden_venta_id,
       f.id  AS factura_cfdi_id,
       f.uuid_fiscal,
       f.serie,
       f.folio,
       COALESCE(f.estatus::text, 'sin_facturar') AS estatus,
       f.total_mxn,
       f.total_usd,
       f.fecha_timbrado,
       f.xml_url,
       f.pdf_url
  FROM public.orden_venta ov
  LEFT JOIN contabilidad.factura_cfdi f
    ON f.orden_venta_id = ov.id AND f.tipo_comprobante = 'ingreso'
 WHERE ov.empacadora_id = contabilidad.current_empacadora();

-- Cierre de periodo · consume: Admin + Owner ("monthly truth")
CREATE VIEW contabilidad.out_cierre_periodo AS
WITH agregado AS (
  SELECT p.empacadora_id, p.id AS periodo_id, p.anio, p.mes,
         p.estado::text AS estado_periodo, p.fecha_cierre,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN la.haber_mxn - la.debe_mxn ELSE 0 END) AS ingresos_mxn,
         SUM(CASE WHEN cu.tipo = 'ingreso' THEN COALESCE(la.haber_usd,0) - COALESCE(la.debe_usd,0) ELSE 0 END) AS ingresos_usd,
         SUM(CASE WHEN cu.tipo = 'egreso' AND a.tipo IN ('compra_fruta','costo_operativo')
                  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS cogs_mxn,
         SUM(CASE WHEN cu.tipo = 'egreso' AND a.tipo NOT IN ('compra_fruta','costo_operativo','ajuste_fx')
                  THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS opex_mxn,
         SUM(CASE WHEN a.tipo = 'ajuste_fx' THEN la.debe_mxn - la.haber_mxn ELSE 0 END) AS ajuste_fx_mxn
    FROM contabilidad.periodo_contable p
    LEFT JOIN contabilidad.asiento_contable a
      ON a.periodo_id = p.id AND a.estado = 'confirmado'
    LEFT JOIN contabilidad.linea_asiento la ON la.asiento_id = a.id
    LEFT JOIN contabilidad.cuenta_contable cu ON cu.id = la.cuenta_id
   GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT empacadora_id, periodo_id, anio, mes, estado_periodo,
       ingresos_mxn::numeric, ingresos_usd::numeric, cogs_mxn::numeric, opex_mxn::numeric,
       ajuste_fx_mxn::numeric,
       (ingresos_mxn - cogs_mxn - opex_mxn - ajuste_fx_mxn)::numeric AS neto_mxn,
       fecha_cierre
  FROM agregado
 WHERE empacadora_id = contabilidad.current_empacadora();
```

- [ ] **Step 4: Correr y verificar PASS**

```bash
./test.sh tests/09_contrato_outputs.sql
```

Si el test de contrato truena por tipos: ajustar el cast en la vista (no el contrato del test) hasta que coincida. El contrato del test es la verdad.

- [ ] **Step 5: Commit**

```bash
git add -A agromesh && git commit -m "feat: AGR-13 las 6 vistas de output del contrato (out_*)"
```

---

### Task 12: GRANTs, README de boundary, suite completa

**Files:**
- Modify: `agromesh/migrations/0001_contabilidad.sql` (append)
- Create: `agromesh/README.md`

- [ ] **Step 1: Append GRANTs al final de la migración**

```sql
-- =====================================================================
-- GRANTS — lo único que AgroMesh ve del schema contabilidad
-- =====================================================================
GRANT USAGE ON SCHEMA contabilidad TO authenticated, service_role;
GRANT SELECT ON contabilidad.out_pnl_calibre,
                contabilidad.out_ar_aging,
                contabilidad.out_ap_status,
                contabilidad.out_salud_negocio,
                contabilidad.out_cfdi_status,
                contabilidad.out_cierre_periodo
  TO authenticated, service_role;
-- Las tablas internas y las vistas in_* NO se exponen a los roles de la app.
```

- [ ] **Step 2: Crear `agromesh/README.md`** (nota de boundary para Abisai)

```markdown
# Módulo de contabilidad AgroMesh — boundary

Schema `contabilidad` en el Supabase compartido. Owner: Ricardo (AGR-13).
Spec: `docs/superpowers/specs/2026-06-10-accounting-data-model-design.md`.
Contrato: `blueprint/30_integrations/ACCOUNTING_REQUIREMENTS.md`.

## Para Abisai (plataforma)

1. **Prerequisito:** `blueprint/10_data_model/schema.sql` aplicado en `public` (AGR-7).
2. Aplicar `migrations/0001_contabilidad.sql`.
3. Exponer el schema `contabilidad` en la API (Dashboard → Settings → API → Exposed schemas).
4. Consumir **solo las vistas `out_*`** (GRANT SELECT ya incluido para
   `authenticated`/`service_role`). Las tablas internas y las `in_*` no son parte del contrato.
5. Las `out_*` filtran por `contabilidad.current_empacadora()`, que hoy lee
   `current_setting('app.empacadora_id')`. Cuando AGR-8 defina el claim de tenant
   en el JWT, se cambia **solo el cuerpo de esa función** — avisar a Ricardo.

## Las 6 vistas del contrato

| Vista | Consume | Granularidad |
|---|---|---|
| `out_pnl_calibre` | Admin Inicio (4 widgets) | empacadora + periodo + calibre |
| `out_ar_aging` | Ventas Embarques + Admin | empacadora + orden + importador |
| `out_ap_status` | Admin | empacadora + acuerdo/corte + acreedor |
| `out_salud_negocio` | Owner | empacadora + periodo |
| `out_cfdi_status` | Ventas Pedidos | empacadora + orden_venta |
| `out_cierre_periodo` | Admin + Owner | empacadora + periodo |

Las columnas exactas están fijadas por test: `tests/09_contrato_outputs.sql`.
Cambiar una columna = romper el contrato = coordinar antes.

## Tests

`./test.sh` (requiere Docker). Postgres 17 efímero: aplica el schema operacional
del blueprint + la migración + seed, corre los 10 archivos de `tests/`.
```

- [ ] **Step 3: Correr la suite completa**

```bash
./agromesh/test.sh
```

Expected: `10 pass, 0 fail`.

- [ ] **Step 4: Commit final**

```bash
git add -A agromesh
git commit -m "feat: AGR-13 grants del boundary + README para plataforma"
```

- [ ] **Step 5: Actualizar Linear**

Mover AGR-13 a "In Progress" al arrancar la ejecución (si no se hizo) y al terminar dejar comentario con: link al spec, resumen del boundary (schema + 6 out_*), y qué necesita de Abisai (exponer schema, aplicar migración tras AGR-7, claim de tenant de AGR-8). Usar las tools de Linear MCP (`save_issue` para estado, `save_comment` para el comentario).

---

## Self-review del plan (ya aplicado)

- **Cobertura del spec:** §2 boundary → Tasks 2/10/11/12 · §3 las 5 adaptaciones → Tasks 4–8 (+ CHECKs en Task 2) · §4 contrato de columnas → Task 11 (test 09 fija nombre+tipo) · §6 testing (los 6 puntos del spec) → tests 02–09 · §7 entregables → migración (2–11), tests (1–11), README (12).
- **Sin placeholders:** todo el SQL está completo en el plan; el único "copiar de" es el DDL de referencia vendoreado, que es un archivo real con path exacto.
- **Consistencia de tipos:** nombres de triggers/funciones (`contabilidad.current_empacadora`, `trg_asiento_*`) usados consistentemente entre tasks; UUIDs fijos del seed (…0001–…0063) referenciados idénticos en todos los tests.
- **Nota consciente:** el spec §4 dice `out_ar_aging` granularidad "por orden + importador"; la vista emite una fila por CxC (que es 1:1 con orden en V1) e incluye `cxc_id` para desambiguar si en el futuro una orden se factura en partes. No contradice el contrato; el test fija las columnas.
