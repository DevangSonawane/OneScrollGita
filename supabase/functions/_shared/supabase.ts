import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.49.4";

import { env } from "./env.ts";
import type { StoreResult } from "./status.ts";

/** The service-role client. Bypasses row level security: server only. */
export function admin(): SupabaseClient {
  const key = env("SUPABASE_SERVICE_ROLE_KEY") ?? env("SUPABASE_SECRET_KEY");
  return createClient(env("SUPABASE_URL")!, key!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** The signed-in caller's user ID, from their access token. */
export async function callerId(
  req: Request,
  sb: SupabaseClient,
): Promise<string | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await sb.auth.getUser(token);
  return error ? null : data.user?.id ?? null;
}

/** True when the account still exists. */
export async function userExists(
  sb: SupabaseClient,
  id: string,
): Promise<boolean> {
  if (!/^[0-9a-f-]{36}$/.test(id)) return false;
  const { data } = await sb.from("profiles").select("id").eq("id", id)
    .maybeSingle();
  return data !== null;
}

export interface RecordRow {
  user_id: string | null;
  product_id: string;
  platform: "ios" | "android";
  transaction_id: string;
  verified: boolean;
  status?: string | null;
  expires_at?: string | null;
  environment?: string | null;
  original_transaction_id?: string | null;
  purchase_token?: string | null;
  will_renew?: boolean | null;
  revoked_at?: string | null;
  revoke_reason?: string | null;
}

/** The record columns that come from a store answer. */
export function storeFields(r: StoreResult) {
  return {
    product_id: r.productId,
    transaction_id: r.transactionId,
    verified: true,
    status: r.status,
    expires_at: r.expiresAt,
    environment: r.environment,
    will_renew: r.willRenew,
    revoked_at: r.revokedAt,
    revoke_reason: r.revokeReason,
  };
}

export interface EventRow {
  user_id: string | null;
  platform: "ios" | "android";
  event: string;
  transaction_id?: string | null;
  original_transaction_id?: string | null;
  purchase_token?: string | null;
}

/** Notes one store notification in purchase_events. Never throws. */
export async function logEvent(sb: SupabaseClient, row: EventRow) {
  const { error } = await sb.from("purchase_events").insert({
    ...row,
    event: row.event.slice(0, 100),
  });
  if (error) console.error("purchase event", error);
}

/**
 * Writes one purchase record. A transaction already recorded stays with
 * the account that recorded it first; it is only brought up to date.
 */
export async function saveRecord(
  sb: SupabaseClient,
  row: RecordRow,
): Promise<"inserted" | "updated" | "other-account" | "no-account"> {
  const { data: existing, error } = await sb.from("purchases")
    .select("id, user_id")
    .eq("platform", row.platform)
    .eq("transaction_id", row.transaction_id)
    .maybeSingle();
  if (error) throw error;
  const { user_id, ...fields } = row;
  if (existing) {
    if (user_id && existing.user_id !== user_id) return "other-account";
    const { error: e } = await sb.from("purchases")
      .update({ ...fields, updated_at: new Date().toISOString() })
      .eq("id", existing.id);
    if (e) throw e;
    return "updated";
  }
  if (!user_id) return "no-account";
  const { error: e } = await sb.from("purchases").insert(row);
  if (e) throw e;
  return "inserted";
}
