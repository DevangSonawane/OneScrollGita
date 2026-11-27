// Ask the App Store and Google Play about a purchase. Answers come straight
// from Apple's and Google's servers over HTTPS, so they are trusted as is.
import { decodeJwt, importPKCS8, SignJWT } from "npm:jose@5.9.6";

import { androidPackage, bundleId, env, pem } from "./env.ts";
import {
  fromAppleTransaction,
  fromPlayProduct,
  fromPlaySubscription,
  isSubscription,
  type StoreResult,
  tokenKey,
} from "./status.ts";

// ---- App Store Server API -------------------------------------------------

export function appStoreConfigured(): boolean {
  return !!(env("ASC_ISSUER_ID") && env("ASC_KEY_ID") &&
    pem("ASC_PRIVATE_KEY"));
}

async function appStoreToken(): Promise<string> {
  const key = await importPKCS8(pem("ASC_PRIVATE_KEY")!, "ES256");
  return await new SignJWT({ bid: bundleId() })
    .setProtectedHeader({ alg: "ES256", kid: env("ASC_KEY_ID")!, typ: "JWT" })
    .setIssuer(env("ASC_ISSUER_ID")!)
    .setAudience("appstoreconnect-v1")
    .setIssuedAt()
    .setExpirationTime("10m")
    .sign(key);
}

const APPLE_HOSTS = [
  "https://api.storekit.itunes.apple.com",
  "https://api.storekit-sandbox.itunes.apple.com",
];

/** The transaction from the App Store (production, then sandbox), or null. */
export async function appStoreTransaction(
  transactionId: string,
): Promise<StoreResult | null> {
  const token = await appStoreToken();
  for (const host of APPLE_HOSTS) {
    const res = await fetch(
      `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (res.status === 404) continue;
    // Production answers 401 until the app is live on the App Store;
    // its purchases can only be sandbox ones then.
    if (res.status === 401 && host === APPLE_HOSTS[0]) continue;
    if (!res.ok) throw new Error(`App Store answered ${res.status}`);
    const { signedTransactionInfo } = await res.json();
    const tx = decodeJwt(signedTransactionInfo);
    if (tx.bundleId !== bundleId()) return null;
    const result = fromAppleTransaction(tx);
    if (typeof tx.expiresDate === "number" && result.originalTransactionId) {
      result.willRenew = await appStoreWillRenew(
        host,
        token,
        result.originalTransactionId,
      );
    }
    return result;
  }
  return null;
}

/** The subscription's auto-renew setting, or null when unknown. */
async function appStoreWillRenew(
  host: string,
  token: string,
  originalTransactionId: string,
): Promise<boolean | null> {
  try {
    const res = await fetch(
      `${host}/inApps/v1/subscriptions/${
        encodeURIComponent(originalTransactionId)
      }`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!res.ok) return null;
    const body = await res.json();
    for (const group of body.data ?? []) {
      for (const last of group.lastTransactions ?? []) {
        if (last.originalTransactionId !== originalTransactionId) continue;
        if (!last.signedRenewalInfo) return null;
        const info = decodeJwt(last.signedRenewalInfo);
        return info.autoRenewStatus === 1;
      }
    }
  } catch (e) {
    console.error("renewal info", e);
  }
  return null;
}

// ---- Google Play Developer API --------------------------------------------

export function playConfigured(): boolean {
  return !!env("GOOGLE_SERVICE_ACCOUNT_JSON");
}

async function playToken(): Promise<string> {
  const sa = JSON.parse(env("GOOGLE_SERVICE_ACCOUNT_JSON")!);
  const key = await importPKCS8(sa.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/androidpublisher",
  })
    .setProtectedHeader({ alg: "RS256", kid: sa.private_key_id, typ: "JWT" })
    .setIssuer(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("10m")
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`Google token answered ${res.status}`);
  return (await res.json()).access_token;
}

/** The purchase from Google Play, or null when Play does not know it. */
export async function playPurchase(
  productId: string,
  purchaseToken: string,
): Promise<StoreResult | null> {
  const base =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
      encodeURIComponent(androidPackage())
    }/purchases`;
  const t = encodeURIComponent(purchaseToken);
  const url = isSubscription(productId)
    ? `${base}/subscriptionsv2/tokens/${t}`
    : `${base}/products/${encodeURIComponent(productId)}/tokens/${t}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${await playToken()}` },
  });
  if ([400, 404, 410].includes(res.status)) return null;
  if (!res.ok) throw new Error(`Google Play answered ${res.status}`);
  const body = await res.json();
  const fallback = await tokenKey(purchaseToken);
  return isSubscription(productId)
    ? fromPlaySubscription(body, productId, fallback)
    : fromPlayProduct(body, productId, fallback);
}
