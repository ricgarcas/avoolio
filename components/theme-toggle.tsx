"use client";

import * as React from "react";
import { Moon, Sun } from "@phosphor-icons/react";
import { cn } from "@/lib/utils";

/* Toggle claro/oscuro. Predeterminado oscuro; el toggle vive en Configuración
   (aquí en el showcase para probar ambos temas). Persiste en localStorage. */

export function ThemeToggle({ className }: { className?: string }) {
  const [theme, setTheme] = React.useState<"dark" | "light">("dark");

  React.useEffect(() => {
    const saved = localStorage.getItem("agromesh-theme") as
      | "dark"
      | "light"
      | null;
    if (saved) {
      setTheme(saved);
      document.documentElement.dataset.theme = saved;
    }
  }, []);

  const toggle = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    document.documentElement.dataset.theme = next;
    localStorage.setItem("agromesh-theme", next);
  };

  return (
    <button
      onClick={toggle}
      aria-label={theme === "dark" ? "Cambiar a modo claro" : "Cambiar a modo oscuro"}
      className={cn(
        "inline-flex size-9 items-center justify-center rounded-sm border border-border text-text-muted hover:bg-bg-hover hover:text-text-primary",
        className,
      )}
    >
      {theme === "dark" ? (
        <Sun size={16} />
      ) : (
        <Moon size={16} />
      )}
    </button>
  );
}
