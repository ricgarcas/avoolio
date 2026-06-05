import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

/* Badges / píldoras de estado — radio 2px (esquina aguda, nunca 9999px), caption,
   fondo al 12% del token semántico + borde 1px. El color NUNCA es la única señal:
   siempre lleva texto (y un punto donde aplica). */

const badgeVariants = cva(
  "inline-flex w-fit shrink-0 items-center justify-center gap-1.5 rounded-sm border px-2 py-0.5 text-caption font-medium whitespace-nowrap [&>svg]:size-3 [&>svg]:pointer-events-none",
  {
    variants: {
      tone: {
        success: "text-success bg-success/12 border-success/30",
        warning: "text-warning bg-warning/12 border-warning/30",
        danger: "text-danger bg-danger/12 border-danger/30",
        info: "text-info bg-info/12 border-info/30",
        brand: "text-brand bg-brand/12 border-brand/30",
        neutral: "text-text-muted bg-bg-active border-border",
      },
    },
    defaultVariants: {
      tone: "neutral",
    },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {
  dot?: boolean;
}

function Badge({ className, tone, dot, children, ...props }: BadgeProps) {
  return (
    <span
      data-slot="badge"
      className={cn(badgeVariants({ tone }), className)}
      {...props}
    >
      {dot && (
        <span className="size-1.5 rounded-full bg-current" aria-hidden="true" />
      )}
      {children}
    </span>
  );
}

export { Badge, badgeVariants };
