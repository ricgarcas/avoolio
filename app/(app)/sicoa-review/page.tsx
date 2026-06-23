import { query } from "@/lib/db";
import { ReviewItem } from "./review-item";

export const dynamic = "force-dynamic";

type Stats = { status: string; n: number };
type Pendiente = {
  monday_hue: string;
  monday_nombre: string;
  monday_municipio: string;
  productor_nombre: string | null;
  sicoa_clave_sagarpa: string;
  sicoa_nombre: string;
  sicoa_municipio: string;
  sicoa_status: string;
  similarity_score: number;
  similarity_dim: string;
  notas: string | null;
};

async function getStats() {
  return await query<Stats>(`
    select status, count(*)::int as n
    from acopio.huerta_reconciliacion
    group by status
    order by status
  `);
}

async function getNextPendiente() {
  const rows = await query<Pendiente>(`
    select
      r.monday_hue,
      h.nombre as monday_nombre,
      h.municipio as monday_municipio,
      p.nombre as productor_nombre,
      r.sicoa_clave_sagarpa,
      s.nombre_huerta as sicoa_nombre,
      s.municipio as sicoa_municipio,
      s.status as sicoa_status,
      r.similarity_score::float as similarity_score,
      r.similarity_dim,
      r.notas
    from acopio.huerta_reconciliacion r
    join public.huerta h on h.hue = r.monday_hue
    left join public.productor p on p.id = h.productor_id
    left join sicoa_raw.huerta_listado_general s on s.clave_sagarpa = r.sicoa_clave_sagarpa
    where r.status = 'pendiente'
    order by r.updated_at asc, r.similarity_score desc nulls last, r.monday_hue
    limit 1
  `);
  return rows[0];
}

export default async function SicoaReviewPage() {
  const [stats, item] = await Promise.all([getStats(), getNextPendiente()]);
  const total = stats.reduce((sum, s) => sum + s.n, 0);
  const confirmado = stats.find((s) => s.status === "auto_confirmado" || s.status === "confirmado")?.n ?? 0;
  const pendientes = stats.find((s) => s.status === "pendiente")?.n ?? 0;
  const rechazadas = stats.find((s) => s.status === "rechazado")?.n ?? 0;
  const sinMatch = stats.find((s) => s.status === "sin_match")?.n ?? 0;
  const procesadas = total - pendientes;
  const pct = total > 0 ? Math.round((procesadas / total) * 100) : 0;

  return (
    <div className="mx-auto max-w-5xl space-y-6 p-6">
      <header className="space-y-1">
        <h1 className="text-2xl font-semibold tracking-tight">Reconciliación SICOA</h1>
        <p className="text-sm text-muted-foreground">
          Decisión manual de las huertas Monday cuyo match con SICOA no fue automático.
        </p>
      </header>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
        <Stat label="Total Monday" value={total} />
        <Stat label="Confirmadas" value={confirmado} accent="emerald" />
        <Stat label="Rechazadas" value={rechazadas} accent="rose" />
        <Stat label="Sin match" value={sinMatch} accent="amber" />
        <Stat label="Pendientes" value={pendientes} accent="blue" />
      </div>

      <div className="flex items-center gap-3 rounded-lg border bg-card p-3">
        <div className="flex-1">
          <div className="h-2 overflow-hidden rounded-full bg-muted">
            <div
              className="h-full bg-emerald-500 transition-all"
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>
        <div className="text-sm tabular-nums text-muted-foreground">
          {procesadas}/{total} ({pct}%)
        </div>
      </div>

      {item ? (
        <ReviewItem item={item} />
      ) : (
        <div className="rounded-lg border bg-card p-12 text-center">
          <div className="text-lg font-medium">✓ No quedan pendientes</div>
          <div className="mt-1 text-sm text-muted-foreground">
            Todas las huertas Monday tienen una decisión de reconciliación.
          </div>
        </div>
      )}
    </div>
  );
}

function Stat({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent?: "emerald" | "rose" | "amber" | "blue";
}) {
  const color =
    accent === "emerald" ? "text-emerald-600" :
    accent === "rose" ? "text-rose-600" :
    accent === "amber" ? "text-amber-600" :
    accent === "blue" ? "text-blue-600" : "text-foreground";
  return (
    <div className="rounded-lg border bg-card p-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className={`mt-1 text-2xl font-semibold tabular-nums ${color}`}>{value.toLocaleString("es-MX")}</div>
    </div>
  );
}
