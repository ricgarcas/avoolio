"use client";

import * as React from "react";
import { Leaf, Check } from "@phosphor-icons/react";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardHeader,
  CardTitle,
  CardAction,
  CardContent,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DataTable, type Column } from "@/components/ui/data-table";
import {
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { ThemeToggle } from "@/components/theme-toggle";
import { mxn, usd, delta } from "@/lib/format";

/* Showcase del sistema de diseño AgroMesh — la "prueba viva" (spec §03):
   los tokens y componentes renderizando fieles al spec. Esta NO es una pantalla
   de producto; es la galería de referencia del design system. */

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="flex flex-col gap-4">
      <h2 className="border-b border-border pb-2 text-h3 font-semibold text-text-primary">
        {title}
      </h2>
      {children}
    </section>
  );
}

function Swatch({
  name,
  hex,
  className,
}: {
  name: string;
  hex: string;
  className: string;
}) {
  return (
    <div className="overflow-hidden rounded-md border border-border">
      <div className={`h-16 ${className}`} />
      <div className="bg-bg-raised px-2 py-1.5">
        <p className="text-caption font-medium text-text-primary">{name}</p>
        <p className="font-mono text-caption text-text-muted">{hex}</p>
      </div>
    </div>
  );
}

// — Datos de muestra (sabor acopio): solo para demostrar la tabla densa. —
type HuertaRow = {
  id: string;
  huerta: string;
  acopiador: string;
  cal: number;
  precio: number;
  estado: { tone: "success" | "info" | "warning"; label: string };
};

const ROWS: HuertaRow[] = [
  { id: "1", huerta: "La Esperanza", acopiador: "Juan Pérez", cal: 48, precio: 38.5, estado: { tone: "success", label: "acordada" } },
  { id: "2", huerta: "El Roble", acopiador: "M. Hernández", cal: 40, precio: 40.2, estado: { tone: "info", label: "abierta" } },
  { id: "3", huerta: "Don Pedro", acopiador: "Juan Pérez", cal: 36, precio: 42.0, estado: { tone: "warning", label: "fuera de margen" } },
];

const COLUMNS: Column<HuertaRow>[] = [
  { header: "Huerta", cell: (r) => <span className="text-text-primary">{r.huerta}</span> },
  { header: "Acopiador", cell: (r) => <span className="text-text-muted">{r.acopiador}</span> },
  { header: "Cal", numeric: true, width: "80px", cell: (r) => r.cal },
  { header: "$/kg", numeric: true, width: "120px", cell: (r) => mxn(r.precio) },
  {
    header: "Estado",
    width: "160px",
    cell: (r) => (
      <Badge tone={r.estado.tone} dot>
        {r.estado.label}
      </Badge>
    ),
  },
];

export default function DesignSystemPage() {
  const [selected, setSelected] = React.useState("1");

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      {/* Encabezado */}
      <header className="mb-10 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <span className="flex size-9 items-center justify-center rounded-md bg-brand text-brand-contrast">
            <Leaf weight="fill" size={20} />
          </span>
          <div>
            <h1 className="text-h2 font-semibold tracking-tight text-text-primary">
              AgroMesh
            </h1>
            <p className="text-caption text-text-muted">
              Sistema de diseño v1.0 · cliente Avoolio
            </p>
          </div>
        </div>
        <ThemeToggle />
      </header>

      <div className="flex flex-col gap-12">
        {/* Color */}
        <Section title="Color">
          <p className="text-caption font-medium uppercase tracking-wide text-text-faint">
            Marca · el verde es atención, nunca fondo (salvo el CTA primario)
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Swatch name="Brand green" hex="#65E06F" className="bg-brand" />
            <Swatch name="Brand contrast" hex="sobre verde" className="bg-brand-contrast" />
            <Swatch name="MESH (IA)" hex="#5DD3F0" className="bg-mesh" />
            <Swatch name="Borde" hex="var(--border)" className="bg-border" />
          </div>

          <p className="mt-2 text-caption font-medium uppercase tracking-wide text-text-faint">
            Semántico · siempre con texto/icono, el color nunca es la única señal
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Swatch name="success" hex="#48C281" className="bg-success" />
            <Swatch name="warning" hex="#F2B040" className="bg-warning" />
            <Swatch name="danger" hex="#E06058" className="bg-danger" />
            <Swatch name="info" hex="#5A9FE0" className="bg-info" />
          </div>

          <p className="mt-2 text-caption font-medium uppercase tracking-wide text-text-faint">
            Superficies · se apilan, no flotan (sin gradientes)
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Swatch name="bg-default" hex="#080F12" className="bg-bg-default" />
            <Swatch name="bg-raised" hex="#13181C" className="bg-bg-raised" />
            <Swatch name="bg-hover" hex="#1A2024" className="bg-bg-hover" />
            <Swatch name="bg-active" hex="#222A30" className="bg-bg-active" />
          </div>
        </Section>

        {/* Tipografía */}
        <Section title="Tipografía">
          <div className="flex flex-col gap-3">
            <p className="text-display font-semibold tracking-tight text-text-primary">
              1,247 kg <span className="text-text-faint">display · 40</span>
            </p>
            <p className="text-h1 font-semibold text-text-primary">
              Pendientes <span className="text-caption text-text-faint">h1 · 30</span>
            </p>
            <p className="text-h2 font-semibold text-text-primary">
              Acuerdos abiertos <span className="text-caption text-text-faint">h2 · 24</span>
            </p>
            <p className="text-h3 font-medium text-text-primary">
              La Esperanza <span className="text-caption text-text-faint">h3 · 20</span>
            </p>
            <p className="text-body text-text-primary">
              Cuerpo del producto. <span className="text-caption text-text-faint">body · 15</span>
            </p>
            <p className="text-ui text-text-muted">
              Fila de tabla densa. <span className="text-caption text-text-faint">ui · 13</span>
            </p>
            <p className="text-caption text-text-faint">
              Texto de ayuda · caption · 12
            </p>
            <p className="mt-2 font-mono text-body text-text-primary">
              {mxn(38.5)} · {usd(34, "caja")} ·{" "}
              <span className="text-success">{delta(5.2)}</span> ·{" "}
              <span className="text-danger">{delta(-3.1)}</span>
              <span className="ml-2 text-caption text-text-faint">
                JetBrains Mono · tabular · tracking-tight
              </span>
            </p>
          </div>
        </Section>

        {/* Botones */}
        <Section title="Botones">
          <p className="text-caption text-text-muted">
            Un primario por pantalla. Press por capa de fondo, no por movimiento.
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Button variant="default">
              <Check weight="bold" /> Aprobar
            </Button>
            <Button variant="secondary">Modificar</Button>
            <Button variant="ghost">Cancelar</Button>
            <Button variant="destructive">Rechazar</Button>
            <Button variant="default" disabled>
              Deshabilitado
            </Button>
          </div>
        </Section>

        {/* Badges */}
        <Section title="Badges / píldoras de estado">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="brand" dot>verificada</Badge>
            <Badge tone="warning" dot>sobrecompra</Badge>
            <Badge tone="danger" dot>fuera de margen</Badge>
            <Badge tone="info" dot>abierta</Badge>
            <Badge tone="success" dot>acordada</Badge>
            <Badge tone="neutral">grade A</Badge>
            <Badge tone="neutral">grade B</Badge>
            <Badge tone="neutral">grade C</Badge>
          </div>
        </Section>

        {/* Inputs */}
        <Section title="Inputs y estados de error">
          <div className="grid max-w-md gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="hue">Código HUE</Label>
              <Input id="hue" defaultValue="HUE08160530011" className="font-mono" />
            </div>
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="precio">Precio MXN/kg</Label>
              <Input id="precio" defaultValue="42.00" aria-invalid className="font-mono" />
              {/* Error inline en el propio elemento, nunca en un toast. */}
              <p className="text-caption text-danger" role="alert">
                Fuera de banda. Requiere aprobación del supervisor.
              </p>
            </div>
          </div>
        </Section>

        {/* Tarjetas */}
        <Section title="Tarjetas — borde de 1px, sin sombra">
          <div className="grid gap-4 sm:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Pérdida por sobreestimación</CardTitle>
                <CardAction>
                  <Button variant="ghost" className="h-7 px-2 text-caption">
                    Ver detalle
                  </Button>
                </CardAction>
              </CardHeader>
              <CardContent>
                <p className="font-mono text-display font-semibold tracking-tight text-danger">
                  {mxn(148300, 0)}
                </p>
                <p className="mt-1 text-caption text-text-muted">
                  MXN · últimos 7 días ·{" "}
                  <span className="text-danger">{delta(-12.4)}</span> vs semana
                  anterior
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Capacidad de empaque · hoy</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="font-mono text-display font-semibold tracking-tight text-text-primary">
                  37.5 <span className="text-h3 text-text-faint">/ 50 ton</span>
                </p>
                <p className="mt-1 text-caption text-text-muted">
                  75% · cierre cerca de 80%
                </p>
              </CardContent>
            </Card>
          </div>
        </Section>

        {/* Tabla densa */}
        <Section title="Tabla densa — la superficie firma">
          <p className="text-caption text-text-muted">
            Rejilla 1px · filas 36px · números en mono · borde izq 2px verde en la
            fila seleccionada (haz clic).
          </p>
          <DataTable
            columns={COLUMNS}
            rows={ROWS}
            rowKey={(r) => r.id}
            selectedKey={selected}
            onRowClick={(r) => setSelected(r.id)}
          />
        </Section>

        {/* Modal */}
        <Section title="Modal — la única superficie con sombra">
          <p className="text-caption text-text-muted">
            Cancelar a la izquierda, confirmar a la derecha. <kbd>esc</kbd> cierra.
          </p>
          <Dialog>
            <DialogTrigger
              render={<Button variant="secondary">Aprobar precio fuera de margen</Button>}
            />
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Aprobar precio fuera de margen</DialogTitle>
                <DialogDescription>
                  Cal 48 · <span className="font-mono">{mxn(42)}/kg</span> · banda 8
                  (fuera de margen). Ingresa tu PIN de WhatsApp para confirmar.
                </DialogDescription>
              </DialogHeader>
              <Input placeholder="• • • •" className="text-center font-mono tracking-[0.5em]" />
              <DialogFooter>
                <DialogClose render={<Button variant="ghost">Cancelar</Button>} />
                <DialogClose render={<Button variant="default">Aprobar</Button>} />
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </Section>
      </div>

      <footer className="mt-16 border-t border-border pt-4 text-caption text-text-faint">
        AgroMesh · sistema de diseño v1.0 · tokens bloqueados · modo oscuro por
        defecto
      </footer>
    </main>
  );
}
