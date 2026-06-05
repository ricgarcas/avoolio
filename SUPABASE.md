# Acceso a Supabase — AvoOlio

**Project ref:** `sfkhmlaaohidmotdnmlh`
**URL:** https://sfkhmlaaohidmotdnmlh.supabase.co

Las credenciales viven en `.env.local` (gitignored). Estado actual: proyecto
**nuevo**, el schema `public` aún no tiene tablas.

---

## 1. REST helper (forma actual, read-only)

Sin dependencias, usa la secret key y solo hace GETs vía PostgREST.

```bash
node scripts/supa.mjs tables          # lista tablas/vistas del public
node scripts/supa.mjs cols <tabla>    # columnas de una tabla
node scripts/supa.mjs get <tabla> 20  # primeras 20 filas
```

Limitación: PostgREST solo expone el schema `public` (y los que configures en
Settings > API > Exposed schemas). No ve `auth`, `storage`, etc.

## 2. MCP de Supabase (cuando tengas rol Owner/Admin)

Ya está configurado en `.mcp.json` (read-only). Falló el OAuth porque la cuenta
no tiene privilegios suficientes en el proyecto. Cuando consigas rol Owner/Admin:

```bash
claude /mcp      # seleccionar "supabase" > Authenticate
```

Reiniciar Claude Code después. Da acceso al esquema completo y queries.

## 3. Postgres directo (para ver TODOS los schemas)

Si necesitas inspeccionar más allá de `public`, usa el password de la DB
(Settings > Database) en `SUPABASE_DB_PASSWORD` y conéctate con `psql` o `pg`:

```
postgresql://postgres:[PASSWORD]@db.sfkhmlaaohidmotdnmlh.supabase.co:5432/postgres
```

Para que sea de verdad read-only, crear un rol con solo `SELECT`:

```sql
CREATE ROLE readonly LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE postgres TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
```

---

## Tipos de keys

| Key | Para qué | Seguridad |
|-----|----------|-----------|
| `sb_publishable_...` | Front-end, respeta RLS | Pública, OK exponer |
| `sb_secret_...` | Backend/inspección, bypassa RLS | **Secreta**, solo local |
| DB password | Postgres directo | **Secreta**, solo local |
