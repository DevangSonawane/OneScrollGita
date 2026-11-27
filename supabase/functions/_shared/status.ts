// Pure helpers shared by the functions (tested in status_test.ts).

/** What the support record says about a purchase. */
export type PurchaseStatus =
  | "active"
  | "grace"
  | "on_hold"
  | "paused"
  | "canceled"
  | "expired"
  | "pending"
  | "revoked";

/** A purchase as the store reports it. */
export interface StoreResult {
  productId: string;
  transactionId: string;
  originalTransactionId: string | null;
  environment: "production" | "sandbox";
  expiresAt: string | null;
  status: PurchaseStatus;
  /** The account ID the app passed to the store, if any. */
  accountId: string | null;
  /** Google Play: the token of the purchase this one replaced. */
  linkedPurchaseToken?: string | null;
  /** Whether a subscription will renew; null for one-time or unknown. */
  willRenew: boolean | null;
  revokedAt: string | null;
  revokeReason: string | null;
}

/** Apple's revocationReason codes. */
export function appleRevokeReason(code: unknown): string | null {
  if (code === 1) return "app_issue";
  if (code === 0) return "other";
  return null;
}

/** Subscriptions end in _monthly or _yearly; the rest are one-time. */
export function isSubscription(productId: string): boolean {
  return /_(monthly|yearly)$/.test(productId);
}

/** Product IDs look like sadhak_yearly. */
export function validProductId(id: unknown): id is string {
  return typeof id === "string" && /^[a-z0-9_.]{1,100}$/.test(id);
}

/** An App Store transaction (decoded JWS payload) as a store result. */
// deno-lint-ignore no-explicit-any
export function fromAppleTransaction(tx: any, now = Date.now()): StoreResult {
  const expires = typeof tx.expiresDate === "number" ? tx.expiresDate : null;
  let status: PurchaseStatus = "active";
  if (tx.revocationDate) status = "revoked";
  else if (expires !== null && expires < now) status = "expired";
  return {
    productId: String(tx.productId),
    transactionId: String(tx.transactionId),
    originalTransactionId: tx.originalTransactionId
      ? String(tx.originalTransactionId)
      : null,
    environment: tx.environment === "Production" ? "production" : "sandbox",
    expiresAt: expires === null ? null : new Date(expires).toISOString(),
    status,
    accountId: typeof tx.appAccountToken === "string"
      ? tx.appAccountToken.toLowerCase()
      : null,
    willRenew: null, // filled from the renewal info for subscriptions
    revokedAt: typeof tx.revocationDate === "number"
      ? new Date(tx.revocationDate).toISOString()
      : null,
    revokeReason: tx.revocationDate
      ? appleRevokeReason(tx.revocationReason) ?? "unknown"
      : null,
  };
}

/** Google Play subscriptionsv2 subscriptionState as a status. */
export function playSubscriptionStatus(state: unknown): PurchaseStatus {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return "active";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "grace";
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return "on_hold";
    case "SUBSCRIPTION_STATE_PAUSED":
      return "paused";
    case "SUBSCRIPTION_STATE_CANCELED":
      return "canceled";
    case "SUBSCRIPTION_STATE_PENDING":
      return "pending";
    default:
      return "expired";
  }
}

/** Google Play one-time purchaseState (0 bought, 1 cancelled, 2 pending). */
export function playProductStatus(state: unknown): PurchaseStatus {
  if (state === 0) return "active";
  if (state === 2) return "pending";
  return "revoked";
}

/** A Google Play subscriptionsv2 response as a store result. */
export function fromPlaySubscription(
  // deno-lint-ignore no-explicit-any
  sub: any,
  productId: string,
  transactionFallback: string,
): StoreResult {
  // deno-lint-ignore no-explicit-any
  const items: any[] = Array.isArray(sub.lineItems) ? sub.lineItems : [];
  const line = items.find((l) => l.productId === productId) ?? items[0] ?? {};
  return {
    productId: String(line.productId ?? productId),
    transactionId: String(sub.latestOrderId ?? transactionFallback),
    originalTransactionId: null,
    environment: sub.testPurchase ? "sandbox" : "production",
    expiresAt: line.expiryTime ?? null,
    status: playSubscriptionStatus(sub.subscriptionState),
    accountId: sub.externalAccountIdentifiers?.obfuscatedExternalAccountId
      ?.toLowerCase() ?? null,
    linkedPurchaseToken: sub.linkedPurchaseToken ?? null,
    willRenew: typeof line.autoRenewingPlan?.autoRenewEnabled === "boolean"
      ? line.autoRenewingPlan.autoRenewEnabled
      : null,
    revokedAt: null, // Play reports refunds as voided-purchase notifications
    revokeReason: null,
  };
}

/** A Google Play one-time product purchase as a store result. */
export function fromPlayProduct(
  // deno-lint-ignore no-explicit-any
  p: any,
  productId: string,
  transactionFallback: string,
): StoreResult {
  return {
    productId,
    transactionId: String(p.orderId ?? transactionFallback),
    originalTransactionId: null,
    environment: p.purchaseType === 0 ? "sandbox" : "production",
    expiresAt: null,
    status: playProductStatus(p.purchaseState),
    accountId: p.obfuscatedExternalAccountId?.toLowerCase() ?? null,
    willRenew: null,
    revokedAt: null,
    revokeReason: p.purchaseState === 1 ? "canceled" : null,
  };
}

/** Compares secrets without leaking where they differ. */
export function sameSecret(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diff === 0;
}

/** A short stand-in transaction ID for a Play purchase with no order ID. */
export async function tokenKey(purchaseToken: string): Promise<string> {
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(purchaseToken),
  );
  return "pt:" +
    [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, "0"))
      .join("");
}

/** Google Play subscription notificationType codes as event names. */
const PLAY_SUBSCRIPTION_EVENTS: Record<number, string> = {
  1: "recovered",
  2: "renewed",
  3: "canceled",
  4: "purchased",
  5: "on_hold",
  6: "in_grace_period",
  7: "restarted",
  8: "price_change_confirmed",
  9: "deferred",
  10: "paused",
  11: "pause_schedule_changed",
  12: "revoked",
  13: "expired",
  17: "items_changed",
  19: "price_change_updated",
  20: "pending_purchase_canceled",
};

/** A Play notification as one event name, e.g. subscription.renewed. */
// deno-lint-ignore no-explicit-any
export function playEventName(note: any): string {
  if (note.voidedPurchaseNotification) {
    return "voided." +
      (note.voidedPurchaseNotification.refundType === 2 ? "partial" : "full");
  }
  const sub = note.subscriptionNotification;
  if (sub) {
    return "subscription." +
      (PLAY_SUBSCRIPTION_EVENTS[sub.notificationType] ??
        String(sub.notificationType));
  }
  const one = note.oneTimeProductNotification;
  if (one) {
    return "one_time." +
      (one.notificationType === 1
        ? "purchased"
        : one.notificationType === 2
        ? "canceled"
        : String(one.notificationType));
  }
  return "test";
}

/** An App Store notification as one event name, e.g. DID_RENEW. */
export function appleEventName(type: unknown, subtype: unknown): string {
  const t = typeof type === "string" ? type : "UNKNOWN";
  return typeof subtype === "string" && subtype ? `${t}.${subtype}` : t;
}
