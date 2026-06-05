import { CatalogosClient } from "@/components/catalogos/catalogos-client";
import {
  getHuertas,
  getProductores,
  getProductorOptions,
  getAcopiadores,
  getCuadrillas,
  getAcarreadores,
} from "@/lib/catalogos/queries";

export const dynamic = "force-dynamic";

export default async function CatalogosPage() {
  const [huertas, productores, productorOptions, acopiadores, cuadrillas, acarreadores] =
    await Promise.all([
      getHuertas(),
      getProductores(),
      getProductorOptions(),
      getAcopiadores(),
      getCuadrillas(),
      getAcarreadores(),
    ]);

  return (
    <CatalogosClient
      huertas={huertas}
      productores={productores}
      acopiadores={acopiadores}
      cuadrillas={cuadrillas}
      acarreadores={acarreadores}
      productorOptions={productorOptions}
    />
  );
}
