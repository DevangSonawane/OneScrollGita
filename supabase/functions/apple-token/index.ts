// apple-token: right after Sign in with Apple, keeps the user's Apple
// refresh token so delete-account can revoke it later.
//   iPhone:  { "client": "ios", "code": "<authorizationCode>" }
//   Android: { "client": "web", "refreshToken": "<provider refresh token>" }
import {
  appleClientId,
  appleSignInConfigured,
  exchangeCode,
} from "../_shared/apple.ts";
import { json } from "../_shared/env.ts";
import { admin, callerId } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const sb = admin();
  const userId = await callerId(req, sb);
  if (!userId) return json({ error: "not signed in" }, 401);

  const body = await req.json().catch(() => null);
  const client = body?.client;
  if (client !== "ios" && client !== "web") {
    return json({ error: "bad request" }, 400);
  }
  const clientId = appleClientId(client);
  if (!clientId || !appleSignInConfigured()) return json({ stored: false });

  let refresh: string | null = null;
  try {
    if (client === "ios") {
      const code = body?.code;
      if (typeof code !== "string" || code.length > 1000) {
        return json({ error: "bad request" }, 400);
      }
      refresh = await exchangeCode(code, clientId);
    } else {
      const t = body?.refreshToken;
      refresh = typeof t === "string" && t.length <= 1000 ? t : null;
    }
  } catch (e) {
    console.error("apple token", e);
  }
  if (!refresh) return json({ stored: false });

  const { error } = await sb.from("apple_tokens").upsert({
    user_id: userId,
    client_id: clientId,
    refresh_token: refresh,
    updated_at: new Date().toISOString(),
  });
  if (error) {
    console.error("store apple token", error);
    return json({ stored: false }, 500);
  }
  return json({ stored: true });
});
