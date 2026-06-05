import { CortesView } from "@/components/cortes/cortes-view";
import {
  getCortes,
  getHuertasParaCorte,
  getCuadrillaOptions,
  getAcopiadorOptions,
  getTipoCorteOptions,
} from "@/lib/cortes/queries";

export const dynamic = "force-dynamic";

export default async function CortesPage() {
  const [cortes, huertas, cuadrillas, acopiadores, tipos] = await Promise.all([
    getCortes(),
    getHuertasParaCorte(),
    getCuadrillaOptions(),
    getAcopiadorOptions(),
    getTipoCorteOptions(),
  ]);

  return (
    <CortesView
      cortes={cortes}
      huertas={huertas}
      cuadrillas={cuadrillas}
      acopiadores={acopiadores}
      tipos={tipos}
    />
  );
}
