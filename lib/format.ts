/* =============================================================================
   Formato numérico normado por el spec (§04 Tipografía).
   - MXN sin espacio:        $38.50 MXN
   - USD con espacio/unidad: $34 USD/caja
   - Deltas con signo menos tipográfico (−, U+2212): +5.2% / −3.1%
   - Fechas en español en minúsculas: 25 may 2026 · 14:32
   Las cifras se renderizan en Geist Mono con tabular-nums (clase .font-mono).
   ============================================================================= */

const MINUS = "−"; // signo menos tipográfico, no el guion ASCII

/** $38.50 MXN — peso mexicano, sin espacio antes del símbolo. */
export function mxn(value: number, decimals = 2): string {
  const n = value.toLocaleString("es-MX", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
  return `$${n} MXN`;
}

/** $34 USD/caja — dólar con unidad opcional y espacio. */
export function usd(value: number, unit?: string, decimals = 0): string {
  const n = value.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
  return `$${n} USD${unit ? `/${unit}` : ""}`;
}

/** 1,247 kg — entero con separador de miles. */
export function kg(value: number): string {
  return `${value.toLocaleString("es-MX")} kg`;
}

/** +5.2% / −3.1% — delta con signo explícito y menos tipográfico. */
export function delta(value: number, decimals = 1): string {
  const abs = Math.abs(value).toFixed(decimals);
  if (value > 0) return `+${abs}%`;
  if (value < 0) return `${MINUS}${abs}%`;
  return `0.0%`;
}

/** Token semántico que le corresponde a un delta (verde sube, rojo baja). */
export function deltaTone(value: number): "success" | "danger" | "muted" {
  if (value > 0) return "success";
  if (value < 0) return "danger";
  return "muted";
}

/** "22 min" / "1 h 14 min" / "ahora" — antigüedad relativa corta (gutter de cola). */
export function hace(date: Date, now: Date): string {
  const mins = Math.max(0, Math.floor((now.getTime() - date.getTime()) / 60000));
  if (mins < 1) return "ahora";
  if (mins < 60) return `${mins} min`;
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m ? `${h} h ${m} min` : `${h} h`;
}

const MESES = [
  "ene", "feb", "mar", "abr", "may", "jun",
  "jul", "ago", "sep", "oct", "nov", "dic",
];

/** 25 may 2026 · 14:32 — fecha y hora en español, minúsculas. */
export function fecha(date: Date, withTime = true): string {
  const d = `${date.getDate()} ${MESES[date.getMonth()]} ${date.getFullYear()}`;
  if (!withTime) return d;
  const hh = String(date.getHours()).padStart(2, "0");
  const mm = String(date.getMinutes()).padStart(2, "0");
  return `${d} · ${hh}:${mm}`;
}
