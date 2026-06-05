"use client";

import * as React from "react";
import { useForm, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter } from "next/navigation";
import { Warning } from "@phosphor-icons/react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { corteSchema, ALTURA_MIN, ESTADOS, ESTADO_META, type Corte } from "@/lib/cortes/schema";
import { guardarCorte } from "@/lib/cortes/actions";

type Opt = { value: string; label: string };
type HuertaOpt = { id: string; nombre: string; productor: string | null; municipio: string | null };
type Values = Record<string, unknown>;

const vacio: Values = {
  huerto: "",
  productor: "",
  municipio: "",
  asnm: "",
  tipo_corte: "",
  empresa_corte: "",
  acopio: "",
  bascula: "",
  punto_reunion: "",
  camion: "",
  precio_pactado: "",
  programado: "",
  estado: "registrado",
};

const str = (v: unknown) => (v == null ? "" : String(v));

export function ProgramarCorteDialog({
  open,
  onOpenChange,
  editando,
  huertas,
  cuadrillas,
  acopiadores,
  tipos,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  editando?: Corte | null;
  huertas: HuertaOpt[];
  cuadrillas: Opt[];
  acopiadores: Opt[];
  tipos: Opt[];
}) {
  const router = useRouter();
  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(corteSchema as unknown as Parameters<typeof zodResolver>[0]) as unknown as Resolver<Values>,
    defaultValues: vacio,
  });
  const [serverError, setServerError] = React.useState<string | null>(null);

  // Resetea el form al abrir (alta vacía o edición precargada).
  React.useEffect(() => {
    if (!open) return;
    setServerError(null);
    reset(
      editando
        ? {
            huerto: str(editando.huerto),
            productor: str(editando.productor),
            municipio: str(editando.municipio),
            asnm: str(editando.asnm),
            tipo_corte: str(editando.tipo_corte),
            empresa_corte: str(editando.empresa_corte),
            acopio: str(editando.acopio),
            bascula: str(editando.bascula),
            punto_reunion: str(editando.punto_reunion),
            camion: str(editando.camion),
            precio_pactado: str(editando.precio_pactado),
            programado: str(editando.programado),
            estado: editando.estado,
          }
        : vacio,
    );
  }, [open, editando, reset]);

  const asnm = Number(watch("asnm"));
  const alerta = asnm > 0 && asnm < ALTURA_MIN;

  // Autollenado: al elegir una huerta del catálogo se copian sus datos.
  function aplicarHuerta(id: string) {
    const h = huertas.find((x) => x.id === id);
    if (!h) return;
    setValue("huerto", h.nombre, { shouldValidate: true });
    setValue("productor", h.productor ?? "");
    setValue("municipio", h.municipio ?? "");
  }

  const submit = handleSubmit(async (values) => {
    setServerError(null);
    const res = await guardarCorte(values, editando?.id);
    if (res.ok) {
      onOpenChange(false);
      router.refresh();
    } else {
      setServerError(res.error ?? "No se pudo guardar.");
    }
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{editando ? "Editar corte" : "Programar corte"}</DialogTitle>
          <DialogDescription>
            Elige la huerta y el resto se autollena desde el catálogo. Puedes editar
            cualquier campo.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={submit} className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-x-4 gap-y-3">
            {/* Selector de huerta (no se envía; alimenta los demás) */}
            <Campo label="Huerta (catálogo)" span={2}>
              <select
                defaultValue=""
                onChange={(e) => aplicarHuerta(e.target.value)}
                className={selectCls}
              >
                <option value="">— Selecciona una huerta —</option>
                {huertas.map((h) => (
                  <option key={h.id} value={h.id}>
                    {h.nombre}
                    {h.municipio ? ` · ${h.municipio}` : ""}
                  </option>
                ))}
              </select>
            </Campo>

            <Campo label="Huerto" required error={errors.huerto?.message as string}>
              <Input {...register("huerto")} placeholder="Nombre del huerto" />
            </Campo>
            <Campo label="Programado">
              <Input type="date" {...register("programado")} className="font-mono" />
            </Campo>

            <Campo label="Productor">
              <Input {...register("productor")} placeholder="—" />
            </Campo>
            <Campo label="Municipio">
              <Input {...register("municipio")} placeholder="—" />
            </Campo>

            <Campo label="Altura (msnm)">
              <Input type="number" step="any" {...register("asnm")} placeholder="ej. 2210" className="font-mono" />
            </Campo>
            <Campo label="Báscula">
              <Input {...register("bascula")} placeholder="—" />
            </Campo>

            {alerta && (
              <div className="col-span-2 flex items-start gap-2 rounded-sm border border-danger/30 bg-danger/12 px-3 py-2">
                <Warning size={16} weight="fill" className="mt-0.5 shrink-0 text-danger" />
                <p className="text-caption text-text-primary">
                  <strong className="text-danger">Alerta de altura (&lt;{ALTURA_MIN} msnm).</strong>{" "}
                  Riesgo de gusano barrenador. El corte requerirá aceptación de riesgo del
                  supervisor.
                </p>
              </div>
            )}

            <Campo label="Punto de reunión" span={2}>
              <Input {...register("punto_reunion")} placeholder="—" />
            </Campo>

            <Campo label="Empresa de corte">
              <Selesct {...register("empresa_corte")} placeholder="Sin asignar" options={cuadrillas} />
            </Campo>
            <Campo label="Acopiador">
              <Selesct {...register("acopio")} placeholder="Sin asignar" options={acopiadores} />
            </Campo>

            <Campo label="Tipo de corte">
              <Selesct {...register("tipo_corte")} placeholder="Sin especificar" options={tipos} />
            </Campo>
            <Campo label="Precio pactado ($/kg)">
              <Input type="number" step="any" {...register("precio_pactado")} placeholder="0.00" className="font-mono" />
            </Campo>

            <Campo label="Camión" span={2}>
              <Input {...register("camion")} placeholder="—" />
            </Campo>

            <Campo label="Estado">
              <select {...register("estado")} className={selectCls}>
                {ESTADOS.map((e) => (
                  <option key={e} value={e}>
                    {ESTADO_META[e].label}
                  </option>
                ))}
              </select>
            </Campo>
          </div>

          {serverError && (
            <p className="rounded-sm border border-danger/30 bg-danger/12 px-3 py-2 text-caption text-danger">
              {serverError}
            </p>
          )}

          <div className="flex justify-end gap-2 border-t border-border pt-4">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={isSubmitting}>
              Cancelar
            </Button>
            <Button type="submit" variant="default" disabled={isSubmitting}>
              {isSubmitting ? "Guardando…" : editando ? "Guardar cambios" : "Programar corte"}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

const selectCls =
  "h-9 rounded-sm border border-border bg-bg-default px-2.5 text-body text-text-primary outline-none focus-visible:border-brand";

function Campo({
  label,
  required,
  error,
  span,
  children,
}: {
  label: string;
  required?: boolean;
  error?: string;
  span?: 1 | 2;
  children: React.ReactNode;
}) {
  return (
    <div className={cn("flex flex-col gap-1.5", span === 2 && "col-span-2")}>
      <Label className="text-caption text-text-muted">
        {label}
        {required && <span className="text-danger"> *</span>}
      </Label>
      {children}
      {error && <p className="text-caption text-danger">{error}</p>}
    </div>
  );
}

/** Select nativo estilado, compatible con register() de RHF. */
const Selesct = React.forwardRef<
  HTMLSelectElement,
  React.ComponentProps<"select"> & { options: Opt[]; placeholder?: string }
>(function Selesct({ options, placeholder, ...props }, ref) {
  return (
    <select ref={ref} className={selectCls} {...props}>
      <option value="">— {placeholder ?? "Selecciona"} —</option>
      {options.map((o) => (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      ))}
    </select>
  );
});
