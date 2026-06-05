"use client";

import * as React from "react";
import { Check, MagnifyingGlass, X, PencilSimple } from "@phosphor-icons/react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DataTable, type Column } from "@/components/ui/data-table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { mxn, delta, hace } from "@/lib/format";
import { TIPO_META, type Pendiente, type PendienteTipo } from "@/lib/acopio";

type Filtro = "todos" | PendienteTipo;

const FILTROS: { key: Filtro; label: string }[] = [
  { key: "todos", label: "Todos" },
  { key: "fuera_margen", label: "Fuera de margen" },
  { key: "coyote", label: "Coyote" },
  { key: "modificacion", label: "Modificación" },
];

const chipCls =
  "rounded-sm border px-2.5 py-1 text-caption font-medium transition-colors";

export function PendientesQueue({
  pendientes,
  serverNow,
}: {
  pendientes: Pendiente[];
  serverNow: string;
}) {
  const now = React.useMemo(() => new Date(serverNow), [serverNow]);
  const [filtro, setFiltro] = React.useState<Filtro>("todos");
  const [q, setQ] = React.useState("");
  const [detalle, setDetalle] = React.useState<Pendiente | null>(null);
  // Aprobaciones resueltas en esta sesión (optimista; aún sin escritura a DB).
  const [resueltos, setResueltos] = React.useState<Set<string>>(new Set());
  const [aprobando, setAprobando] = React.useState<Pendiente | null>(null);

  const vivos = pendientes.filter((p) => !resueltos.has(p.id));

  const filtrados = React.useMemo(() => {
    const needle = q.trim().toLowerCase();
    return vivos.filter((p) => {
      if (filtro !== "todos" && p.tipo !== filtro) return false;
      if (!needle) return true;
      return `${p.huerta} ${p.productor} ${p.acopiador ?? ""} ${p.codigoHue} ${p.acopio ?? ""}`
        .toLowerCase()
        .includes(needle);
    });
  }, [vivos, filtro, q]);

  const cuenta = (f: Filtro) =>
    f === "todos" ? vivos.length : vivos.filter((p) => p.tipo === f).length;

  const columns: Column<Pendiente>[] = [
    {
      header: "Antigüedad",
      width: "92px",
      cell: (p) => (
        <span className="font-mono tabular-nums text-text-muted">
          {hace(new Date(p.createdAt), now)}
        </span>
      ),
    },
    {
      header: "Huerta",
      cell: (p) => (
        <span>
          <span className="block truncate font-medium text-text-primary">{p.huerta}</span>
          <span className="block truncate font-mono text-caption text-text-faint">
            {p.codigoHue}
            {p.acopio && ` · ${p.acopio}`}
          </span>
        </span>
      ),
    },
    {
      header: "Productor",
      cell: (p) => (
        <span>
          <span className="block truncate text-text-primary">{p.productor}</span>
          {p.acopiador && (
            <span className="block truncate text-caption text-text-faint">{p.acopiador}</span>
          )}
        </span>
      ),
    },
    {
      header: "Precio",
      numeric: true,
      cell: (p) => (
        <span>
          {p.calibre != null && <span className="text-text-faint">cal {p.calibre} </span>}
          {mxn(p.precioPropuesto)}
        </span>
      ),
    },
    {
      header: "Tipo",
      cell: (p) => {
        if (p.margenPct != null) {
          return (
            <Badge tone={p.margenPct < 0 ? "danger" : "success"}>{delta(p.margenPct)}</Badge>
          );
        }
        const m = TIPO_META[p.tipo];
        return (
          <Badge tone={m.tone} dot>
            {m.label}
          </Badge>
        );
      },
    },
  ];

  return (
    <div className="flex flex-col gap-4">
      {/* Encabezado */}
      <div className="flex flex-wrap items-center gap-3">
        <div>
          <h1 className="text-h1 font-semibold text-text-primary">Pendientes</h1>
          <p className="text-caption text-text-muted">
            Aprobaciones de precio fuera de margen · {filtrados.length} en vista
          </p>
        </div>

        <div className="ml-auto flex items-center gap-2">
          <div className="flex h-9 items-center gap-2 rounded-sm border border-border bg-bg-default px-2.5">
            <MagnifyingGlass size={14} className="text-text-faint" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Huerta, productor, código…"
              className="w-48 bg-transparent text-ui text-text-primary outline-none placeholder:text-text-faint"
            />
          </div>
        </div>
      </div>

      {/* Filtros de tipo */}
      <div className="flex flex-wrap items-center gap-1">
        {FILTROS.map((f) => {
          const activo = filtro === f.key;
          const n = cuenta(f.key);
          return (
            <button
              key={f.key}
              onClick={() => setFiltro(f.key)}
              className={cn(
                chipCls,
                "inline-flex items-center gap-1.5",
                activo
                  ? "border-brand/40 bg-brand/12 text-brand"
                  : "border-border text-text-muted hover:bg-bg-hover",
              )}
            >
              {f.label}
              {n > 0 && <span className="font-mono tabular-nums">{n}</span>}
            </button>
          );
        })}
      </div>

      {/* Cola */}
      {filtrados.length === 0 ? (
        <div className="flex flex-col items-center gap-1 rounded-md border border-dashed border-border py-16 text-center">
          <Check size={28} className="text-success" />
          <p className="text-body font-medium text-text-primary">Sin pendientes</p>
          <p className="text-caption text-text-muted">
            No hay aprobaciones en cola para este filtro.
          </p>
        </div>
      ) : (
        <DataTable
          columns={columns}
          rows={filtrados}
          rowKey={(p) => p.id}
          selectedKey={detalle?.id}
          onRowClick={setDetalle}
        />
      )}

      {/* Diálogo de detalle + acciones */}
      <DetalleDialog
        pendiente={detalle}
        onClose={() => setDetalle(null)}
        onAprobar={(p) => setAprobando(p)}
      />

      {/* Modal de PIN */}
      <AprobarDialog
        pendiente={aprobando}
        onClose={() => setAprobando(null)}
        onConfirmado={(id) => {
          setResueltos((s) => new Set(s).add(id));
          setAprobando(null);
          setDetalle(null);
        }}
      />
    </div>
  );
}

function DetalleDialog({
  pendiente,
  onClose,
  onAprobar,
}: {
  pendiente: Pendiente | null;
  onClose: () => void;
  onAprobar: (p: Pendiente) => void;
}) {
  // Conserva el último pendiente para que el contenido no parpadee al cerrar.
  const [snapshot, setSnapshot] = React.useState<Pendiente | null>(pendiente);
  React.useEffect(() => {
    if (pendiente) setSnapshot(pendiente);
  }, [pendiente]);
  const p = pendiente ?? snapshot;
  const meta = p ? TIPO_META[p.tipo] : null;

  return (
    <Dialog open={pendiente != null} onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        {p && meta && (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                {p.huerta}
                {p.margenPct != null ? (
                  <Badge tone={p.margenPct < 0 ? "danger" : "success"}>
                    {delta(p.margenPct)}
                  </Badge>
                ) : (
                  <Badge tone={meta.tone} dot>
                    {meta.label}
                  </Badge>
                )}
              </DialogTitle>
              <DialogDescription className="font-mono">
                {p.codigoHue}
                {p.acopio && ` · ${p.acopio}`}
              </DialogDescription>
            </DialogHeader>

            <div className="rounded-sm border border-border bg-bg-default p-3">
              <div className="mb-2 flex items-center gap-2">
                <Badge tone={meta.tone} dot>
                  {meta.label}
                </Badge>
                {p.banda != null && (
                  <span className="text-caption text-text-muted">banda {p.banda}</span>
                )}
              </div>
              <p className="text-ui text-text-primary">{p.razonHitl}</p>

              <dl className="mt-3 grid grid-cols-2 gap-x-4 gap-y-1.5 text-caption">
                <Dato k="Productor" v={p.productor} />
                <Dato k="Acopiador" v={p.acopiador ?? "—"} />
                <Dato
                  k="Precio propuesto"
                  v={`${p.calibre != null ? `cal ${p.calibre} · ` : ""}${mxn(p.precioPropuesto)}`}
                  mono
                />
                <Dato
                  k="Techo de banda"
                  v={p.precioBandaMax != null ? mxn(p.precioBandaMax) : "—"}
                  mono
                />
                <Dato
                  k="Volumen"
                  v={p.volumenKg ? `${p.volumenKg.toLocaleString("es-MX")} kg` : "—"}
                  mono
                />
                <Dato k="Variedad" v={p.variedad} />
              </dl>
            </div>

            {/* Acciones — un primario (Aprobar) por fila */}
            <DialogFooter>
              <Button variant="destructive" className="flex-1 sm:flex-none">
                <X weight="bold" /> Rechazar
              </Button>
              <Button variant="secondary" className="flex-1 sm:flex-none">
                <PencilSimple /> Modificar
              </Button>
              <Button
                variant="default"
                className="flex-1 sm:flex-none"
                onClick={() => onAprobar(p)}
              >
                <Check weight="bold" /> Aprobar
              </Button>
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}

function Dato({ k, v, mono }: { k: string; v: string; mono?: boolean }) {
  return (
    <div className="flex flex-col">
      <dt className="text-text-faint">{k}</dt>
      <dd className={cn("text-text-primary", mono && "font-mono tabular-nums")}>{v}</dd>
    </div>
  );
}

function AprobarDialog({
  pendiente,
  onClose,
  onConfirmado,
}: {
  pendiente: Pendiente | null;
  onClose: () => void;
  onConfirmado: (id: string) => void;
}) {
  const [pin, setPin] = React.useState("");
  React.useEffect(() => {
    if (pendiente) setPin("");
  }, [pendiente]);

  const completo = pin.length === 4;

  return (
    <Dialog
      open={pendiente != null}
      onOpenChange={(o) => {
        if (!o) onClose();
      }}
    >
      <DialogContent showCloseButton={false}>
        <DialogHeader>
          <DialogTitle>Confirmar aprobación</DialogTitle>
          {pendiente && (
            <DialogDescription>
              {pendiente.huerta} · cal {pendiente.calibre} ·{" "}
              <span className="font-mono">{mxn(pendiente.precioPropuesto)}/kg</span>
              {pendiente.banda != null && ` (banda ${pendiente.banda})`}. Ingresa el
              PIN enviado por WhatsApp para autorizar.
            </DialogDescription>
          )}
        </DialogHeader>

        <PinInput value={pin} onChange={setPin} />

        <DialogFooter>
          <DialogClose render={<Button variant="ghost">Cancelar</Button>} />
          <Button
            variant="default"
            disabled={!completo}
            onClick={() => pendiente && onConfirmado(pendiente.id)}
          >
            <Check weight="bold" /> Aprobar
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function PinInput({
  value,
  onChange,
}: {
  value: string;
  onChange: (v: string) => void;
}) {
  const refs = React.useRef<(HTMLInputElement | null)[]>([]);
  const digits = [0, 1, 2, 3];

  const setAt = (i: number, d: string) => {
    const clean = d.replace(/\D/g, "").slice(-1);
    const arr = value.split("");
    arr[i] = clean;
    const next = arr.join("").slice(0, 4);
    onChange(next);
    if (clean && i < 3) refs.current[i + 1]?.focus();
  };

  return (
    <div className="flex justify-center gap-2">
      {digits.map((i) => (
        <input
          key={i}
          ref={(el) => {
            refs.current[i] = el;
          }}
          inputMode="numeric"
          maxLength={1}
          value={value[i] ?? ""}
          onChange={(e) => setAt(i, e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Backspace" && !value[i] && i > 0)
              refs.current[i - 1]?.focus();
          }}
          aria-label={`Dígito ${i + 1} del PIN`}
          className="size-12 rounded-sm border border-border bg-bg-default text-center font-mono text-h3 text-text-primary outline-none focus-visible:border-brand"
        />
      ))}
    </div>
  );
}
