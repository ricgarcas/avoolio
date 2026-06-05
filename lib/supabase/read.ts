import "server-only";
import { createClient } from "@supabase/supabase-js";

/* Cliente de SOLO LECTURA sin cookies, para lecturas cacheables (unstable_cache).

   ¿Por qué separado del de server.ts? `unstable_cache` no permite leer cookies()
   ni headers() dentro de la función cacheada (truena). El cliente de server.ts sí
   las lee (sesión). Como los catálogos viven bajo RLS abierta y usan la key
   publishable, una lectura sin sesión devuelve lo mismo — y ya es cacheable.

   NO usar para escrituras ni para datos que dependan del usuario. */

export function createReadClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    { auth: { persistSession: false } },
  );
}

/** Tag único de caché para los catálogos. Se invalida en cada mutación. */
export const CATALOGOS_TAG = "catalogos";
