// google-notifications: Google Play Real-time developer notifications,
// pushed by a Pub/Sub push subscription to
//   https://<project>.supabase.co/functions/v1/google-notifications
// Pub/Sub signs each push with a Google ID token for the service account
// in GOOGLE_RTDN_SERVICE_ACCOUNT (no shared secret needed). A URL
// ?token=<GOOGLE_RTDN_TOKEN> is accepted too.
// The purchase is fetched again from Google Play before anything is written.
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5.9.6";

import { androidPackage, env, json } from "../_shared/env.ts";
import {
  playEventName,
  sameSecret,
  validProductId,
} from "../_shared/status.ts";
import { playConfigured, playPurchase } from "../_shared/stores.ts";
import {
  admin,
  logEvent,
  saveRecord,
  storeFields,
  userExists,
} from "../_shared/supabase.ts";

const googleKeys = createRemoteJWKSet(
  new URL("https://www.googleapis.com/oauth2/v3/certs"),
);

/** True when the push carries Pub/Sub's ID token for our service account. */
async function signedByPubSub(req: Request): Promise<boolean> {
  const account = env("GOOGLE_RTDN_SERVICE_ACCOUNT");
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!account || !token) return false;
  try {
    const { payload } = await jwtVerify(token, googleKeys, {
      issuer: ["https://accounts.google.com", "accounts.google.com"],
      audience: env("GOOGLE_RTDN_AUDIENCE") ??
        `${env("SUPABASE_URL")}/functions/v1/google-notifications`,
    });
    return payload.email === account && payload.email_verified === true;
  } catch {
    return false;
  }
}

function hasUrlToken(req: Request): boolean {
  const secret = env("GOOGLE_RTDN_TOKEN");
  const given = new URL(req.url).searchParams.get("token") ?? "";
  return !!secret && sameSecret(given, secret);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  if (!hasUrlToken(req) && !(await signedByPubSub(req))) {
    return json({ error: "forbidden" }, 403);
  }
  if (!playConfigured()) return json({ ok: true });

  // deno-lint-ignore no-explicit-any
  let note: any;
  try {
    const body = await req.json();
    note = JSON.parse(atob(body.message.data));
  } catch {
    return json({ ok: true }); // not something Pub/Sub should resend
  }
  if (note.packageName !== androidPackage()) return json({ ok: true });

  const sb = admin();
  try {
    const event = playEventName(note);
    const voided = note.voidedPurchaseNotification;
    if (typeof voided?.purchaseToken === "string") {
      const now = new Date().toISOString();
      const { data: rows } = await sb.from("purchases")
        .update({
          status: "revoked",
          revoked_at: now,
          revoke_reason: voided.refundType === 2 ? "partial_refund" : "refund",
          will_renew: false,
          updated_at: now,
        })
        .eq("platform", "android")
        .eq("purchase_token", voided.purchaseToken)
        .select("user_id");
      await logEvent(sb, {
        user_id: rows?.[0]?.user_id ?? null,
        platform: "android",
        event,
        transaction_id: typeof voided.orderId === "string"
          ? voided.orderId
          : null,
        purchase_token: voided.purchaseToken,
      });
      return json({ ok: true });
    }

    const sub = note.subscriptionNotification;
    const one = note.oneTimeProductNotification;
    const token: unknown = sub?.purchaseToken ?? one?.purchaseToken;
    const productId: unknown = sub?.subscriptionId ?? one?.sku;
    if (typeof token !== "string" || !validProductId(productId)) {
      return json({ ok: true }); // e.g. a test notification
    }

    const result = await playPurchase(productId, token);
    if (!result) return json({ ok: true });
    const now = new Date().toISOString();
    if (event === "subscription.revoked") {
      result.status = "revoked";
      result.revokedAt = now;
      result.revokeReason = "revoked";
      result.willRenew = false;
    }

    // Whose purchase: an earlier record with this token (or the one it
    // replaced), else the account ID the app passed to Google Play.
    let userId: string | null = null;
    for (const t of [token, result.linkedPurchaseToken]) {
      if (!t || userId) continue;
      const { data } = await sb.from("purchases").select("user_id")
        .eq("platform", "android").eq("purchase_token", t)
        .limit(1).maybeSingle();
      userId = data?.user_id ?? null;
    }
    if (!userId && result.accountId && await userExists(sb, result.accountId)) {
      userId = result.accountId;
    }

    // Bring every record of this purchase up to date...
    await sb.from("purchases").update({
      status: result.status,
      expires_at: result.expiresAt,
      environment: result.environment,
      will_renew: result.willRenew,
      ...(result.revokedAt
        ? { revoked_at: result.revokedAt, revoke_reason: result.revokeReason }
        : {}),
      verified: true,
      updated_at: now,
    }).eq("platform", "android").eq("purchase_token", token);
    // ...and record a renewal's new order, if it is new.
    await saveRecord(sb, {
      user_id: userId,
      platform: "android",
      ...storeFields(result),
      purchase_token: token,
    });
    await logEvent(sb, {
      user_id: userId,
      platform: "android",
      event,
      transaction_id: result.transactionId,
      purchase_token: token,
    });
    return json({ ok: true });
  } catch (e) {
    console.error("google-notifications", e);
    return json({ error: "retry" }, 500); // Pub/Sub retries
  }
});
