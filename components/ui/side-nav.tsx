"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { type Icon } from "@phosphor-icons/react";
import { cn } from "@/lib/utils";

/* Navegación lateral — 240px en escritorio. El item activo lleva un borde
   izquierdo de 2px en verde y fondo bg-raised. Hover = bg-hover. */

export interface NavItem {
  href: string;
  label: string;
  icon: Icon;
  /** Contador opcional (ej. pendientes). */
  count?: number;
}

export interface NavGroup {
  title?: string;
  items: NavItem[];
}

export function SideNav({
  groups,
  header,
}: {
  groups: NavGroup[];
  header?: React.ReactNode;
}) {
  const pathname = usePathname();

  return (
    <nav className="flex w-60 shrink-0 flex-col border-r border-border bg-bg-default">
      {header && (
        <div className="flex h-14 items-center border-b border-border px-4">
          {header}
        </div>
      )}
      <div className="flex flex-col gap-4 overflow-y-auto py-4">
        {groups.map((group, gi) => (
          <div key={gi} className="flex flex-col gap-0.5 px-2">
            {group.title && (
              <p className="px-2 pb-1 text-caption font-medium uppercase tracking-wide text-text-faint">
                {group.title}
              </p>
            )}
            {group.items.map((item) => {
              const active =
                pathname === item.href ||
                pathname.startsWith(item.href + "/");
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  aria-current={active ? "page" : undefined}
                  className={cn(
                    "flex min-h-[36px] items-center gap-2.5 rounded-sm border-l-2 px-2.5 text-caption transition-colors",
                    active
                      ? "border-l-brand bg-bg-raised text-text-primary"
                      : "border-l-transparent text-text-muted hover:bg-bg-hover hover:text-text-primary",
                  )}
                >
                  <Icon size={16} aria-hidden="true" />
                  <span className="flex-1">{item.label}</span>
                  {item.count != null && (
                    <span className="font-mono tabular-nums text-caption text-text-faint">
                      {item.count}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </div>
    </nav>
  );
}
