"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

export default function LoginPage() {
  const [password, setPassword] = useState("");
  const [error, setError] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(false);

    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });

    if (res.ok) {
      router.push("/");
      router.refresh();
    } else {
      setError(true);
      setPassword("");
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-base-900 gap-8">
      {/* Logo */}
      <div className="flex flex-col items-center gap-3">
        <Image
          src="/gota-avoolio.png"
          alt="AvoOlio"
          width={72}
          height={72}
          priority
        />
        <h1 className="text-2xl font-semibold tracking-tight text-white">
          AvoOlio
        </h1>
        <p className="text-sm text-white/40">Cadena de suministro · Aguacate</p>
      </div>

      {/* Form */}
      <form
        onSubmit={handleSubmit}
        className="flex flex-col gap-3 w-full max-w-xs"
      >
        <input
          type="password"
          placeholder="Contraseña"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoFocus
          className={`
            w-full px-4 py-2.5 rounded-lg text-sm bg-white/5 border
            text-white placeholder:text-white/30 outline-none
            transition-colors
            ${error ? "border-red-500/60 focus:border-red-500" : "border-white/10 focus:border-white/30"}
          `}
        />
        {error && (
          <p className="text-xs text-red-400 text-center">Contraseña incorrecta</p>
        )}
        <button
          type="submit"
          disabled={loading || !password}
          className="w-full py-2.5 rounded-lg bg-green-600 hover:bg-green-500 disabled:opacity-40 disabled:cursor-not-allowed text-white text-sm font-medium transition-colors"
        >
          {loading ? "Entrando..." : "Entrar"}
        </button>
      </form>
    </div>
  );
}
