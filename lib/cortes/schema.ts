/* Cortes — tipos, esquema zod (programar/editar) y metadatos (client-safe).
   Queries en ./queries (server-only), mutaciones en ./actions. */
import { z } from "zod";

const opt = z.preprocess(
  (v) => (typeof v === "string" && v.trim() === "" ? undefined : v),
  z.string().trim().optional(),
);
const optInt = z.preprocess(
  (v) => (v === "" || v == null ? undefined : Number(v)),
  z.number().int().optional(),
);
const optNum = z.preprocess(
  (v) => (v === "" || v == null ? undefined : Number(v)),
  z.number().optional(),
);

export const ESTADOS = ["registrado", "en_espera", "confirmado", "cancelado"] as const;
export type Estado = (typeof ESTADOS)[number];

export const corteSchema = z.object({
  huerto: z.string().trim().min(1, "Requerido"),
  productor: opt,
  municipio: opt,
  asnm: optInt,
  tipo_corte: opt,
  empresa_corte: opt,
  acopio: opt,
  bascula: opt,
  punto_reunion: opt,
  camion: opt,
  precio_pactado: optNum,
  programado: opt,
  estado: z.enum(ESTADOS),
});

export type CorteInput = z.infer<typeof corteSchema>;

export interface Corte extends CorteInput {
  id: string;
  semana: number | null;
  floracion?: string;
  visita1?: string;
  visita2?: string;
}

/** Umbral de altura: por debajo, riesgo de gusano barrenador → supervisión. */
export const ALTURA_MIN = 2100;

export const ESTADO_META: Record<
  Estado,
  { label: string; tone: "neutral" | "warning" | "success" | "danger" }
> = {
  registrado: { label: "Registrado", tone: "neutral" },
  en_espera: { label: "En espera", tone: "warning" },
  confirmado: { label: "Confirmado", tone: "success" },
  cancelado: { label: "Cancelado", tone: "danger" },
};

export type Grupo = "alerta" | Estado;

/** La alerta de altura manda sobre el estado (es señal de supervisión). */
export function grupoDe(c: Pick<Corte, "asnm" | "estado">): Grupo {
  if (c.asnm != null && c.asnm < ALTURA_MIN) return "alerta";
  return c.estado;
}

export const GRUPO_META: Record<Grupo, { title: string; tone: "danger" | "neutral" | "warning" | "success" }> = {
  alerta: { title: `Alerta de altura · <${ALTURA_MIN} msnm`, tone: "danger" },
  confirmado: { title: "Confirmados", tone: "success" },
  en_espera: { title: "En espera", tone: "warning" },
  registrado: { title: "Registrados", tone: "neutral" },
  cancelado: { title: "Cancelados", tone: "neutral" },
};

/** Orden de aparición de los grupos. */
export const GRUPO_ORDER: Grupo[] = ["alerta", "confirmado", "en_espera", "registrado", "cancelado"];
