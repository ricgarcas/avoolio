/* Tipos y metadatos del slice de acopio — client-safe (sin imports de server).
   La query vive en `lib/acopio-queries.ts` (server-only). */

export type PendienteTipo = "fuera_margen" | "coyote" | "modificacion";

export interface Pendiente {
  id: string;
  createdAt: string; // ISO
  codigoHue: string;
  huerta: string;
  empacadora: string;
  productor: string;
  acopio: string | null;
  acopiador: string | null;
  variedad: string;
  calibre: number | null;
  banda: number | null;
  precioPropuesto: number;
  precioBandaMax: number | null;
  volumenKg: number | null;
  margenPct: number | null;
  tipo: PendienteTipo;
  razonHitl: string;
}

/** Metadatos de presentación por tipo de Pendiente (etiqueta + tono semántico).
   El color nunca es la única señal: siempre acompaña la etiqueta. */
export const TIPO_META: Record<
  PendienteTipo,
  { label: string; tone: "danger" | "warning" | "info" }
> = {
  fuera_margen: { label: "fuera de margen", tone: "danger" },
  coyote: { label: "coyote", tone: "warning" },
  modificacion: { label: "modificación", tone: "info" },
};
