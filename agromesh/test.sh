#!/usr/bin/env bash
# Harness de tests del schema contabilidad.
# Uso: ./test.sh                 -> corre toda la suite
#      ./test.sh tests/03_*.sql  -> corre solo esos archivos
# Requiere el PostgreSQL local de Herd corriendo (127.0.0.1:5432, user root).
# Crea una base efímera agromesh_test y la dropea al salir.
set -euo pipefail
cd "$(dirname "$0")"

PSQL_BIN="${PSQL_BIN:-$HOME/Library/Application Support/Herd/bin/psql}"
command -v "$PSQL_BIN" >/dev/null || PSQL_BIN=psql
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-root}"
TESTDB=agromesh_test

psql_admin() { "$PSQL_BIN" -d postgres -v ON_ERROR_STOP=1 -q "$@"; }
psql_test()  { "$PSQL_BIN" -d "$TESTDB" -v ON_ERROR_STOP=1 -q "$@"; }

cleanup() { psql_admin -c "DROP DATABASE IF EXISTS $TESTDB WITH (FORCE)" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

echo "→ Creando base efímera ${TESTDB}…"
psql_admin -c "CREATE DATABASE $TESTDB" >/dev/null

echo "→ Aplicando fixtures + migración…"
psql_test -f fixtures/00_roles.sql >/dev/null
psql_test -f fixtures/10_operational_schema.sql >/dev/null
psql_test -f migrations/0001_contabilidad.sql >/dev/null
psql_test -f fixtures/20_test_seed.sql >/dev/null

FILES=("${@:-}")
if [ -z "${FILES[0]:-}" ]; then FILES=(tests/*.sql); fi

PASS=0; FAIL=0
for f in "${FILES[@]}"; do
  if psql_test -f "$f" >/dev/null 2>/tmp/agromesh-test-err.txt; then
    echo "  PASS $f"; PASS=$((PASS+1))
  else
    echo "  FAIL $f"; sed 's/^/       /' /tmp/agromesh-test-err.txt; FAIL=$((FAIL+1))
  fi
done

echo "→ $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
