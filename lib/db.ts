import "server-only";
import { Pool } from "pg";

/* Acceso a Postgres directo (server-only) para los schemas de negocio
   (ops, core, agent, sales) que PostgREST/supabase-js NO expone — la Data API
   solo deja ver `public`. Usa el DB password de `.env.local`. El password nunca
   sale del servidor.

   Cuando el proyecto exponga estos schemas en la Data API (rol Owner), se podrá
   migrar a supabase-js y quitar esta capa. */

const ref = process.env.SUPABASE_REF ?? "sfkhmlaaohidmotdnmlh";
const password = process.env.SUPABASE_DB_PASSWORD;

let pool: Pool | null = null;

/** Pool perezoso. Devuelve null si no hay password configurado. */
export function getPool(): Pool | null {
  if (!password) return null;
  if (!pool) {
    pool = new Pool({
      host: `db.${ref}.supabase.co`,
      port: 5432,
      user: "postgres",
      password,
      database: "postgres",
      ssl: { rejectUnauthorized: false },
      max: 3,
      connectionTimeoutMillis: 8000,
    });
  }
  return pool;
}

/** Query tipada. Lanza si no hay pool (sin password) — el caller decide el fallback. */
export async function query<T>(text: string, params?: unknown[]): Promise<T[]> {
  const p = getPool();
  if (!p) throw new Error("Sin SUPABASE_DB_PASSWORD: Postgres directo no disponible.");
  const res = await p.query(text, params);
  return res.rows as T[];
}
