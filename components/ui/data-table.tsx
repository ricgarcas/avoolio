"use client";

import * as React from "react";
import { CaretLeft, CaretRight } from "@phosphor-icons/react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

/* Tabla densa — la superficie firma de AgroMesh: rejilla completa de 1px,
   filas de 36px, números en mono (tabular), y borde izquierdo de 2px en verde
   de marca en la fila seleccionada. El estado nunca depende solo del color.
   Construida sobre las primitivas <Table> de shadcn.

   Paginación client-side por defecto (10/pág): el filtrado/búsqueda viven en
   las vistas y le pasan las filas ya filtradas; aquí solo se trocean. Para
   listas muy chicas o agrupadas, pásale pageSize={0} para desactivarla. */

/** Tamaño de página por defecto. */
const DEFAULT_PAGE_SIZE = 10;

export interface Column<T> {
  /** Encabezado visible. */
  header: string;
  /** Render de la celda. */
  cell: (row: T) => React.ReactNode;
  /** Alinear a la derecha + tipografía mono tabular (números). */
  numeric?: boolean;
  /** Ancho fijo opcional (ej. "120px"). */
  width?: string;
}

export interface DataTableProps<T> {
  columns: Column<T>[];
  rows: T[];
  /** Clave estable por fila. */
  rowKey: (row: T) => string;
  /** Fila seleccionada (marca borde izq 2px verde). */
  selectedKey?: string;
  onRowClick?: (row: T) => void;
  className?: string;
  /** Filas por página. Default 10. Usa 0 para desactivar la paginación. */
  pageSize?: number;
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  selectedKey,
  onRowClick,
  className,
  pageSize = DEFAULT_PAGE_SIZE,
}: DataTableProps<T>) {
  const paginate = pageSize > 0 && rows.length > pageSize;
  const pageCount = paginate ? Math.ceil(rows.length / pageSize) : 1;
  const [page, setPage] = React.useState(0);

  // Si cambian el total de filas (filtro/búsqueda) y la página actual quedó
  // fuera de rango, regresa a la última válida.
  React.useEffect(() => {
    if (page > pageCount - 1) setPage(Math.max(0, pageCount - 1));
  }, [page, pageCount]);

  const visibles = paginate ? rows.slice(page * pageSize, page * pageSize + pageSize) : rows;
  const desde = rows.length === 0 ? 0 : page * pageSize + 1;
  const hasta = paginate ? Math.min(rows.length, (page + 1) * pageSize) : rows.length;

  return (
    <div className="flex flex-col gap-2">
      <div className={cn("overflow-hidden rounded-md border border-border", className)}>
        <Table className="text-ui">
          <TableHeader>
            <TableRow className="bg-bg-raised hover:bg-bg-raised">
              {columns.map((col, i) => (
                <TableHead
                  key={i}
                  style={col.width ? { width: col.width } : undefined}
                  className={cn(
                    "h-9 border-b border-border px-3 text-caption font-medium uppercase tracking-wide text-text-muted",
                    col.numeric && "text-right",
                  )}
                >
                  {col.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {visibles.map((row) => {
              const key = rowKey(row);
              const selected = key === selectedKey;
              return (
                <TableRow
                  key={key}
                  onClick={onRowClick ? () => onRowClick(row) : undefined}
                  data-state={selected ? "selected" : undefined}
                  className={cn(
                    "h-9 border-b border-border last:border-b-0",
                    onRowClick && "cursor-pointer",
                    selected
                      ? "border-l-2 border-l-brand bg-bg-hover"
                      : "border-l-2 border-l-transparent",
                  )}
                >
                  {columns.map((col, i) => (
                    <TableCell
                      key={i}
                      className={cn(
                        "h-9 px-3 py-0",
                        col.numeric &&
                          "text-right font-mono tabular-nums text-text-primary",
                      )}
                    >
                      {col.cell(row)}
                    </TableCell>
                  ))}
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>

      {paginate && (
        <div className="flex items-center justify-between px-1 text-caption text-text-muted">
          <span className="tabular-nums">
            {desde}–{hasta} de {rows.length}
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="xs"
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0}
            >
              <CaretLeft />
              Anterior
            </Button>
            <span className="tabular-nums">
              {page + 1} / {pageCount}
            </span>
            <Button
              variant="outline"
              size="xs"
              onClick={() => setPage((p) => Math.min(pageCount - 1, p + 1))}
              disabled={page >= pageCount - 1}
            >
              Siguiente
              <CaretRight />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
