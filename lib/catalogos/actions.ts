"use server";

import { revalidatePath, revalidateTag } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { CATALOGOS_TAG } from "@/lib/supabase/read";
import { SCHEMAS, type CatalogoDef } from "./schema";

/* Server actions de catálogos: validan con el mismo esquema zod (server-side,
   nunca confíes en el cliente) y escriben a `public` vía supabase-js. Una sola
   action genérica, con allowlist de tablas para evitar inyección de tabla. */

export type ActionResult = { ok: true } | { ok: false; error: string };

type Tabla = CatalogoDef["table"];

const TABLAS: Tabla[] = ["huerta", "productor", "acopiador", "cuadrilla", "acarreador"];

/** Crea (id undefined) o actualiza (id presente) una fila de catálogo. */
export async function guardarCatalogo(
  tabla: Tabla,
  input: unknown,
  id?: string,
): Promise<ActionResult> {
  if (!TABLAS.includes(tabla)) return { ok: false, error: "Tabla no permitida" };

  const parsed = SCHEMAS[tabla].safeParse(input);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    return { ok: false, error: first ? `${first.path.join(".")}: ${first.message}` : "Datos inválidos" };
  }

  const supabase = await createClient();
  const payload = { ...parsed.data, updated_at: new Date().toISOString() };

  // payload es unión de los 5 esquemas; la tabla ya está en allowlist.
  const { error } = id
    ? await supabase.from(tabla).update(payload as never).eq("id", id)
    : await supabase.from(tabla).insert(payload as never);

  if (error) return { ok: false, error: error.message };

  revalidateTag(CATALOGOS_TAG);
  revalidatePath("/catalogos");
  revalidatePath("/");
  return { ok: true };
}

export async function eliminarCatalogo(tabla: Tabla, id: string): Promise<ActionResult> {
  if (!TABLAS.includes(tabla)) return { ok: false, error: "Tabla no permitida" };
  const supabase = await createClient();
  const { error } = await supabase.from(tabla).delete().eq("id", id);
  if (error) return { ok: false, error: error.message };
  revalidateTag(CATALOGOS_TAG);
  revalidatePath("/catalogos");
  revalidatePath("/");
  return { ok: true };
}
