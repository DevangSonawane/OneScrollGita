// Sign in with Apple: turn a sign-in code into a refresh token, and revoke
// that token when the account is deleted (Apple requires the revoke).
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

import { bundleId, env, pem } from "./env.ts";

const APPLE = "https://appleid.apple.com";

/** Which Apple client signed the user in. */
export type AppleClient = "ios" | "web";

export function appleClientId(kind: AppleClient): string | undefined {
  return kind === "ios" ? bundleId() : env("APPLE_SERVICES_ID");
}

/** True when the Apple sign-in key is set up (docs/auth-setup.md). */
export function appleSignInConfigured(): boolean {
  return !!(env("APPLE_TEAM_ID") && env("APPLE_SIGNIN_KEY_ID") &&
    pem("APPLE_SIGNIN_PRIVATE_KEY"));
}

/** A short-lived client secret, made fresh for each call. */
async function clientSecret(clientId: string): Promise<string> {
  const key = await importPKCS8(pem("APPLE_SIGNIN_PRIVATE_KEY")!, "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: env("APPLE_SIGNIN_KEY_ID")! })
    .setIssuer(env("APPLE_TEAM_ID")!)
    .setSubject(clientId)
    .setAudience(APPLE)
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(key);
}

async function post(path: string, form: Record<string, string>) {
  return await fetch(`${APPLE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(form),
  });
}

/** The refresh token for a sign-in's authorization code, or null. */
export async function exchangeCode(
  code: string,
  clientId: string,
): Promise<string | null> {
  const res = await post("/auth/token", {
    client_id: clientId,
    client_secret: await clientSecret(clientId),
    code,
    grant_type: "authorization_code",
  });
  if (!res.ok) return null;
  const body = await res.json();
  return typeof body.refresh_token === "string" ? body.refresh_token : null;
}

/** Revokes a refresh token. True when Apple accepted it. */
export async function revokeToken(
  token: string,
  clientId: string,
): Promise<boolean> {
  const res = await post("/auth/revoke", {
    client_id: clientId,
    client_secret: await clientSecret(clientId),
    token,
    token_type_hint: "refresh_token",
  });
  return res.ok;
}
