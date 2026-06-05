import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Pendiente, PendienteTipo } from "@/lib/acopio";

/* Queries del slice de acopio. Lee de `public` con supabase-js (el camino
   correcto: respeta RLS, una sola key). Hoy apunta a `public.pendiente_hitl`
   (aplanado provisional). Cuando exista el modelo public completo, solo cambia
   la query de aquí — la UI no se entera. */

type Row = {
  id: string;
  created_at: string;
  codigo_hue: string;
  huerta: string;
  empacadora: string;
  productor: string;
  acopio: string | null;
  acopiador: string | null;
  variedad: string;
  calibre: number | null;
  banda: number | null;
  precio_propuesto_mxn_kg: number | string;
  precio_banda_max_mxn_kg: number | string | null;
  volumen_acordado_kg: number | string | null;
  margen_pct: number | string | null;
  tipo: PendienteTipo;
  razon_hitl: string;
};

const num = (v: number | string | null): number | null =>
  v == null ? null : typeof v === "number" ? v : Number(v);

/** Cola de Pendientes (HITL) ordenada por antigüedad descendente. */
export async function getPendientes(): Promise<Pendiente[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("pendiente_hitl")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(1000); // Tope de seguridad mientras no haya paginación server-side.

  if (error) {
    console.error("getPendientes:", error.message);
    return [];
  }

  return (data as Row[]).map((r) => ({
    id: r.id,
    createdAt: r.created_at,
    codigoHue: r.codigo_hue,
    huerta: r.huerta,
    empacadora: r.empacadora,
    productor: r.productor,
    acopio: r.acopio,
    acopiador: r.acopiador,
    variedad: r.variedad,
    calibre: r.calibre,
    banda: r.banda,
    precioPropuesto: num(r.precio_propuesto_mxn_kg)!,
    precioBandaMax: num(r.precio_banda_max_mxn_kg),
    volumenKg: num(r.volumen_acordado_kg),
    margenPct: num(r.margen_pct),
    tipo: r.tipo,
    razonHitl: r.razon_hitl,
  }));
}
