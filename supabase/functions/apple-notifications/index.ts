// apple-notifications: App Store Server Notifications V2 (renewals,
// refunds, expiries). Set its URL in App Store Connect.
// The posted payload is only a hint: the transaction is fetched again from
// the App Store before anything is written, so a forged post changes nothing.
import { decodeJwt } from "npm:jose@5.9.6";

import { json } from "../_shared/env.ts";
import {
  appStoreConfigured,
  appStoreTransaction,
} from "../_shared/stores.ts";
import { appleEventName } from "../_shared/status.ts";
import {
  admin,
  logEvent,
  saveRecord,
  storeFields,
  userExists,
} from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  if (!appStoreConfigured()) return json({ ok: true });

  let transactionId: string | null = null;
  let event = "UNKNOWN";
  try {
    const { signedPayload } = await req.json();
    const payload = decodeJwt(signedPayload) as {
      notificationType?: string;
      subtype?: string;
      data?: { signedTransactionInfo?: string };
    };
    event = appleEventName(payload.notificationType, payload.subtype);
    const info = payload.data?.signedTransactionInfo;
    if (info) {
      const id = decodeJwt(info).transactionId;
      transactionId = typeof id === "string" && id.length <= 200 ? id : null;
    }
  } catch {
    return json({ error: "bad request" }, 400);
  }
  if (!transactionId) return json({ ok: true }); // e.g. a TEST notification

  try {
    const result = await appStoreTransaction(transactionId);
    if (!result) return json({ ok: true });
    const sb = admin();
    // Whose purchase: an earlier record of the same subscription, else the
    // account ID the app passed to the App Store.
    let userId: string | null = null;
    if (result.originalTransactionId) {
      const { data } = await sb.from("purchases").select("user_id")
        .eq("platform", "ios")
        .eq("original_transaction_id", result.originalTransactionId)
        .limit(1).maybeSingle();
      userId = data?.user_id ?? null;
    }
    if (!userId && result.accountId && await userExists(sb, result.accountId)) {
      userId = result.accountId;
    }
    await saveRecord(sb, {
      user_id: userId,
      platform: "ios",
      ...storeFields(result),
      original_transaction_id: result.originalTransactionId,
    });
    await logEvent(sb, {
      user_id: userId,
      platform: "ios",
      event,
      transaction_id: result.transactionId,
      original_transaction_id: result.originalTransactionId,
    });
    return json({ ok: true });
  } catch (e) {
    console.error("apple-notifications", e);
    return json({ error: "retry" }, 500); // Apple retries
  }
});
