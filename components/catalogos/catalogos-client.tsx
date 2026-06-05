"use client";

import * as React from "react";

import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { CatalogoCrud } from "./catalogo-crud";
import type { Column } from "@/components/ui/data-table";
import type {
  Huerta,
  Productor,
  Acopiador,
  Cuadrilla,
  Acarreador,
} from "@/lib/catalogos/schema";

/* Catálogos: pestañas sobre los 5 catálogos maestros. Cada uno define sus
   columnas (con render propio: badges, alertas, mono) y reusa <CatalogoCrud>
   para tabla + alta/edición. Los datos llegan del servidor. */

type Opt = { value: string; label: string };
const peso = (v?: number, dec = 2) =>
  v == null ? "—" : `$${v.toLocaleString("es-MX", { minimumFractionDigits: dec, maximumFractionDigits: dec })}`;
const str = (v: unknown) => (v == null ? "" : String(v));

const ESTATUS_TONE = {
  autorizado: "success",
  pendiente: "warning",
  suspendido: "danger",
  temporal: "info",
} as const;

export function CatalogosClient({
  huertas,
  productores,
  acopiadores,
  cuadrillas,
  acarreadores,
  productorOptions,
}: {
  huertas: Huerta[];
  productores: Productor[];
  acopiadores: Acopiador[];
  cuadrillas: Cuadrilla[];
  acarreadores: Acarreador[];
  productorOptions: Opt[];
}) {
  const tabs = [
    { key: "huertas", label: "Huertas", n: huertas.length },
    { key: "productores", label: "Productores", n: productores.length },
    { key: "acopiadores", label: "Acopiadores", n: acopiadores.length },
    { key: "cuadrillas", label: "Cuadrillas", n: cuadrillas.length },
    { key: "acarreadores", label: "Acarreadores", n: acarreadores.length },
  ] as const;
  const [tab, setTab] = React.useState<(typeof tabs)[number]["key"]>("huertas");

  // ── columnas ──────────────────────────────────────────────────────────────
  const huertaCols: Column<Huerta>[] = [
    { header: "HUE", width: "160px", cell: (r) => <span className="font-mono text-caption text-text-muted">{r.hue}</span> },
    { header: "Huerta", cell: (r) => <span className="font-medium text-text-primary">{r.nombre}</span> },
    { header: "Productor", cell: (r) => r.productorNombre ?? <span className="text-text-faint">—</span> },
    { header: "Municipio", cell: (r) => r.municipio ?? "—" },
    {
      header: "Altura",
      numeric: true,
      cell: (r) =>
        r.altura == null ? (
          <span className="text-text-faint">—</span>
        ) : r.altura < 2100 ? (
          <span className="text-danger">{r.altura.toLocaleString("es-MX")} ⚠</span>
        ) : (
          r.altura.toLocaleString("es-MX")
        ),
    },
    { header: "Báscula", cell: (r) => r.bascula ?? "—" },
  ];

  const productorCols: Column<Productor>[] = [
    { header: "Productor", cell: (r) => <span className="font-medium text-text-primary">{r.nombre}</span> },
    { header: "RFC", cell: (r) => <span className="font-mono text-caption text-text-muted">{r.rfc ?? "—"}</span> },
    { header: "Municipio", cell: (r) => r.municipio ?? "—" },
    { header: "Teléfono", cell: (r) => <span className="font-mono text-caption">{r.tel ?? "—"}</span> },
    { header: "Huertas", numeric: true, cell: (r) => r.huertasCount },
  ];

  const acopiadorCols: Column<Acopiador>[] = [
    { header: "Acopiador", cell: (r) => <span className="font-medium text-text-primary">{r.nombre}</span> },
    {
      header: "Estatus",
      cell: (r) => (
        <Badge tone={ESTATUS_TONE[r.estatus]} dot>
          {r.estatus}
        </Badge>
      ),
    },
    { header: "WhatsApp", cell: (r) => <span className="font-mono text-caption">{r.whatsapp ?? "—"}</span> },
    { header: "Zona", cell: (r) => r.zona ?? "—" },
  ];

  const cuadrillaCols: Column<Cuadrilla>[] = [
    { header: "Empresa / cuadrilla", cell: (r) => <span className="font-medium text-text-primary">{r.nombre}</span> },
    { header: "Tipo", cell: (r) => <Badge tone={r.tipo === "propia" ? "brand" : "neutral"}>{r.tipo}</Badge> },
    { header: "Tarifa $/kg", numeric: true, cell: (r) => peso(r.tarifa_kg) },
    { header: "Tarifa $/día", numeric: true, cell: (r) => peso(r.tarifa_dia, 0) },
  ];

  const acarreadorCols: Column<Acarreador>[] = [
    { header: "Proveedor", cell: (r) => <span className="font-medium text-text-primary">{r.nombre}</span> },
    { header: "Tipo de unidad", cell: (r) => r.tipo_unidad ?? "—" },
    { header: "Tarifa $/viaje", numeric: true, cell: (r) => peso(r.tarifa_viaje, 0) },
  ];

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-h1 font-semibold text-text-primary">Catálogos</h1>
        <p className="text-caption text-text-muted">
          Base maestra del acopio · importada de Monday · editable
        </p>
      </div>

      {/* Pestañas */}
      <div className="flex gap-1 border-b border-border">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={cn(
              "flex items-center gap-1.5 border-b-2 px-3 py-2 text-ui transition-colors",
              tab === t.key
                ? "border-b-brand text-text-primary"
                : "border-b-transparent text-text-muted hover:text-text-primary",
            )}
          >
            {t.label}
            <span className="font-mono text-caption tabular-nums text-text-faint">{t.n}</span>
          </button>
        ))}
      </div>

      {tab === "huertas" && (
        <CatalogoCrud
          catalogo="huertas"
          columns={huertaCols}
          rows={huertas}
          options={{ productores: productorOptions }}
          search={(r) => `${r.hue} ${r.nombre} ${r.productorNombre ?? ""} ${r.municipio ?? ""}`}
          toDefaults={(r) => ({
            hue: str(r?.hue),
            nombre: str(r?.nombre),
            productor_id: str(r?.productor_id),
            municipio: str(r?.municipio),
            altura: str(r?.altura),
            bascula: str(r?.bascula),
            punto_reunion: str(r?.punto_reunion),
          })}
        />
      )}
      {tab === "productores" && (
        <CatalogoCrud
          catalogo="productores"
          columns={productorCols}
          rows={productores}
          search={(r) => `${r.nombre} ${r.rfc ?? ""} ${r.municipio ?? ""}`}
          toDefaults={(r) => ({
            nombre: str(r?.nombre),
            rfc: str(r?.rfc),
            municipio: str(r?.municipio),
            tel: str(r?.tel),
            correo: str(r?.correo),
            beneficiario: str(r?.beneficiario),
            dias_credito: str(r?.dias_credito),
          })}
        />
      )}
      {tab === "acopiadores" && (
        <CatalogoCrud
          catalogo="acopiadores"
          columns={acopiadorCols}
          rows={acopiadores}
          search={(r) => `${r.nombre} ${r.zona ?? ""}`}
          toDefaults={(r) => ({
            nombre: str(r?.nombre),
            estatus: r?.estatus ?? "autorizado",
            whatsapp: str(r?.whatsapp),
            zona: str(r?.zona),
          })}
        />
      )}
      {tab === "cuadrillas" && (
        <CatalogoCrud
          catalogo="cuadrillas"
          columns={cuadrillaCols}
          rows={cuadrillas}
          search={(r) => r.nombre}
          toDefaults={(r) => ({
            nombre: str(r?.nombre),
            tipo: r?.tipo ?? "externa",
            tarifa_kg: str(r?.tarifa_kg),
            tarifa_dia: str(r?.tarifa_dia),
          })}
        />
      )}
      {tab === "acarreadores" && (
        <CatalogoCrud
          catalogo="acarreadores"
          columns={acarreadorCols}
          rows={acarreadores}
          search={(r) => `${r.nombre} ${r.tipo_unidad ?? ""}`}
          toDefaults={(r) => ({
            nombre: str(r?.nombre),
            tipo_unidad: str(r?.tipo_unidad),
            tarifa_viaje: str(r?.tarifa_viaje),
          })}
        />
      )}
    </div>
  );
}
