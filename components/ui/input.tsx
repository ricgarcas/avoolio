import * as React from "react"
import { Input as InputPrimitive } from "@base-ui/react/input"

import { cn } from "@/lib/utils"

function Input({ className, type, ...props }: React.ComponentProps<"input">) {
  return (
    <InputPrimitive
      type={type}
      data-slot="input"
      className={cn(
        // AgroMesh: radio 2px, borde 1px, foco por outline global, error inline.
        "h-9 w-full min-w-0 rounded-sm border border-input bg-bg-default px-3 py-1 text-body transition-colors outline-none placeholder:text-text-faint disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive",
        className
      )}
      {...props}
    />
  )
}

export { Input }
