"use client";

import * as React from "react";
import { useForm, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter } from "next/navigation";
import { Lock } from "@phosphor-icons/react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { mxn } from "@/lib/format";
import {
  cxpEditSchema,
  ESTADO_META,
  ESTADOS_REQUIEREN_FACTURA,
  TIPO_META,
  type Cxp,
  type CxpEstado,
} from "@/lib/cxp/schema";
import { guardarCxp } from "@/lib/cxp/actions";

type Values = Record<string, unknown>;
const ESTADOS: CxpEstado[] = ["borrador", "validada", "autorizada", "pagada", "conciliada"];
const selectCls =
  "h-9 rounded-sm border border-border bg-bg-default px-2.5 text-body text-text-primary outline-none focus-visible:border-brand disabled:opacity-50";

export function CxpEditDialog({
  cxp,
  onClose,
}: {
  cxp: Cxp | null;
  onClose: () => void;
}) {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(cxpEditSchema as unknown as Parameters<typeof zodResolver>[0]) as unknown as Resolver<Values>,
    defaultValues: {},
  });
  const [serverError, setServerError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!cxp) return;
    setServerError(null);
    reset({
      factura: cxp.factura ?? "",
      monto: cxp.monto ?? "",
      estado: cxp.estado,
      forma_pago: cxp.formaPago ?? "",
    });
  }, [cxp, reset]);

  const facturaActual = String(watch("factura") ?? "").trim();
  const bloqueado = facturaActual === "";

  const submit = handleSubmit(async (values) => {
    if (!cxp) return;
    setServerError(null);
    const res = await guardarCxp(cxp.id, values);
    if (res.ok) {
      onClose();
      router.refresh();
    } else {
      setServerError(res.error ?? "No se pudo guardar.");
    }
  });

  return (
    <Dialog open={cxp != null} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-lg">
        {cxp && (
          <>
            <DialogHeader>
              <DialogTitle>Obligación · {TIPO_META[cxp.tipo].label}</DialogTitle>
              <DialogDescription>
                {cxp.beneficiario ?? "—"}
                {cxp.huerta ? ` · ${cxp.huerta}` : ""}
                {cxp.monto != null ? ` · ${mxn(cxp.monto)}` : ""}
              </DialogDescription>
            </DialogHeader>

            <form onSubmit={submit} className="flex flex-col gap-4">
              {bloqueado && (
                <div className="flex items-start gap-2 rounded-sm border border-warning/30 bg-warning/12 px-3 py-2">
                  <Lock size={15} weight="fill" className="mt-0.5 shrink-0 text-warning" />
                  <p className="text-caption text-text-primary">
                    <strong className="text-warning">Sin factura.</strong> No puede avanzar a{" "}
                    <em>pagada</em> ni <em>conciliada</em> hasta registrar el CFDI.
                  </p>
                </div>
              )}

              <div className="grid grid-cols-2 gap-x-4 gap-y-3">
                <div className="col-span-2 flex flex-col gap-1.5">
                  <Label htmlFor="factura" className="text-caption text-text-muted">
                    Folio de factura (CFDI)
                  </Label>
                  <Input id="factura" {...register("factura")} placeholder="Sin factura" className="font-mono" />
                </div>

                <div className="flex flex-col gap-1.5">
                  <Label htmlFor="monto" className="text-caption text-text-muted">
                    Monto final ($)
                  </Label>
                  <Input id="monto" type="number" step="any" {...register("monto")} className="font-mono" />
                </div>

                <div className="flex flex-col gap-1.5">
                  <Label htmlFor="estado" className="text-caption text-text-muted">
                    Estado
                  </Label>
                  <select id="estado" {...register("estado")} className={selectCls}>
                    {ESTADOS.map((e) => (
                      <option key={e} value={e} disabled={bloqueado && ESTADOS_REQUIEREN_FACTURA.includes(e)}>
                        {ESTADO_META[e].label}
                        {bloqueado && ESTADOS_REQUIEREN_FACTURA.includes(e) ? " 🔒" : ""}
                      </option>
                    ))}
                  </select>
                  {errors.estado && (
                    <p className="text-caption text-danger">{errors.estado.message as string}</p>
                  )}
                </div>

                <div className="col-span-2 flex flex-col gap-1.5">
                  <Label htmlFor="forma_pago" className="text-caption text-text-muted">
                    Forma de pago
                  </Label>
                  <Input id="forma_pago" {...register("forma_pago")} placeholder="Transferencia / Efectivo / Cheque" />
                </div>
              </div>

              {serverError && (
                <p className="rounded-sm border border-danger/30 bg-danger/12 px-3 py-2 text-caption text-danger">
                  {serverError}
                </p>
              )}

              <div className="flex items-center gap-2 border-t border-border pt-4">
                <Badge tone={ESTADO_META[cxp.estado].tone}>{ESTADO_META[cxp.estado].label}</Badge>
                <span className="ml-auto flex gap-2">
                  <Button type="button" variant="ghost" onClick={onClose} disabled={isSubmitting}>
                    Cancelar
                  </Button>
                  <Button type="submit" variant="default" disabled={isSubmitting}>
                    {isSubmitting ? "Guardando…" : "Guardar"}
                  </Button>
                </span>
              </div>
            </form>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
