import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Cxp, CxpTipo, CxpEstado } from "./schema";

const n = (v: number | string | null): number | null =>
  v == null ? null : typeof v === "number" ? v : Number(v);

export async function getCxp(): Promise<Cxp[]> {
  const supabase = await createClient();
  const [{ data, error }, { data: acs }] = await Promise.all([
    supabase
      .from("cxp")
      .select(
        "id, tipo, origen, beneficiario, huerta, lote, orden_compra, fecha, semana, kilos, monto, factura, estado, forma_pago",
      )
      .order("fecha", { ascending: false, nullsFirst: false })
      .limit(1000), // Tope de seguridad mientras no haya paginación server-side.
    // Tarifas del catálogo para estimar montos de acarreo faltantes (1 viaje/fila).
    supabase.from("acarreador").select("nombre, tarifa_viaje"),
  ]);

  if (error) {
    console.error("getCxp:", error.message);
    return [];
  }

  const tarifa = new Map<string, number | null>(
    (acs ?? []).map((a) => [a.nombre as string, n(a.tarifa_viaje)]),
  );

  return (data ?? []).map((r) => {
    let monto = n(r.monto);
    let montoEstimado = false;
    // Acarreo sin Total en Monday → estimar con la tarifa por viaje registrada.
    if (r.tipo === "acarreo" && monto == null && r.beneficiario) {
      const t = tarifa.get(r.beneficiario);
      if (t != null) {
        monto = t;
        montoEstimado = true;
      }
    }
    return {
      id: r.id,
      tipo: r.tipo as CxpTipo,
      origen: r.origen ?? undefined,
      beneficiario: r.beneficiario ?? undefined,
      huerta: r.huerta ?? undefined,
      lote: r.lote ?? undefined,
      ordenCompra: r.orden_compra ?? undefined,
      fecha: r.fecha ?? undefined,
      semana: r.semana ?? null,
      kilos: n(r.kilos) ?? undefined,
      monto: monto ?? undefined,
      factura: r.factura ?? undefined,
      estado: r.estado as CxpEstado,
      formaPago: r.forma_pago ?? undefined,
      montoEstimado,
    };
  });
}
