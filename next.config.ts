import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // El repo tiene HTMLs de análisis y PDFs en la raíz; Next solo compila app/.
  reactStrictMode: true,
};

export default nextConfig;
