import "server-only";
import { unstable_cache } from "next/cache";
import { createReadClient, CATALOGOS_TAG } from "@/lib/supabase/read";
import type {
  Huerta,
  Productor,
  Acopiador,
  Cuadrilla,
  Acarreador,
} from "./schema";

/* Queries de catálogos — lecturas cacheadas con `unstable_cache` y el tag
   `catalogos`. Cada mutación (lib/catalogos/actions.ts) llama revalidateTag,
   así que el caché se tira en cada escritura → nunca queda stale. El revalidate
   de 5 min es solo un respaldo por si algo cambia fuera de la app.
   Usan el cliente sin-cookies (read.ts) porque unstable_cache no admite cookies. */

const n = (v: number | string | null): number | null =>
  v == null ? null : typeof v === "number" ? v : Number(v);

/** Wrapper: cachea una lectura bajo el tag de catálogos. */
function cached<T>(fn: () => Promise<T>, key: string) {
  return unstable_cache(fn, [`catalogos:${key}`], {
    tags: [CATALOGOS_TAG],
    revalidate: 300,
  });
}

export const getHuertas = cached<Huerta[]>(async () => {
  const supabase = createReadClient();
  const { data, error } = await supabase
    .from("huerta")
    .select("id, hue, nombre, productor_id, municipio, altura, punto_reunion, bascula, productor:productor_id(nombre)")
    .order("hue")
    .limit(1000);
  if (error) {
    console.error("getHuertas:", error.message);
    return [];
  }
  return (data ?? []).map((r) => {
    const prod = r.productor as { nombre: string } | { nombre: string }[] | null;
    const productorNombre = Array.isArray(prod) ? prod[0]?.nombre ?? null : prod?.nombre ?? null;
    return {
      id: r.id,
      hue: r.hue,
      nombre: r.nombre,
      productor_id: r.productor_id ?? undefined,
      municipio: r.municipio ?? undefined,
      altura: n(r.altura) ?? undefined,
      punto_reunion: r.punto_reunion ?? undefined,
      bascula: r.bascula ?? undefined,
      productorNombre,
    };
  });
}, "huertas");

export const getProductores = cached<Productor[]>(async () => {
  const supabase = createReadClient();
  const { data, error } = await supabase
    .from("productor")
    .select("id, nombre, rfc, municipio, tel, correo, beneficiario, dias_credito, huerta(count)")
    .order("nombre")
    .limit(1000);
  if (error) {
    console.error("getProductores:", error.message);
    return [];
  }
  return (data ?? []).map((r) => {
    const count = (r.huerta as { count: number }[] | null)?.[0]?.count ?? 0;
    return {
      id: r.id,
      nombre: r.nombre,
      rfc: r.rfc ?? undefined,
      municipio: r.municipio ?? undefined,
      tel: r.tel ?? undefined,
      correo: r.correo ?? undefined,
      beneficiario: r.beneficiario ?? undefined,
      dias_credito: n(r.dias_credito) ?? undefined,
      huertasCount: count,
    };
  });
}, "productores");

/** Opciones {value,label} de productores para selects de formularios. */
export const getProductorOptions = cached<{ value: string; label: string }[]>(async () => {
  const supabase = createReadClient();
  const { data } = await supabase.from("productor").select("id, nombre").order("nombre");
  return (data ?? []).map((p) => ({ value: p.id, label: p.nombre }));
}, "productor-options");

export const getAcopiadores = cached<Acopiador[]>(async () => {
  const supabase = createReadClient();
  const { data, error } = await supabase
    .from("acopiador")
    .select("id, nombre, whatsapp, zona, estatus")
    .order("nombre")
    .limit(1000);
  if (error) {
    console.error("getAcopiadores:", error.message);
    return [];
  }
  return (data ?? []).map((r) => ({
    id: r.id,
    nombre: r.nombre,
    whatsapp: r.whatsapp ?? undefined,
    zona: r.zona ?? undefined,
    estatus: r.estatus,
  }));
}, "acopiadores");

export const getCuadrillas = cached<Cuadrilla[]>(async () => {
  const supabase = createReadClient();
  const { data, error } = await supabase
    .from("cuadrilla")
    .select("id, nombre, tipo, tarifa_kg, tarifa_dia")
    .order("nombre")
    .limit(1000);
  if (error) {
    console.error("getCuadrillas:", error.message);
    return [];
  }
  return (data ?? []).map((r) => ({
    id: r.id,
    nombre: r.nombre,
    tipo: r.tipo,
    tarifa_kg: n(r.tarifa_kg) ?? undefined,
    tarifa_dia: n(r.tarifa_dia) ?? undefined,
  }));
}, "cuadrillas");

export const getAcarreadores = cached<Acarreador[]>(async () => {
  const supabase = createReadClient();
  const { data, error } = await supabase
    .from("acarreador")
    .select("id, nombre, tipo_unidad, tarifa_viaje")
    .order("nombre")
    .limit(1000);
  if (error) {
    console.error("getAcarreadores:", error.message);
    return [];
  }
  return (data ?? []).map((r) => ({
    id: r.id,
    nombre: r.nombre,
    tipo_unidad: r.tipo_unidad ?? undefined,
    tarifa_viaje: n(r.tarifa_viaje) ?? undefined,
  }));
}, "acarreadores");

/** Conteos para el dashboard de Inicio. */
export const getCatalogoCounts = cached(async () => {
  const supabase = createReadClient();
  const tablas = ["huerta", "productor", "acopiador", "cuadrilla", "acarreador"] as const;
  const counts = await Promise.all(
    tablas.map((t) =>
      supabase.from(t).select("*", { count: "exact", head: true }).then((r) => r.count ?? 0),
    ),
  );
  return Object.fromEntries(tablas.map((t, i) => [t, counts[i]])) as Record<
    (typeof tablas)[number],
    number
  >;
}, "counts");
