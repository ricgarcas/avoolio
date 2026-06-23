"use server";

import { revalidatePath } from "next/cache";
import { query } from "@/lib/db";

type Decision = "confirmado" | "rechazado" | "saltado";

export async function decidirReconciliacion(monday_hue: string, decision: Decision) {
  const status = decision === "saltado" ? "pendiente" : decision;
  const reviewed = decision === "saltado" ? null : "ricardo";
  await query(
    `update acopio.huerta_reconciliacion
       set status = $2,
           reviewed_by = $3,
           reviewed_at = case when $2 = 'pendiente' then null else now() end,
           updated_at = now()
     where monday_hue = $1`,
    [monday_hue, status, reviewed],
  );
  revalidatePath("/sicoa-review");
}
