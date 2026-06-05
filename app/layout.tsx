import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { JetBrains_Mono } from "next/font/google";
import "./globals.css";

// Geist Sans para toda la interfaz (body + headings).
// JetBrains Mono para números, IDs y timestamps — tabular y tracking-tight.
const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains-mono",
});

export const metadata: Metadata = {
  title: "AvoOlio",
  description:
    "Plataforma de operaciones para la cadena de suministro del aguacate.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    // Modo oscuro por defecto. El toggle (Configuración) cambia data-theme.
    <html
      lang="es"
      data-theme="dark"
      className={`${GeistSans.variable} ${jetbrainsMono.variable}`}
      suppressHydrationWarning
    >
      <body>{children}</body>
    </html>
  );
}
