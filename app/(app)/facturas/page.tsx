import { FileText } from "@phosphor-icons/react/dist/ssr";
import { Placeholder } from "@/components/app/placeholder";

export default function FacturasPage() {
  return (
    <Placeholder
      icon={FileText}
      title="Facturas"
      description="Validación de CFDI que libera el candado de pago en cuentas por pagar. Siguiente pase."
    />
  );
}
