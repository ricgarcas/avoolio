import Link from "next/link";
import { ArrowRight, Tray } from "@phosphor-icons/react/dist/ssr";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getCatalogoCounts } from "@/lib/catalogos/queries";
import { getPendientes } from "@/lib/acopio-queries";
import { TIPO_META } from "@/lib/acopio";
import { mxn, delta } from "@/lib/format";

export const dynamic = "force-dynamic";

export default async function InicioPage() {
  const [counts, pendientes] = await Promise.all([
    getCatalogoCounts(),
    getPendientes(),
  ]);

  const kpis = [
    { label: "Pendientes HITL", value: pendientes.length, href: "/pendientes", tone: pendientes.length > 0 },
    { label: "Huertas", value: counts.huerta, href: "/catalogos" },
    { label: "Productores", value: counts.productor, href: "/catalogos" },
    { label: "Acopiadores", value: counts.acopiador, href: "/catalogos" },
    { label: "Cuadrillas", value: counts.cuadrilla, href: "/catalogos" },
    { label: "Acarreadores", value: counts.acarreador, href: "/catalogos" },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-h1 font-semibold text-text-primary">Inicio</h1>
        <p className="text-caption text-text-muted">
          Resumen operativo · empacadora San José · datos en vivo
        </p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {kpis.map((k) => (
          <Link
            key={k.label}
            href={k.href}
            className="group rounded-md border border-border bg-card p-4 transition-colors hover:bg-bg-hover"
          >
            <div className="text-caption text-text-muted">{k.label}</div>
            <div
              className={`mt-1 font-mono text-display tabular-nums ${
                k.tone ? "text-brand" : "text-text-primary"
              }`}
            >
              {k.value.toLocaleString("es-MX")}
            </div>
          </Link>
        ))}
      </div>

      {/* Cola de pendientes + accesos */}
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Tray size={16} className="text-text-muted" /> Cola de pendientes
            </CardTitle>
            <Link
              href="/pendientes"
              className="ml-auto flex items-center gap-1 text-caption text-brand hover:underline"
            >
              Ver todo <ArrowRight size={12} />
            </Link>
          </CardHeader>
          <CardContent className="p-0">
            {pendientes.length === 0 ? (
              <p className="px-4 py-8 text-center text-ui text-text-muted">
                Sin aprobaciones en cola.
              </p>
            ) : (
              <ul className="divide-y divide-border">
                {pendientes.slice(0, 5).map((p) => {
                  const meta = TIPO_META[p.tipo];
                  return (
                    <li key={p.id} className="flex items-center gap-3 px-4 py-2.5">
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-ui text-text-primary">
                          {p.huerta}
                        </span>
                        <span className="block truncate font-mono text-caption text-text-faint">
                          {p.codigoHue}
                        </span>
                      </span>
                      <span className="font-mono text-ui tabular-nums text-text-primary">
                        {mxn(p.precioPropuesto)}
                      </span>
                      {p.margenPct != null ? (
                        <Badge tone={p.margenPct < 0 ? "danger" : "success"}>
                          {delta(p.margenPct)}
                        </Badge>
                      ) : (
                        <Badge tone={meta.tone} dot>
                          {meta.label}
                        </Badge>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Operación</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-2 text-ui text-text-muted">
            <p className="text-caption">
              Cortes, cuentas por pagar, facturas, pagos y costeo llegan en el
              siguiente pase. Los catálogos maestros ya están en vivo desde
              Monday.
            </p>
            <Link
              href="/catalogos"
              className="mt-1 flex items-center gap-1 text-caption text-brand hover:underline"
            >
              Ir a catálogos <ArrowRight size={12} />
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
