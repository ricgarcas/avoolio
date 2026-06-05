import { Money } from "@phosphor-icons/react/dist/ssr";
import { Placeholder } from "@/components/app/placeholder";

export default function PagosPage() {
  return (
    <Placeholder
      icon={Money}
      title="Pagos"
      description="Registro y conciliación de pagos a productores y servicios, con trazabilidad de excepciones autorizadas. Siguiente pase."
    />
  );
}
