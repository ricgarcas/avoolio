import { createBrowserClient } from "@supabase/ssr";

/** Cliente Supabase para componentes de cliente. Usa la publishable key
 *  (respeta RLS, segura para el front). */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
  );
}
