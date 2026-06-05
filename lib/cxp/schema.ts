/* CxP — tipos, metadatos y esquema de edición (client-safe).
   El candado de factura vive aquí (puedePagar) y se re-valida en la action. */
import { z } from "zod";

export type CxpTipo = "productor" | "servicio_corte" | "acarreo" | "comision_acopio";
export type CxpEstado = "borrador" | "validada" | "autorizada" | "pagada" | "conciliada";

export interface Cxp {
  id: string;
  tipo: CxpTipo;
  origen?: string;
  beneficiario?: string;
  huerta?: string;
  lote?: string;
  ordenCompra?: string;
  fecha?: string;
  semana: number | null;
  kilos?: number;
  monto?: number;
  factura?: string;
  estado: CxpEstado;
  formaPago?: string;
  /** El monto se derivó de la tarifa del catálogo (no del Total de Monday). */
  montoEstimado?: boolean;
}

export const TIPO_META: Record<CxpTipo, { label: string; short: string }> = {
  productor: { label: "Productor", short: "Productor" },
  servicio_corte: { label: "Servicio de corte", short: "Corte" },
  acarreo: { label: "Acarreo", short: "Acarreo" },
  comision_acopio: { label: "Comisión de acopio", short: "Comisión" },
};

export const ESTADO_META: Record<
  CxpEstado,
  { label: string; tone: "neutral" | "info" | "brand" | "success" }
> = {
  borrador: { label: "Borrador", tone: "neutral" },
  validada: { label: "Validada", tone: "info" },
  autorizada: { label: "Autorizada", tone: "brand" },
  pagada: { label: "Pagada", tone: "success" },
  conciliada: { label: "Conciliada", tone: "success" },
};

/** Estados que exigen factura (el candado). */
export const ESTADOS_REQUIEREN_FACTURA: CxpEstado[] = ["pagada", "conciliada"];

/** ¿La obligación puede avanzar a pagada? Solo si tiene factura (CFDI). */
export const puedePagar = (c: Pick<Cxp, "factura">) => Boolean(c.factura && c.factura.trim());

// ── edición ─────────────────────────────────────────────────────────────────
const opt = z.preprocess(
  (v) => (typeof v === "string" && v.trim() === "" ? undefined : v),
  z.string().trim().optional(),
);
const optNum = z.preprocess(
  (v) => (v === "" || v == null ? undefined : Number(v)),
  z.number().optional(),
);

export const cxpEditSchema = z
  .object({
    factura: opt,
    monto: optNum,
    estado: z.enum(["borrador", "validada", "autorizada", "pagada", "conciliada"]),
    forma_pago: opt,
  })
  .refine((d) => !ESTADOS_REQUIEREN_FACTURA.includes(d.estado) || Boolean(d.factura), {
    message: "Candado de factura: registra el CFDI antes de marcar pagada/conciliada.",
    path: ["estado"],
  });

export type CxpEditInput = z.infer<typeof cxpEditSchema>;
