# AgroMesh V1 — Calendario de trabajo (12 semanas)

**Fuentes:** repo `agromesh/blueprint` (`40_plan/SPRINT_PLAN.md`) + Linear (iniciativa [AgroMesh V1 — 12-week MVP](https://linear.app/agromeshai/initiative/agromesh-v1-12-week-mvp-84d3165b6c76), team Agromesh `AGR`, 90 issues).
**Estado al 10 jun 2026:** ✅ AGR-5 (decisiones bloqueantes) cerrado por Mariano el 7 jun — Sprint 0 desbloqueado. S0 y S1 en Todo; S2–S6 en Backlog.
**Cadencia fija:** Lunes standup · Jueves sync SICOA · **Viernes demo a Avoolio (no negociable)**.

> En Linear los sprints viven como **labels S0–S6** (no hay cycles ni due dates por issue). Las fechas oficiales son las del roadmap por proyecto (abajo). Filtra tu trabajo con `assignee:Ricardo` o el proyecto Accounting.

---

## Roadmap oficial (fechas de Linear, por proyecto)

| Proyecto (track) | Inicio | Target | Owner |
|---|---|---|---|
| Foundations | 6 jun | **13 jun** | Abisai |
| Calculadora (WhatsApp agent) | 13 jun | 29 ago | Alberto |
| Dashboards | 13 jun | 29 ago | Abisai |
| Integrations (SICOA/USDA/Banxico) | 13 jun | 15 ago | Alberto |
| **Accounting (Ricardo)** | **6 jun** | **15 ago** | **Ricardo** |
| Scoring | 18 jul | 1 ago | Alberto |
| Ventas (Sales agent) | 1 ago | 29 ago | Alberto |
| Notifications & Bridge | 15 ago | 29 ago | Abisai |
| **V1 completo** | | **sáb 29 ago 2026** | |

*Nota: el roadmap de Linear corre ~1 semana más apretado que la matemática estricta de sprints del repo (que daría ~4 sep). Manda Linear.*

---

## Sprints (labels S0–S6, semanas derivadas del roadmap)

| Sprint | Fechas aprox. | Tema | Pts | Demos (viernes) |
|--------|--------------|------|-----|-----------------|
| **S0** | 6 – 13 jun *(en curso)* | Foundations: DB + auth + Baileys + deploy | 31 | 12 jun |
| **S1** | 15 – 26 jun | El acopio recibe precio (el sprint más importante) | 48 | 19 y 26 jun |
| **S2** | 29 jun – 10 jul | Negociaciones + HITL + acuerdo PDF | 39 | 3 y 10 jul |
| **S3** | 13 – 24 jul | SICOA RPA en vivo (mayor riesgo: anti-bot con sanciones) | 35 | 17 y 24 jul |
| **S4** | 27 jul – 7 ago | Scoring (ground truth → 4 scores) | 37 | 31 jul y 7 ago |
| **S5** | 10 – 21 ago | Ventas: CRM + órdenes + USDA | 42 | 14 y 21 ago |
| **S6** | 24 – 29 ago | El loop cierra: bridge + notificaciones | 44 | 28 ago (final) |

---

## Track de Ricardo (Accounting — boundary contractor) · 6 jun → 15 ago

Lo vinculante es `30_integrations/ACCOUNTING_REQUIREMENTS.md` (contrato de datos). El modelo en `10_data_model/accounting/` es referencia no vinculante. Tú decides: stack, PAC, base de efectivo vs devengado, mecanismo de integración. **Terminología:** ver `docs/GLOSARIO_CONTABLE.md` (jerga contable mexicana, fuente de verdad).

| Issue | Sprint | Fechas | Entregable | Pts | Estado |
|-------|--------|--------|-----------|-----|--------|
| [AGR-13](https://linear.app/agromeshai/issue/AGR-13) | S0 | ahora – 13 jun | Modelo contable: libro diario, catálogo de cuentas, asientos | 5 | **Todo — arrancar ya** |
| [AGR-25](https://linear.app/agromeshai/issue/AGR-25) | S1 | 15 – 26 jun | Cost capture (acarreo / corte / fijos) ligado a deals | 5 | Todo |
| [AGR-37](https://linear.app/agromeshai/issue/AGR-37) | S2 | 29 jun – 10 jul | **Estado de resultados por calibre** → Inicio Admin (4 widgets) | 5 | Backlog |
| [AGR-44](https://linear.app/agromeshai/issue/AGR-44) | S3 | 13 – 24 jul | CxC/CxP + cobranza 21–25 días | 5 | Backlog |
| [AGR-45](https://linear.app/agromeshai/issue/AGR-45) | S3 | 13 – 24 jul | Spike CFDI 4.0 (elegir PAC, decidir approach) | 3 | Backlog |
| — | S4 | 27 jul – 7 ago | *(vacío — colchón / adelantar CFDI)* | 0 | — |
| [AGR-68](https://linear.app/agromeshai/issue/AGR-68) | S5 | 10 – 21 ago | Ligar pedidos de venta → CxC (cuentas por cobrar) | 3 | Backlog |
| [AGR-87](https://linear.app/agromeshai/issue/AGR-87) | Post-V1 | backlog | Full CFDI/SAT invoicing build | 8 | Backlog |

**Antes de cerrar S0 hay que confirmarle al equipo:** (1) mecanismo de integración (recomendado: vistas read-only en Supabase + tablas de output propias), (2) que puedes producir los 6 outputs del contrato, (3) spec a nivel de campo de tus tablas/endpoints para que Abisai cablee los dashboards.

**Los 6 reportes obligatorios** (todos por `empacadora_id` + periodo): estado de resultados por calibre · antigüedad de saldos de CxC · estatus de CxP · salud del negocio · estatus de timbrado por pedido · cierre mensual.

**No negociables:** CFDI 4.0 vía PAC certificado · partida doble · multi-moneda MXN/USD con fluctuación cambiaria (NIF) · costo de ventas por calibre · RLS por tenant · libro diario inmutable.

> ⚠️ Carga personal: ~5 pts/sprint es viable en paralelo, pero S3 (8 pts: AR/AP + spike CFDI) cae a mediados de julio, justo cuando arranca tu trabajo nuevo. S4 está vacío — úsalo de colchón o adelanta el spike CFDI a S2.

---

## Riesgos y dependencias clave

- **S1 decide todo:** si HUE→precio cuadra ±$0.50/kg vs el Excel de Avoolio (parallel-run 1 semana), el bot se usa a diario.
- **S3 = mayor riesgo:** SICOA tiene anti-bot con sanciones monetarias → RPA en modo supervisado primero, ritmo humano, fallback manual.
- **Baileys (WhatsApp no oficial):** riesgo de baneo → si quieren la API oficial de Meta después, la verificación Business tarda 2–4 semanas: iniciarla YA.
- **Capacidad:** 40–48 pts/sprint para 2–3 devs es ambicioso. Si hay retraso: enviar P0, arrastrar P1. **Accounting es el track que más fácil se atrasa** — flag temprano.
- Pendiente en Linear: la cuenta de Alberto sigue como invitación (`alberto@agromesh.ai`) y no hay cycles configurados — si quieren burndown por sprint, convertir labels S0–S6 a cycles.

---

## Métricas de éxito a semana 12 (29 ago)

50+ interacciones de acopio/semana · 20+ negociaciones · 10+ cortes trackeados · 5+ cortes agendados vía SICOA · precisión ±$0.50/kg · ≥1 acopio con score (≥5 cortes) · importadores en CRM · 3+ órdenes de venta · 1+ flujo Necesidad_Compra end-to-end.
