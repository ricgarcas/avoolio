"use client";

import * as React from "react";
import Image from "next/image";
import {
  House,
  Tray,
  Books,
  Scissors,
  Receipt,
  FileText,
  Money,
  ChartBar,
} from "@phosphor-icons/react";

import { SideNav, type NavGroup } from "@/components/ui/side-nav";
import { ThemeToggle } from "@/components/theme-toggle";

/* Shell de la app de administración: navegación lateral fija de 240px + barra
   superior. El contenido vive en <main>. La cola de Pendientes (móvil) se
   accede desde aquí pero conserva su propio layout angosto. */

export function AppShell({
  children,
  pendientesCount,
}: {
  children: React.ReactNode;
  pendientesCount?: number;
}) {
  const groups: NavGroup[] = [
    {
      items: [
        { href: "/", label: "Inicio", icon: House },
        { href: "/pendientes", label: "Pendientes", icon: Tray, count: pendientesCount },
        { href: "/catalogos", label: "Catálogos", icon: Books },
      ],
    },
    {
      title: "Operación",
      items: [
        { href: "/cortes", label: "Cortes", icon: Scissors },
        { href: "/cxp", label: "Cuentas por pagar", icon: Receipt },
        { href: "/facturas", label: "Facturas", icon: FileText },
        { href: "/pagos", label: "Pagos", icon: Money },
        { href: "/costeo", label: "Costeo", icon: ChartBar },
      ],
    },
  ];

  return (
    <div className="flex min-h-dvh bg-bg-default">
      <SideNav
        groups={groups}
        header={
          <span className="flex items-center gap-2 text-h3 font-semibold tracking-tight">
            <Image
              src="/gota-avoolio.png"
              alt="AvoOlio"
              width={258}
              height={271}
              className="h-6 w-auto"
              priority
            />
            <span>
              <span className="text-brand">Avo</span>
              <span className="text-warning">Olio</span>
            </span>
          </span>
        }
      />

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-10 flex h-14 shrink-0 items-center gap-3 border-b border-border bg-bg-default/95 px-5 backdrop-blur">
          <span className="text-caption text-text-faint">
            AvoOlio · empacadora San José
          </span>
          <div className="ml-auto flex items-center gap-2">
            <ThemeToggle />
          </div>
        </header>

        <main className="min-w-0 flex-1 p-5">{children}</main>
      </div>
    </div>
  );
}
