import { NextRequest, NextResponse } from "next/server";

const PASSWORD = "avocado";
const COOKIE_NAME = "avoolio-auth";
const COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 días

export async function POST(req: NextRequest) {
  const { password } = await req.json();

  if (password !== PASSWORD) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const res = NextResponse.json({ ok: true });
  res.cookies.set(COOKIE_NAME, "1", {
    httpOnly: true,
    sameSite: "lax",
    maxAge: COOKIE_MAX_AGE,
    path: "/",
    // secure: true en producción (Vercel lo pone en HTTPS automáticamente)
    secure: process.env.NODE_ENV === "production",
  });

  return res;
}
