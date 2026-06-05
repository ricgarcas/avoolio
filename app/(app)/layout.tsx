import { AppShell } from "@/components/app/app-shell";
import { getPendientes } from "@/lib/acopio-queries";

export const dynamic = "force-dynamic";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pendientes = await getPendientes();
  return <AppShell pendientesCount={pendientes.length}>{children}</AppShell>;
}
