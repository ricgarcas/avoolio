import { getPendientes } from "@/lib/acopio-queries";
import { PendientesQueue } from "@/components/pendientes/pendientes-queue";

// Datos en vivo desde Supabase (public.pendiente_hitl) en cada request.
export const dynamic = "force-dynamic";

export default async function PendientesPage() {
  const pendientes = await getPendientes();
  const serverNow = new Date().toISOString();

  return <PendientesQueue pendientes={pendientes} serverNow={serverNow} />;
}
