import { ChartBar } from "@phosphor-icons/react/dist/ssr";
import { Placeholder } from "@/components/app/placeholder";

export default function CosteoPage() {
  return (
    <Placeholder
      icon={ChartBar}
      title="Costeo"
      description="El reporte cumbre: cuánto costó comprar un kilo con servicios esta semana, por curva de calibre. Siguiente pase."
    />
  );
}
