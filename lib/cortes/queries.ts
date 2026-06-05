import "server-only";
import { unstable_cache } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { createReadClient, CATALOGOS_TAG } from "@/lib/supabase/read";
import type { Corte, Estado } from "./schema";

/* Queries de cortes. La lista (public.corte) se lee dinámica con sesión; las
   lecturas de catálogo (huerta/cuadrilla/acopiador) van cacheadas bajo el tag
   `catalogos`, así que se tiran solo cuando se edita un catálogo. */

/** Tope de filas por lista — red de seguridad mientras no haya paginación
   server-side. Cuando una tabla se acerque, migramos a `.range()`. */
const LIST_LIMIT = 1000;

const n = (v: number | string | null): number | null =>
  v == null ? null : typeof v === "number" ? v : Number(v);

export async function getCortes(): Promise<Corte[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("corte")
    .select(
      "id, programado, semana, huerto, productor, municipio, asnm, tipo_corte, floracion, camion, acopio, bascula, punto_reunion, empresa_corte, precio_pactado, estado, visita1, visita2",
    )
    .order("programado", { ascending: false, nullsFirst: false })
    .limit(LIST_LIMIT);

  if (error) {
    console.error("getCortes:", error.message);
    return [];
  }

  return (data ?? []).map((r) => ({
    id: r.id,
    programado: r.programado ?? undefined,
    semana: r.semana ?? null,
    huerto: r.huerto,
    productor: r.productor ?? undefined,
    municipio: r.municipio ?? undefined,
    asnm: n(r.asnm) ?? undefined,
    tipo_corte: r.tipo_corte ?? undefined,
    floracion: r.floracion ?? undefined,
    camion: r.camion ?? undefined,
    acopio: r.acopio ?? undefined,
    bascula: r.bascula ?? undefined,
    punto_reunion: r.punto_reunion ?? undefined,
    empresa_corte: r.empresa_corte ?? undefined,
    precio_pactado: n(r.precio_pactado) ?? undefined,
    estado: r.estado as Estado,
    visita1: r.visita1 ?? undefined,
    visita2: r.visita2 ?? undefined,
  }));
}

/** Huertas del catálogo, enriquecidas para autollenar al programar un corte. */
export const getHuertasParaCorte = unstable_cache(
  async (): Promise<{ id: string; nombre: string; productor: string | null; municipio: string | null }[]> => {
    const supabase = createReadClient();
    const { data } = await supabase
      .from("huerta")
      .select("id, nombre, municipio, productor:productor_id(nombre)")
      .order("nombre")
      .limit(LIST_LIMIT);
    return (data ?? []).map((h) => {
      const prod = h.productor as { nombre: string } | { nombre: string }[] | null;
      const productor = Array.isArray(prod) ? prod[0]?.nombre ?? null : prod?.nombre ?? null;
      return { id: h.id, nombre: h.nombre, productor, municipio: h.municipio ?? null };
    });
  },
  ["cortes:huertas-para-corte"],
  { tags: [CATALOGOS_TAG], revalidate: 300 },
);

/** Opciones {value,label} (value = label, denormalizado) para selects.
   Cacheadas bajo el tag de catálogos (se invalidan al editar cuadrilla/acopiador). */
function labelOptions(table: "cuadrilla" | "acopiador") {
  return unstable_cache(
    async (): Promise<{ value: string; label: string }[]> => {
      const supabase = createReadClient();
      const { data } = await supabase.from(table).select("nombre").order("nombre").limit(LIST_LIMIT);
      return (data ?? []).map((r) => ({ value: r.nombre as string, label: r.nombre as string }));
    },
    [`cortes:label-options:${table}`],
    { tags: [CATALOGOS_TAG], revalidate: 300 },
  );
}

export const getCuadrillaOptions = () => labelOptions("cuadrilla")();
export const getAcopiadorOptions = () => labelOptions("acopiador")();

/** Tipos de corte distintos ya vistos (para el select). */
export async function getTipoCorteOptions(): Promise<{ value: string; label: string }[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("corte")
    .select("tipo_corte")
    .not("tipo_corte", "is", null)
    .limit(LIST_LIMIT);
  const set = new Set((data ?? []).map((r) => r.tipo_corte as string).filter(Boolean));
  return [...set].sort().map((t) => ({ value: t, label: t }));
}
