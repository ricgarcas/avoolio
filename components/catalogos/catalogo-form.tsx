"use client";

import * as React from "react";
import { useForm, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import type { ZodType } from "zod";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import type { Field } from "@/lib/catalogos/schema";

/* Formulario genérico de catálogo. Renderiza campos por tipo desde la config,
   valida con el esquema zod del catálogo, y entrega valores limpios a onSubmit
   (una server action). Rejilla de 2 columnas; `span` controla el ancho. */

type Values = Record<string, unknown>;

export function CatalogoForm({
  fields,
  schema,
  defaultValues,
  options,
  submitLabel,
  onSubmit,
  onCancel,
}: {
  fields: Field[];
  schema: ZodType;
  defaultValues: Values;
  /** Opciones dinámicas por optionsKey (ej. productores). */
  options?: Record<string, { value: string; label: string }[]>;
  submitLabel: string;
  onSubmit: (values: Values) => Promise<{ ok: boolean; error?: string }>;
  onCancel: () => void;
}) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<Values>({
    resolver: zodResolver(
      schema as unknown as Parameters<typeof zodResolver>[0],
    ) as unknown as Resolver<Values>,
    defaultValues,
  });
  const [serverError, setServerError] = React.useState<string | null>(null);

  const submit = handleSubmit(async (values) => {
    setServerError(null);
    const res = await onSubmit(values);
    if (!res.ok) setServerError(res.error ?? "No se pudo guardar.");
  });

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <div className="grid grid-cols-2 gap-x-4 gap-y-3">
        {fields.map((f) => {
          const opts = f.options ?? (f.optionsKey ? options?.[f.optionsKey] : undefined);
          const err = errors[f.name]?.message as string | undefined;
          return (
            <div
              key={f.name}
              className={cn("flex flex-col gap-1.5", f.span === 2 && "col-span-2")}
            >
              <Label htmlFor={f.name} className="text-caption text-text-muted">
                {f.label}
                {f.required && <span className="text-danger"> *</span>}
              </Label>

              {f.type === "select" ? (
                <select
                  id={f.name}
                  {...register(f.name)}
                  className="h-9 rounded-sm border border-border bg-bg-default px-2.5 text-body text-text-primary outline-none focus-visible:border-brand"
                >
                  {!f.required && <option value="">— Sin asignar —</option>}
                  {opts?.map((o) => (
                    <option key={o.value} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </select>
              ) : (
                <Input
                  id={f.name}
                  type={f.type === "number" ? "number" : f.type === "email" ? "email" : f.type === "tel" ? "tel" : "text"}
                  step={f.type === "number" ? "any" : undefined}
                  placeholder={f.placeholder}
                  className={cn(f.mono && "font-mono")}
                  {...register(f.name)}
                />
              )}

              {err && <p className="text-caption text-danger">{err}</p>}
            </div>
          );
        })}
      </div>

      {serverError && (
        <p className="rounded-sm border border-danger/30 bg-danger/12 px-3 py-2 text-caption text-danger">
          {serverError}
        </p>
      )}

      <div className="flex justify-end gap-2 border-t border-border pt-4">
        <Button type="button" variant="ghost" onClick={onCancel} disabled={isSubmitting}>
          Cancelar
        </Button>
        <Button type="submit" variant="default" disabled={isSubmitting}>
          {isSubmitting ? "Guardando…" : submitLabel}
        </Button>
      </div>
    </form>
  );
}
