// verify-purchase: the app sends a purchase it just received from the store;
// this checks it with the App Store / Google Play and keeps a support record
// (PRD_v9 section 4). The app never unlocks anything from the record.
import { json } from "../_shared/env.ts";
import { validProductId } from "../_shared/status.ts";
import {
  appStoreConfigured,
  appStoreTransaction,
  playConfigured,
  playPurchase,
} from "../_shared/stores.ts";
import {
  admin,
  callerId,
  saveRecord,
  storeFields,
} from "../_shared/supabase.ts";
import { tokenKey } from "../_shared/status.ts";

const str = (v: unknown, max: number) =>
  typeof v === "string" && v.length > 0 && v.length <= max ? v : null;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const sb = admin();
  const userId = await callerId(req, sb);
  if (!userId) return json({ error: "not signed in" }, 401);

  const body = await req.json().catch(() => null);
  const platform = body?.platform;
  const productId = body?.productId;
  const transactionId = str(body?.transactionId, 200);
  const purchaseToken = str(body?.purchaseToken, 4096);
  if (
    (platform !== "ios" && platform !== "android") || !validProductId(productId)
  ) {
    return json({ error: "bad request" }, 400);
  }

  try {
    if (platform === "ios") {
      if (!transactionId) return json({ error: "no transaction" }, 400);
      if (!appStoreConfigured()) {
        // Keys not set up yet: keep an unchecked record, as before.
        await saveRecord(sb, {
          user_id: userId,
          product_id: productId,
          platform,
          transaction_id: transactionId,
          verified: false,
        });
        return json({ verified: false });
      }
      const result = await appStoreTransaction(transactionId);
      if (!result) return json({ verified: false, error: "unknown" }, 404);
      return await save(result, null);
    }

    if (!purchaseToken) return json({ error: "no purchase token" }, 400);
    if (!playConfigured()) {
      await saveRecord(sb, {
        user_id: userId,
        product_id: productId,
        platform,
        transaction_id: transactionId ?? await tokenKey(purchaseToken),
        verified: false,
        purchase_token: purchaseToken,
      });
      return json({ verified: false });
    }
    const result = await playPurchase(productId, purchaseToken);
    if (!result) return json({ verified: false, error: "unknown" }, 404);
    return await save(result, purchaseToken);
  } catch (e) {
    console.error("verify-purchase", e);
    return json({ error: "store unavailable" }, 502);
  }

  async function save(
    result: Awaited<ReturnType<typeof appStoreTransaction>> & object,
    token: string | null,
  ) {
    if (result.productId !== productId) {
      return json({ verified: false, error: "product mismatch" }, 409);
    }
    // Bought while signed in to a different account.
    if (result.accountId && result.accountId !== userId) {
      return json({ verified: false, error: "other account" }, 403);
    }
    const outcome = await saveRecord(sb, {
      user_id: userId,
      platform,
      ...storeFields(result),
      original_transaction_id: result.originalTransactionId,
      purchase_token: token,
    });
    if (outcome === "other-account") {
      return json({ verified: false, error: "other account" }, 403);
    }
    return json({ verified: true, status: result.status });
  }
});
