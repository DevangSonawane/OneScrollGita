import { assertEquals } from "jsr:@std/assert@1";

import {
  appleEventName,
  fromAppleTransaction,
  playEventName,
  fromPlayProduct,
  fromPlaySubscription,
  isSubscription,
  playSubscriptionStatus,
  sameSecret,
  tokenKey,
  validProductId,
} from "./status.ts";

Deno.test("subscriptions are the monthly and yearly products", () => {
  assertEquals(isSubscription("sadhak_yearly"), true);
  assertEquals(isSubscription("shravan_monthly"), true);
  assertEquals(isSubscription("sadhak_lifetime"), false);
  assertEquals(isSubscription("shravan_lifetime_ios"), false);
});

Deno.test("product IDs are checked", () => {
  assertEquals(validProductId("sadhak_yearly"), true);
  assertEquals(validProductId("BAD ID"), false);
  assertEquals(validProductId(""), false);
  assertEquals(validProductId(42), false);
});

Deno.test("App Store transactions: active, expired, revoked", () => {
  const now = Date.UTC(2026, 10, 25);
  const base = {
    productId: "sadhak_yearly",
    transactionId: "2000000001",
    originalTransactionId: "2000000000",
    environment: "Sandbox",
    appAccountToken: "AAAAAAAA-0000-4000-8000-000000000001",
  };
  const active = fromAppleTransaction({ ...base, expiresDate: now + 1 }, now);
  assertEquals(active.status, "active");
  assertEquals(active.environment, "sandbox");
  assertEquals(active.accountId, "aaaaaaaa-0000-4000-8000-000000000001");
  assertEquals(active.originalTransactionId, "2000000000");
  assertEquals(
    fromAppleTransaction({ ...base, expiresDate: now - 1 }, now).status,
    "expired",
  );
  assertEquals(
    fromAppleTransaction({ ...base, revocationDate: now }, now).status,
    "revoked",
  );
  const lifetime = fromAppleTransaction(
    { ...base, productId: "sadhak_lifetime_ios", environment: "Production" },
    now,
  );
  assertEquals(lifetime.status, "active");
  assertEquals(lifetime.expiresAt, null);
  assertEquals(lifetime.environment, "production");
});

Deno.test("Google Play subscriptions", () => {
  const r = fromPlaySubscription({
    subscriptionState: "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
    latestOrderId: "GPA.1234-5678..1",
    lineItems: [{ productId: "shravan_yearly", expiryTime: "2027-01-01T00:00:00Z" }],
    testPurchase: {},
    externalAccountIdentifiers: { obfuscatedExternalAccountId: "ABC" },
    linkedPurchaseToken: "old",
  }, "shravan_yearly", "pt:x");
  assertEquals(r.status, "grace");
  assertEquals(r.transactionId, "GPA.1234-5678..1");
  assertEquals(r.environment, "sandbox");
  assertEquals(r.expiresAt, "2027-01-01T00:00:00Z");
  assertEquals(r.accountId, "abc");
  assertEquals(r.linkedPurchaseToken, "old");
  assertEquals(playSubscriptionStatus("SUBSCRIPTION_STATE_EXPIRED"), "expired");
  assertEquals(playSubscriptionStatus(undefined), "expired");
});

Deno.test("Google Play one-time products", () => {
  const r = fromPlayProduct(
    { purchaseState: 0, purchaseType: 0 },
    "sadhak_lifetime",
    "pt:abc",
  );
  assertEquals(r.status, "active");
  assertEquals(r.environment, "sandbox");
  assertEquals(r.transactionId, "pt:abc");
  assertEquals(fromPlayProduct({ purchaseState: 1 }, "x", "y").status, "revoked");
  assertEquals(fromPlayProduct({ purchaseState: 2 }, "x", "y").status, "pending");
});

Deno.test("secrets compare exactly", () => {
  assertEquals(sameSecret("abc", "abc"), true);
  assertEquals(sameSecret("abc", "abd"), false);
  assertEquals(sameSecret("abc", "abcd"), false);
});

Deno.test("token keys are short and stable", async () => {
  const k = await tokenKey("token");
  assertEquals(k, await tokenKey("token"));
  assertEquals(k.length, 67);
});

Deno.test("refunds and renewals are carried over", () => {
  const now = Date.UTC(2026, 10, 25);
  const tx = fromAppleTransaction({
    productId: "sadhak_yearly",
    transactionId: "1",
    revocationDate: now,
    revocationReason: 1,
  }, now);
  assertEquals(tx.revokedAt, new Date(now).toISOString());
  assertEquals(tx.revokeReason, "app_issue");
  assertEquals(tx.willRenew, null);
  const sub = fromPlaySubscription({
    subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
    lineItems: [{ productId: "sadhak_yearly", autoRenewingPlan: { autoRenewEnabled: false } }],
  }, "sadhak_yearly", "pt:x");
  assertEquals(sub.status, "canceled");
  assertEquals(sub.willRenew, false);
  assertEquals(fromPlayProduct({ purchaseState: 1 }, "x", "y").revokeReason, "canceled");
});

Deno.test("notification event names", () => {
  assertEquals(appleEventName("DID_RENEW", undefined), "DID_RENEW");
  assertEquals(appleEventName("REFUND", "VOLUNTARY"), "REFUND.VOLUNTARY");
  assertEquals(
    playEventName({ subscriptionNotification: { notificationType: 2 } }),
    "subscription.renewed",
  );
  assertEquals(
    playEventName({ oneTimeProductNotification: { notificationType: 2 } }),
    "one_time.canceled",
  );
  assertEquals(
    playEventName({ voidedPurchaseNotification: { refundType: 1 } }),
    "voided.full",
  );
  assertEquals(playEventName({ testNotification: {} }), "test");
});
