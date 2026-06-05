"use client";

import * as React from "react";
import { Plus, MagnifyingGlass, Warning } from "@phosphor-icons/react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DataTable, type Column } from "@/components/ui/data-table";
import { cn } from "@/lib/utils";
import { ProgramarCorteDialog } from "./programar-corte-dialog";
import {
  ESTADO_META,
  GRUPO_META,
  GRUPO_ORDER,
  grupoDe,
  ALTURA_MIN,
  type Corte,
} from "@/lib/cortes/schema";

type Opt = { value: string; label: string };
type HuertaOpt = { id: string; nombre: string; productor: string | null; municipio: string | null };

const peso = (v?: number) =>
  v == null || v === 0 ? "—" : `$${v.toLocaleString("es-MX", { minimumFractionDigits: 2 })}`;

export function CortesView({
  cortes,
  huertas,
  cuadrillas,
  acopiadores,
  tipos,
}: {
  cortes: Corte[];
  huertas: HuertaOpt[];
  cuadrillas: Opt[];
  acopiadores: Opt[];
  tipos: Opt[];
}) {
  const semanas = React.useMemo(
    () => [...new Set(cortes.map((c) => c.semana).filter((s): s is number => s != null))].sort((a, b) => b - a),
    [cortes],
  );
  const [semana, setSemana] = React.useState<number | "todas">(semanas[0] ?? "todas");
  const [q, setQ] = React.useState("");
  const [dialog, setDialog] = React.useState(false);
  const [editando, setEditando] = React.useState<Corte | null>(null);

  const filtrados = React.useMemo(() => {
    const needle = q.trim().toLowerCase();
    return cortes.filter((c) => {
      if (semana !== "todas" && c.semana !== semana) return false;
      if (!needle) return true;
      return `${c.huerto} ${c.productor ?? ""} ${c.empresa_corte ?? ""} ${c.acopio ?? ""}`
        .toLowerCase()
        .includes(needle);
    });
  }, [cortes, semana, q]);

  // Agrupa por la regla del spec (alerta de altura manda).
  const grupos = React.useMemo(() => {
    const m = new Map<string, Corte[]>();
    for (const c of filtrados) {
      const g = grupoDe(c);
      if (!m.has(g)) m.set(g, []);
      m.get(g)!.push(c);
    }
    return GRUPO_ORDER.filter((g) => m.has(g)).map((g) => ({ grupo: g, rows: m.get(g)! }));
  }, [filtrados]);

  const alertas = filtrados.filter((c) => c.asnm != null && c.asnm < ALTURA_MIN).length;

  const columns: Column<Corte>[] = [
    { header: "Huerto", cell: (c) => <span className="font-medium text-text-primary">{c.huerto}</span> },
    { header: "Productor", cell: (c) => c.productor ?? <span className="text-text-faint">—</span> },
    { header: "Municipio", cell: (c) => c.municipio ?? "—" },
    {
      header: "Altura",
      numeric: true,
      cell: (c) =>
        c.asnm == null ? (
          <span className="text-text-faint">—</span>
        ) : c.asnm < ALTURA_MIN ? (
          <span className="text-danger">{c.asnm.toLocaleString("es-MX")} ⚠</span>
        ) : (
          c.asnm.toLocaleString("es-MX")
        ),
    },
    { header: "Empresa corte", cell: (c) => c.empresa_corte ?? <span className="text-text-faint">sin asignar</span> },
    { header: "Acopiador", cell: (c) => c.acopio ?? "—" },
    { header: "Precio", numeric: true, cell: (c) => peso(c.precio_pactado) },
    {
      header: "Estado",
      cell: (c) => {
        const m = ESTADO_META[c.estado];
        return <Badge tone={m.tone}>{m.label}</Badge>;
      },
    },
  ];

  function abrirAlta() {
    setEditando(null);
    setDialog(true);
  }
  function abrirEdicion(c: Corte) {
    setEditando(c);
    setDialog(true);
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Encabezado */}
      <div className="flex flex-wrap items-center gap-3">
        <div>
          <h1 className="text-h1 font-semibold text-text-primary">Cortes</h1>
          <p className="text-caption text-text-muted">
            Programación de corte · {filtrados.length} en vista
            {alertas > 0 && (
              <span className="ml-1 inline-flex items-center gap-1 text-danger">
                · <Warning size={12} weight="fill" /> {alertas} con alerta de altura
              </span>
            )}
          </p>
        </div>

        <div className="ml-auto flex items-center gap-2">
          <select
            value={String(semana)}
            onChange={(e) => setSemana(e.target.value === "todas" ? "todas" : Number(e.target.value))}
            className="h-9 rounded-sm border border-border bg-bg-default px-2.5 text-ui text-text-primary outline-none focus-visible:border-brand"
          >
            <option value="todas">Todas las semanas</option>
            {semanas.map((s) => (
              <option key={s} value={s}>
                Semana {s}
              </option>
            ))}
          </select>

          <div className="flex h-9 items-center gap-2 rounded-sm border border-border bg-bg-default px-2.5">
            <MagnifyingGlass size={14} className="text-text-faint" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Buscar huerto, productor…"
              className="w-44 bg-transparent text-ui text-text-primary outline-none placeholder:text-text-faint"
            />
          </div>

          <Button variant="default" onClick={abrirAlta}>
            <Plus weight="bold" /> Programar corte
          </Button>
        </div>
      </div>

      {/* Grupos */}
      {grupos.length === 0 ? (
        <div className="rounded-md border border-dashed border-border py-16 text-center text-ui text-text-muted">
          Sin cortes para este filtro.
        </div>
      ) : (
        grupos.map(({ grupo, rows }) => {
          const meta = GRUPO_META[grupo];
          return (
            <section key={grupo} className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <span
                  className={cn(
                    "size-2 rounded-full",
                    meta.tone === "danger" && "bg-danger",
                    meta.tone === "success" && "bg-success",
                    meta.tone === "warning" && "bg-warning",
                    meta.tone === "neutral" && "bg-text-faint",
                  )}
                />
                <h2 className="text-h3 font-semibold text-text-primary">{meta.title}</h2>
                <span className="font-mono text-caption tabular-nums text-text-faint">{rows.length}</span>
              </div>
              <DataTable columns={columns} rows={rows} rowKey={(c) => c.id} onRowClick={abrirEdicion} />
            </section>
          );
        })
      )}

      <ProgramarCorteDialog
        open={dialog}
        onOpenChange={setDialog}
        editando={editando}
        huertas={huertas}
        cuadrillas={cuadrillas}
        acopiadores={acopiadores}
        tipos={tipos}
      />
    </div>
  );
}
