import { CxpView } from "@/components/cxp/cxp-view";
import { getCxp } from "@/lib/cxp/queries";

export const dynamic = "force-dynamic";

export default async function CxpPage() {
  const cxp = await getCxp();
  return <CxpView cxp={cxp} />;
}
