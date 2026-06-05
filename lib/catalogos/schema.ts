/* Catálogos — fuente única de verdad (client-safe).
 *
 * Cada catálogo define: su tabla en `public`, etiquetas, un esquema zod (valida
 * en cliente y servidor) y la config de campos del formulario. Las queries
 * (server-only) viven en ./queries y las mutaciones en ./actions; ambas
 * reusan estos esquemas. La UI no toca SQL.
 */
import { z } from "zod";

// ── helpers ─────────────────────────────────────────────────────────────────
/** Texto opcional: "" del form → undefined. */
const opt = z.preprocess(
  (v) => (typeof v === "string" && v.trim() === "" ? undefined : v),
  z.string().trim().optional(),
);
/** Entero opcional desde input (string) → number | undefined. */
const optInt = z.preprocess(
  (v) => (v === "" || v == null ? undefined : Number(v)),
  z.number().int().optional(),
);
/** Decimal opcional. */
const optNum = z.preprocess(
  (v) => (v === "" || v == null ? undefined : Number(v)),
  z.number().optional(),
);
const req = z.string().trim().min(1, "Requerido");

// ── esquemas ────────────────────────────────────────────────────────────────
export const huertaSchema = z.object({
  hue: req,
  nombre: req,
  productor_id: opt,
  municipio: opt,
  altura: optInt,
  punto_reunion: opt,
  bascula: opt,
});

export const productorSchema = z.object({
  nombre: req,
  rfc: opt,
  municipio: opt,
  tel: opt,
  correo: z.preprocess(
    (v) => (typeof v === "string" && v.trim() === "" ? undefined : v),
    z.string().email("Correo inválido").optional(),
  ),
  beneficiario: opt,
  dias_credito: optInt,
});

export const acopiadorSchema = z.object({
  nombre: req,
  whatsapp: opt,
  zona: opt,
  estatus: z.enum(["autorizado", "pendiente", "suspendido", "temporal"]),
});

export const cuadrillaSchema = z.object({
  nombre: req,
  tipo: z.enum(["propia", "externa"]),
  tarifa_kg: optNum,
  tarifa_dia: optNum,
});

export const acarreadorSchema = z.object({
  nombre: req,
  tipo_unidad: opt,
  tarifa_viaje: optNum,
});

export type HuertaInput = z.infer<typeof huertaSchema>;
export type ProductorInput = z.infer<typeof productorSchema>;
export type AcopiadorInput = z.infer<typeof acopiadorSchema>;
export type CuadrillaInput = z.infer<typeof cuadrillaSchema>;
export type AcarreadorInput = z.infer<typeof acarreadorSchema>;

// ── filas (lo que devuelven las queries; incluye id + joins) ─────────────────
export interface Huerta extends HuertaInput {
  id: string;
  productorNombre: string | null;
}
export interface Productor extends ProductorInput {
  id: string;
  huertasCount: number;
}
export interface Acopiador extends AcopiadorInput {
  id: string;
}
export interface Cuadrilla extends CuadrillaInput {
  id: string;
}
export interface Acarreador extends AcarreadorInput {
  id: string;
}

// ── config de formularios ───────────────────────────────────────────────────
export type FieldType = "text" | "number" | "tel" | "email" | "select";

export interface Field {
  name: string;
  label: string;
  type: FieldType;
  required?: boolean;
  placeholder?: string;
  mono?: boolean;
  /** Opciones estáticas para select. */
  options?: { value: string; label: string }[];
  /** Clave de opciones resueltas en runtime (ej. "productores"). */
  optionsKey?: string;
  /** Ancho en la rejilla de 2 columnas. */
  span?: 1 | 2;
}

/** Una entrada del registro de catálogos. `table` apunta a `public.<table>`. */
export interface CatalogoDef {
  key: string;
  table: "huerta" | "productor" | "acopiador" | "cuadrilla" | "acarreador";
  singular: string;
  plural: string;
  fields: Field[];
}

const ESTATUS_OPTS = [
  { value: "autorizado", label: "Autorizado" },
  { value: "pendiente", label: "Pendiente" },
  { value: "suspendido", label: "Suspendido" },
  { value: "temporal", label: "Temporal" },
];

export const CATALOGOS: Record<string, CatalogoDef> = {
  huertas: {
    key: "huertas",
    table: "huerta",
    singular: "Huerta",
    plural: "Huertas",
    fields: [
      { name: "hue", label: "Código HUE", type: "text", required: true, mono: true, placeholder: "HUE…", span: 1 },
      { name: "nombre", label: "Nombre de la huerta", type: "text", required: true, span: 1 },
      { name: "productor_id", label: "Productor", type: "select", optionsKey: "productores", span: 2 },
      { name: "municipio", label: "Municipio", type: "text", span: 1 },
      { name: "altura", label: "Altura (msnm)", type: "number", mono: true, placeholder: "ej. 2210", span: 1 },
      { name: "bascula", label: "Báscula", type: "text", span: 1 },
      { name: "punto_reunion", label: "Punto de reunión", type: "text", span: 2 },
    ],
  },
  productores: {
    key: "productores",
    table: "productor",
    singular: "Productor",
    plural: "Productores",
    fields: [
      { name: "nombre", label: "Nombre / razón social", type: "text", required: true, span: 2 },
      { name: "rfc", label: "RFC", type: "text", mono: true, span: 1 },
      { name: "municipio", label: "Municipio", type: "text", span: 1 },
      { name: "tel", label: "Teléfono", type: "tel", mono: true, span: 1 },
      { name: "correo", label: "Correo", type: "email", span: 1 },
      { name: "beneficiario", label: "Beneficiario (pago)", type: "text", span: 1 },
      { name: "dias_credito", label: "Días de crédito", type: "number", mono: true, span: 1 },
    ],
  },
  acopiadores: {
    key: "acopiadores",
    table: "acopiador",
    singular: "Acopiador",
    plural: "Acopiadores",
    fields: [
      { name: "nombre", label: "Nombre", type: "text", required: true, span: 1 },
      { name: "estatus", label: "Estatus", type: "select", options: ESTATUS_OPTS, span: 1 },
      { name: "whatsapp", label: "WhatsApp", type: "tel", mono: true, span: 1 },
      { name: "zona", label: "Zona", type: "text", span: 1 },
    ],
  },
  cuadrillas: {
    key: "cuadrillas",
    table: "cuadrilla",
    singular: "Cuadrilla",
    plural: "Cuadrillas / empresas de corte",
    fields: [
      { name: "nombre", label: "Empresa / cuadrilla", type: "text", required: true, span: 2 },
      {
        name: "tipo",
        label: "Tipo",
        type: "select",
        options: [
          { value: "propia", label: "Propia" },
          { value: "externa", label: "Externa" },
        ],
        span: 2,
      },
      { name: "tarifa_kg", label: "Tarifa $/kg", type: "number", mono: true, span: 1 },
      { name: "tarifa_dia", label: "Tarifa $/día", type: "number", mono: true, span: 1 },
    ],
  },
  acarreadores: {
    key: "acarreadores",
    table: "acarreador",
    singular: "Acarreador",
    plural: "Proveedores de acarreo",
    fields: [
      { name: "nombre", label: "Proveedor", type: "text", required: true, span: 2 },
      { name: "tipo_unidad", label: "Tipo de unidad", type: "text", placeholder: "Torton, Rabón…", span: 1 },
      { name: "tarifa_viaje", label: "Tarifa $/viaje", type: "number", mono: true, span: 1 },
    ],
  },
};

export const SCHEMAS = {
  huerta: huertaSchema,
  productor: productorSchema,
  acopiador: acopiadorSchema,
  cuadrilla: cuadrillaSchema,
  acarreador: acarreadorSchema,
} as const;
