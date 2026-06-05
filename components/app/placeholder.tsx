import type { Icon } from "@phosphor-icons/react";

/* Pantalla "próximamente" para secciones aún no construidas. Honesta: dice qué
   falta, no finge datos. */
export function Placeholder({
  icon: Icon,
  title,
  description,
}: {
  icon: Icon;
  title: string;
  description: string;
}) {
  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-h1 font-semibold text-text-primary">{title}</h1>
      <div className="flex flex-col items-center gap-3 rounded-md border border-dashed border-border py-20 text-center">
        <Icon size={32} className="text-text-faint" />
        <p className="text-body font-medium text-text-primary">Próximamente</p>
        <p className="max-w-sm text-caption text-text-muted">{description}</p>
      </div>
    </div>
  );
}
