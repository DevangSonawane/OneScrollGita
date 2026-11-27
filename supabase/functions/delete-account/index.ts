// delete-account: revokes the user's Apple token (Apple requires it), then
// deletes the account. Profiles, purchase records and the stored Apple
// token go with it (on delete cascade).
import { appleSignInConfigured, revokeToken } from "../_shared/apple.ts";
import { json } from "../_shared/env.ts";
import { admin, callerId } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const sb = admin();
  const userId = await callerId(req, sb);
  if (!userId) return json({ error: "not signed in" }, 401);

  let appleRevoked: boolean | null = null;
  const { data: token } = await sb.from("apple_tokens")
    .select("client_id, refresh_token")
    .eq("user_id", userId)
    .maybeSingle();
  if (token && appleSignInConfigured()) {
    try {
      appleRevoked = await revokeToken(token.refresh_token, token.client_id);
    } catch (e) {
      console.error("apple revoke", e);
      appleRevoked = false;
    }
  }
  // Deleting the account never waits on Apple: the user asked for it.
  const { error } = await sb.auth.admin.deleteUser(userId);
  if (error) {
    console.error("delete user", error);
    return json({ error: "could not delete" }, 500);
  }
  return json({ deleted: true, appleRevoked });
});
