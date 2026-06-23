#!/usr/bin/env bash
# Aplica todas las migraciones de AvoOlio a una DB Postgres.
# Uso:
#   ./db/apply-all.sh                                      # default: avoolio local
#   PGHOST=... PGUSER=... DB=avoolio ./db/apply-all.sh     # otro target (Railway, etc.)
set -euo pipefail
DB="${DB:-avoolio}"
PGHOST="${PGHOST:-127.0.0.1}"
PGUSER="${PGUSER:-root}"
PGPORT="${PGPORT:-5432}"

echo "→ Aplicando migraciones a ${PGUSER}@${PGHOST}:${PGPORT}/${DB}"
for f in db/migrations/*.sql; do
  echo "  ▸ $(basename "$f")"
  psql -h "$PGHOST" -U "$PGUSER" -p "$PGPORT" -d "$DB" -v ON_ERROR_STOP=1 -f "$f" >/dev/null
done
echo "✓ Listo"
