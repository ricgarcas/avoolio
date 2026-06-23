import { type NextRequest, NextResponse } from "next/server";

const COOKIE_NAME = "avoolio-auth";
const PUBLIC_PATHS = ["/login", "/api/auth/login", "/sicoa-review"];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Dejar pasar rutas públicas
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Verificar cookie de auth
  const auth = request.cookies.get(COOKIE_NAME);
  if (!auth || auth.value !== "1") {
    const loginUrl = new URL("/login", request.url);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
