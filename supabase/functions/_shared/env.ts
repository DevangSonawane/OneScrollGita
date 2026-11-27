// Settings come from Supabase secrets (`supabase secrets set`), see
// docs/auth-setup.md. Never commit their values.

export function env(name: string): string | undefined {
  const v = Deno.env.get(name);
  return v && v.trim() ? v.trim() : undefined;
}

/** A PEM private key stored with literal \n in one line. */
export function pem(name: string): string | undefined {
  return env(name)?.replace(/\\n/g, "\n");
}

export const bundleId = () => env("APPLE_BUNDLE_ID") ?? "com.onescrollgita.app";
export const androidPackage = () =>
  env("ANDROID_PACKAGE") ?? "com.onescrollgita.app";

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
