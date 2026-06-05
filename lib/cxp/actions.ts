"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { cxpEditSchema, ESTADOS_REQUIEREN_FACTURA } from "./schema";

export type ActionResult = { ok: true } | { ok: false; error: string };

/** Actualiza una obligación de CxP. Re-valida el candado de factura en server. */
export async function guardarCxp(id: string, input: unknown): Promise<ActionResult> {
  const parsed = cxpEditSchema.safeParse(input);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    return { ok: false, error: first?.message ?? "Datos inválidos" };
  }
  const d = parsed.data;

  // Candado de factura (defensa en server, no solo en el form).
  if (ESTADOS_REQUIEREN_FACTURA.includes(d.estado) && !d.factura) {
    return { ok: false, error: "Candado de factura: registra el CFDI antes de pagar." };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .from("cxp")
    .update({
      factura: d.factura ?? null,
      monto: d.monto ?? null,
      estado: d.estado,
      forma_pago: d.forma_pago ?? null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", id);

  if (error) return { ok: false, error: error.message };

  revalidatePath("/cxp");
  return { ok: true };
}
