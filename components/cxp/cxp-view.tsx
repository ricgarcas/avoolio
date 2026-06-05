"use client";

import * as React from "react";
import { MagnifyingGlass, Lock } from "@phosphor-icons/react";

import { Badge } from "@/components/ui/badge";
import { DataTable, type Column } from "@/components/ui/data-table";
import { CxpEditDialog } from "./cxp-edit-dialog";
import { mxn } from "@/lib/format";
import { ESTADO_META, TIPO_META, puedePagar, type Cxp, type CxpTipo, type CxpEstado } from "@/lib/cxp/schema";

const selectCls =
  "h-9 rounded-sm border border-border bg-bg-default px-2.5 text-ui text-text-primary outline-none focus-visible:border-brand";

const TIPOS: { v: CxpTipo | "todos"; label: string }[] = [
  { v: "todos", label: "Todos" },
  { v: "productor", label: "Productor" },
  { v: "servicio_corte", label: "Corte" },
  { v: "acarreo", label: "Acarreo" },
];

export function CxpView({ cxp }: { cxp: Cxp[] }) {
  const semanas = React.useMemo(
    () => [...new Set(cxp.map((c) => c.semana).filter((s): s is number => s != null))].sort((a, b) => b - a),
    [cxp],
  );
  const [semana, setSemana] = React.useState<number | "todas">("todas");
  const [tipo, setTipo] = React.useState<CxpTipo | "todos">("todos");
  const [soloSinFactura, setSoloSinFactura] = React.useState(false);
  const [q, setQ] = React.useState("");
  const [editar, setEditar] = React.useState<Cxp | null>(null);

  const filtrados = React.useMemo(() => {
    const needle = q.trim().toLowerCase();
    return cxp.filter((c) => {
      if (semana !== "todas" && c.semana !== semana) return false;
      if (tipo !== "todos" && c.tipo !== tipo) return false;
      if (soloSinFactura && puedePagar(c)) return false;
      if (needle && !`${c.beneficiario ?? ""} ${c.huerta ?? ""} ${c.lote ?? ""}`.toLowerCase().includes(needle))
        return false;
      return true;
    });
  }, [cxp, semana, tipo, soloSinFactura, q]);

  const totalConocido = filtrados.reduce((s, c) => s + (c.monto ?? 0), 0);
  const sinFactura = filtrados.filter((c) => !puedePagar(c)).length;
  const sinMonto = filtrados.filter((c) => c.monto == null).length;
  const estimados = filtrados.filter((c) => c.montoEstimado).length;

  const columns: Column<Cxp>[] = [
    {
      header: "Tipo",
      cell: (c) => <span className="text-text-muted">{TIPO_META[c.tipo].short}</span>,
    },
    {
      header: "Beneficiario",
      cell: (c) => (
        <span>
          <span className="block truncate font-medium text-text-primary">{c.beneficiario ?? "—"}</span>
          {c.huerta && <span className="block truncate text-caption text-text-faint">{c.huerta}</span>}
        </span>
      ),
    },
    {
      header: "Factura",
      cell: (c) =>
        puedePagar(c) ? (
          <Badge tone="success">✓ {c.factura}</Badge>
        ) : (
          <span className="inline-flex items-center gap-1 text-caption text-danger">
            <Lock size={12} weight="fill" /> Sin factura
          </span>
        ),
    },
    {
      header: "Monto",
      numeric: true,
      cell: (c) =>
        c.monto == null ? (
          <span className="text-text-faint">pendiente</span>
        ) : c.montoEstimado ? (
          <span className="text-text-muted" title="Estimado con la tarifa por viaje del catálogo">
            ~{mxn(c.monto)}
          </span>
        ) : (
          mxn(c.monto)
        ),
    },
    {
      header: "Estado",
      cell: (c) => {
        const m = ESTADO_META[c.estado];
        return <Badge tone={m.tone}>{m.label}</Badge>;
      },
    },
  ];

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3">
        <div>
          <h1 className="text-h1 font-semibold text-text-primary">Cuentas por pagar</h1>
          <p className="text-caption text-text-muted">
            Obligaciones del acopio · {filtrados.length} en vista · {sinFactura} sin factura
          </p>
        </div>

        <div className="ml-auto flex flex-wrap items-center gap-2">
          <select value={String(semana)} onChange={(e) => setSemana(e.target.value === "todas" ? "todas" : Number(e.target.value))} className={selectCls}>
            <option value="todas">Todas las semanas</option>
            {semanas.map((s) => (
              <option key={s} value={s}>Semana {s}</option>
            ))}
          </select>
          <div className="flex h-9 items-center gap-2 rounded-sm border border-border bg-bg-default px-2.5">
            <MagnifyingGlass size={14} className="text-text-faint" />
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Beneficiario, huerta…" className="w-40 bg-transparent text-ui text-text-primary outline-none placeholder:text-text-faint" />
          </div>
        </div>
      </div>

      {/* Filtros de tipo + candado */}
      <div className="flex flex-wrap items-center gap-1">
        {TIPOS.map((t) => (
          <button
            key={t.v}
            onClick={() => setTipo(t.v)}
            className={`rounded-sm border px-2.5 py-1 text-caption font-medium transition-colors ${
              tipo === t.v ? "border-brand/40 bg-brand/12 text-brand" : "border-border text-text-muted hover:bg-bg-hover"
            }`}
          >
            {t.label}
          </button>
        ))}
        <button
          onClick={() => setSoloSinFactura((v) => !v)}
          className={`ml-2 inline-flex items-center gap-1 rounded-sm border px-2.5 py-1 text-caption font-medium transition-colors ${
            soloSinFactura ? "border-danger/40 bg-danger/12 text-danger" : "border-border text-text-muted hover:bg-bg-hover"
          }`}
        >
          <Lock size={12} weight="fill" /> Solo sin factura
        </button>
      </div>

      <DataTable columns={columns} rows={filtrados} rowKey={(c) => c.id} onRowClick={setEditar} />

      {/* Total + candado */}
      <div className="flex flex-wrap items-center justify-between gap-2 rounded-md border border-border bg-bg-raised px-4 py-3">
        <span className="text-ui text-text-muted">
          Total obligaciones {semana !== "todas" ? `· Semana ${semana}` : ""}
          {(sinMonto > 0 || estimados > 0) && (
            <span className="text-caption text-text-faint">
              {" "}({estimados > 0 && `${estimados} estimados por tarifa`}
              {estimados > 0 && sinMonto > 0 && " · "}
              {sinMonto > 0 && `${sinMonto} sin monto`})
            </span>
          )}
        </span>
        <span className="font-mono text-h3 font-semibold tabular-nums text-text-primary">{mxn(totalConocido)}</span>
      </div>

      <div className="flex items-start gap-2 rounded-md border border-danger/30 bg-danger/12 px-4 py-3">
        <Lock size={16} weight="fill" className="mt-0.5 shrink-0 text-danger" />
        <p className="text-caption text-text-primary">
          <strong className="text-danger">Candado de factura.</strong> Las filas{" "}
          <span className="text-danger">Sin factura</span> no pueden avanzar a <em>pagada</em>: el estado se
          bloquea hasta que administración registre el CFDI. Los montos de acarreo con{" "}
          <span className="font-mono">~</span> son estimados con la tarifa por viaje del catálogo (captúrala en{" "}
          <strong>Catálogos → Acarreadores</strong> para que se ajusten).
        </p>
      </div>

      <CxpEditDialog cxp={editar} onClose={() => setEditar(null)} />
    </div>
  );
}
