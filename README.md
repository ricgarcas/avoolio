# AgroMesh — cliente Avoolio

Plataforma de operaciones para la cadena de suministro del aguacate en empacadoras
mexicanas. Sustituye hojas de Excel + WhatsApp sin estructura por un sistema con
trazabilidad de dinero y fruta auditada de extremo a extremo. **Primer cliente:
Avoolio** (Michoacán).

Este repo es el **dashboard PWA** (Next.js). El sistema de diseño está bloqueado
en `AgroMesh_Design_Spec.pdf` (v1.0).

## Stack

- **Next.js 15** (App Router, TS) · **Tailwind v4** (tokens como CSS variables)
- **shadcn** (base-nova / Base UI) — componentes themed con los tokens del spec
- **Geist Sans** (UI) · **JetBrains Mono** (números/IDs, tabular + tracking-tight)
- **Phosphor** (iconos) · **@supabase/ssr** (Postgres)

## Correr

```bash
npm install
npm run dev      # http://localhost:3000  → showcase del sistema de diseño
```

`npm run build` · `npm run typecheck` · `npm run lint`

## Estructura

| Ruta | Para qué |
|---|---|
| `app/globals.css` | **Tokens del spec** — color, tipografía, espacio, radios, dark/light |
| `app/page.tsx` | **Showcase** — la "prueba viva" del sistema de diseño (spec §03) |
| `components/ui/` | Button · Badge · Card · Input · DataTable · SideNav · Dialog (shadcn) |
| `components/theme-toggle.tsx` | Toggle claro/oscuro (default oscuro) |
| `lib/format.ts` | Formato numérico normado (MXN, USD, deltas, fechas es) |
| `lib/supabase/` | Helpers client/server/middleware (`@supabase/ssr`) |
| `_analisis/` | HTMLs de análisis de requerimientos (versión previa, estáticos) |
| `docs-fuente/` | PDFs originales de discovery |
| `scripts/supa.mjs` | Helper REST read-only para inspeccionar Supabase |

## Sistema de diseño (resumen)

Estética de **precisión de ingeniería**: densidad alta, **bordes no sombras**,
color con significado. Modo oscuro por defecto. Verde de marca `#65E06F` es
atención (nunca fondo salvo CTA); acento cyan `#5DD3F0` para MESH (IA), siempre
distinto del verde. Retícula de 8pt, radios nítidos 2/4/8px. La **tabla densa**
es la superficie firma. Ver el PDF para el detalle bloqueado.

## Estado

- ✅ Pase 1: scaffold + sistema de diseño (tokens + componentes + showcase).
- ⏳ Datos de **acopio**: viven en el schema `ops` de Supabase (legacy), **no expuesto**
  en la API y sin acceso de Owner. Migración a Postgres local (Herd) en curso —
  ver `DATABASE.md`.

> Stack y tokens confirmados desde el spec v1.0 (03 jun 2026).
