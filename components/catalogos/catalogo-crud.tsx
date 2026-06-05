"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Plus, MagnifyingGlass } from "@phosphor-icons/react";

import { Button } from "@/components/ui/button";
import { DataTable, type Column } from "@/components/ui/data-table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { CatalogoForm } from "./catalogo-form";
import { guardarCatalogo } from "@/lib/catalogos/actions";
import { CATALOGOS, SCHEMAS } from "@/lib/catalogos/schema";

/* CRUD genérico de un catálogo: tabla densa + alta/edición en modal.
   Click en fila = editar; botón Agregar = crear. Tras guardar, refresca los
   datos del servidor (router.refresh). Reusable para los 5 catálogos. */

const LIMITE = 80; // tope de filas en pantalla; el resto se encuentra buscando

type Row = { id: string };

export function CatalogoCrud<T extends Row>({
  catalogo,
  columns,
  rows,
  toDefaults,
  search,
  options,
}: {
  /** Clave en CATALOGOS (huertas, productores, …). */
  catalogo: keyof typeof CATALOGOS | string;
  columns: Column<T>[];
  rows: T[];
  /** Mapea una fila → valores del formulario (o undefined para alta). */
  toDefaults: (row?: T) => Record<string, unknown>;
  /** Texto buscable por fila. */
  search: (row: T) => string;
  options?: Record<string, { value: string; label: string }[]>;
}) {
  const def = CATALOGOS[catalogo as string];
  const schema = SCHEMAS[def.table];
  const router = useRouter();

  const [q, setQ] = React.useState("");
  const [editando, setEditando] = React.useState<T | null>(null);
  const [creando, setCreando] = React.useState(false);

  const filtradas = React.useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return rows;
    return rows.filter((r) => search(r).toLowerCase().includes(needle));
  }, [q, rows, search]);

  const visibles = filtradas.slice(0, LIMITE);
  const abierto = creando || editando != null;

  async function handleSubmit(values: Record<string, unknown>) {
    const res = await guardarCatalogo(def.table, values, editando?.id);
    if (res.ok) {
      setCreando(false);
      setEditando(null);
      router.refresh();
    }
    return res;
  }

  return (
    <section className="flex flex-col gap-3">
      {/* Barra: título + buscar + agregar */}
      <div className="flex items-center gap-3">
        <h2 className="text-h3 font-semibold text-text-primary">{def.plural}</h2>
        <span className="font-mono text-caption tabular-nums text-text-faint">
          {filtradas.length}
        </span>
        <div className="ml-auto flex items-center gap-2">
          <div className="flex h-9 items-center gap-2 rounded-sm border border-border bg-bg-default px-2.5">
            <MagnifyingGlass size={14} className="text-text-faint" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder={`Buscar ${def.plural.toLowerCase()}…`}
              className="w-44 bg-transparent text-ui text-text-primary outline-none placeholder:text-text-faint"
            />
          </div>
          <Button variant="default" onClick={() => setCreando(true)}>
            <Plus weight="bold" /> Agregar
          </Button>
        </div>
      </div>

      <DataTable
        columns={columns}
        rows={visibles}
        rowKey={(r) => r.id}
        onRowClick={(r) => setEditando(r)}
      />

      {filtradas.length > LIMITE && (
        <p className="text-caption text-text-faint">
          Mostrando {LIMITE} de {filtradas.length.toLocaleString("es-MX")} · afina con la
          búsqueda.
        </p>
      )}

      <Dialog
        open={abierto}
        onOpenChange={(o) => {
          if (!o) {
            setCreando(false);
            setEditando(null);
          }
        }}
      >
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {editando ? `Editar ${def.singular.toLowerCase()}` : `Nuevo ${def.singular.toLowerCase()}`}
            </DialogTitle>
            <DialogDescription>
              {editando
                ? "Actualiza los datos y guarda los cambios."
                : `Da de alta ${def.singular.toLowerCase()} en el catálogo maestro.`}
            </DialogDescription>
          </DialogHeader>

          {abierto && (
            <CatalogoForm
              fields={def.fields}
              schema={schema}
              defaultValues={toDefaults(editando ?? undefined)}
              options={options}
              submitLabel={editando ? "Guardar cambios" : "Crear"}
              onSubmit={handleSubmit}
              onCancel={() => {
                setCreando(false);
                setEditando(null);
              }}
            />
          )}
        </DialogContent>
      </Dialog>
    </section>
  );
}
