"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { corteSchema } from "./schema";

export type ActionResult = { ok: true } | { ok: false; error: string };

/** Programa (alta) o actualiza un corte en public.corte. */
export async function guardarCorte(input: unknown, id?: string): Promise<ActionResult> {
  const parsed = corteSchema.safeParse(input);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    return { ok: false, error: first ? `${first.path.join(".")}: ${first.message}` : "Datos inválidos" };
  }

  const supabase = await createClient();
  const payload = { ...parsed.data, updated_at: new Date().toISOString() };

  const { error } = id
    ? await supabase.from("corte").update(payload).eq("id", id)
    : await supabase.from("corte").insert(payload);

  if (error) return { ok: false, error: error.message };

  revalidatePath("/cortes");
  revalidatePath("/");
  return { ok: true };
}
