"use client";

import { useTransition } from "react";
import { decidirReconciliacion } from "./actions";
import { Button } from "@/components/ui/button";

type Item = {
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

export function ReviewItem({ item }: { item: Item }) {
  const [pending, startTransition] = useTransition();

  function decidir(decision: "confirmado" | "rechazado" | "saltado") {
    startTransition(async () => {
      await decidirReconciliacion(item.monday_hue, decision);
    });
  }

  const simPct = Math.round((item.similarity_score ?? 0) * 100);
  const simColor =
    simPct >= 70 ? "bg-emerald-100 text-emerald-700" :
    simPct >= 50 ? "bg-amber-100 text-amber-700" :
    "bg-rose-100 text-rose-700";

  return (
    <div className="space-y-4 rounded-lg border bg-card p-6 shadow-sm">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${simColor}`}>
            similitud {simPct}%
          </span>
          <span className="text-xs text-muted-foreground">{item.similarity_dim}</span>
        </div>
        {item.notas && (
          <span className="text-xs text-muted-foreground">{item.notas}</span>
        )}
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Card title="Monday" tone="default">
          <Field label="Clave SAGARPA" value={item.monday_hue} mono />
          <Field label="Nombre" value={item.monday_nombre} />
          <Field label="Municipio" value={item.monday_municipio} />
          <Field label="Productor" value={item.productor_nombre ?? "—"} />
        </Card>
        <Card title="SICOA (candidato)" tone="emerald">
          <Field label="Clave SAGARPA" value={item.sicoa_clave_sagarpa} mono />
          <Field label="Nombre" value={item.sicoa_nombre} />
          <Field label="Municipio" value={item.sicoa_municipio} />
          <Field label="Status SICOA" value={item.sicoa_status} />
        </Card>
      </div>

      <div className="flex flex-wrap items-center justify-end gap-2 border-t pt-4">
        <Button
          variant="ghost"
          disabled={pending}
          onClick={() => decidir("saltado")}
        >
          Saltar
        </Button>
        <Button
          variant="outline"
          disabled={pending}
          onClick={() => decidir("rechazado")}
        >
          Rechazar
        </Button>
        <Button
          disabled={pending}
          onClick={() => decidir("confirmado")}
        >
          Confirmar match
        </Button>
      </div>
    </div>
  );
}

function Card({
  title,
  tone,
  children,
}: {
  title: string;
  tone: "default" | "emerald";
  children: React.ReactNode;
}) {
  const border = tone === "emerald" ? "border-emerald-200" : "border-border";
  return (
    <div className={`space-y-2 rounded-md border ${border} bg-background p-4`}>
      <div className="text-xs font-medium uppercase tracking-wider text-muted-foreground">{title}</div>
      <div className="space-y-1.5">{children}</div>
    </div>
  );
}

function Field({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between gap-3 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className={`text-right ${mono ? "font-mono text-xs" : ""}`}>{value}</span>
    </div>
  );
}
