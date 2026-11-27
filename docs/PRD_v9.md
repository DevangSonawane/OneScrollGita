# Gita App: v9 PRD (Optional account: Sign in with Apple and Google)

Nov 21, 2026 · owner: @Devang · status: **built (V9-1); Supabase, Apple and Google set up; device testing pending**

Extends all earlier PRDs. Where it contradicts them, **this file wins**.
Scripture-text rules in `CLAUDE.md` still apply in full.

## 1. Overrides

| Earlier rule | v9 now |
| --- | --- |
| No accounts (v1, v5) | An **optional** account through Supabase Auth, using Sign in with Apple and Sign in with Google only (owner, 2026-11-21). |
| The app's own code makes no network calls (v3, v4) | The app may call the single configured Supabase project for sign-in, sign-out, account deletion and the purchase record (section 4). No other network use. |
| Profile: "No account" | Profile has an Account row (section 3). |
| Apple sign-in on iOS only; no server code (v9, 2026-11-21) | Owner, 2026-11-25: Apple sign-in on Android too (Apple's web page, behind `APPLE_ON_ANDROID`), and Supabase Edge Functions in the same project for purchase checks, store notifications, and the Apple token revoke on account deletion (sections 4 and 5). Their only outside calls are Apple's and Google's own APIs. |

Still true: no analytics, no tracking, no ads, no cloud sync. Reading,
search, streaks and everything the user made stay on the phone and work
without an account or internet. Scripture is never behind a sign-in.

## 2. Decisions (owner, 2026-11-21)

| # | Decision | Value |
| --- | --- | --- |
| 1 | Provider | Supabase Auth (free plan). |
| 2 | Sign-in methods | Apple and Google. Email/password is not built. |
| 3 | Where | A sign-up page right after the first-launch flow, and later from Profile. |
| 4 | Scope | Keep it basic: sign in, sign out, delete account, link purchases to the account. |

Claude's choices, for owner review:
- ~~The sign-up page can always be skipped ("Not now").~~ Owner decision
  (2026-11-22): the sign-up page is the last step of first launch and has
  no skip; new installs sign in with Apple or Google to finish. Claude
  flagged the risk: App Store guideline 5.1.1(v) lets reviewers reject apps
  that require a login for features that do not need an account, and a new
  install with no internet cannot get past this step. People who later sign
  out are not asked again.
- It is shown once, to new installs only. People updating from an earlier
  version are not interrupted; they find it in Profile.
- Sign in with Apple shows on iOS only. On Android it needs a web redirect
  set up in Supabase and Apple; not built (Google covers Android).
- Signing out or deleting the account never touches what is on the phone.

## 3. Screens

**Sign up** (`/signup`, after first launch). Heading "Keep your purchases
safe", one line explaining it is optional, "Continue with Apple" (iOS, the
official Apple button), "Continue with Google", "Not now". A short privacy
line. Errors show as one plain line under the buttons. Cancelling the
Apple or Google sheet just returns to the page, no error.

**Account** (`/profile/account`). Signed out: the same two buttons. Signed
in: name and email, how they signed in, "Sign out", "Delete account".
Delete asks first and says that a store subscription is cancelled in the
App Store or Google Play, not by deleting the account (Apple requires this).

## 4. Purchases

- When a signed-in user buys Sadhak or Shravan, the account's ID goes to
  the store with the purchase (`appAccountToken` on the App Store,
  obfuscated account ID on Google Play), so the store's own records link
  the purchase to the account.
- After a purchase, the app sends it (product, platform, store
  transaction ID, Google Play purchase token) to the `verify-purchase`
  function, which checks it with the App Store Server API / Google Play
  Developer API and keeps one row in `purchases`. Store notifications
  (App Store Server Notifications V2, Play real-time developer
  notifications) keep the row's status, expiry, renewal and refund up to
  date and add a line to `purchase_events`. It is a record for support
  only. **The app never unlocks anything from it**; the store stays the
  only source of truth and "Restore purchase" keeps working without an
  account.

## 5. Backend (Supabase)

`supabase/migrations/20261121_auth.sql`:
- `profiles` (id = auth user, created_at), created by a trigger on sign-up.
- `purchases` (user_id, product_id, platform, transaction_id, created_at),
  unique on (user_id, transaction_id).
- Row level security: a user reads and writes only their own rows.
- `delete_my_account()`: deletes the calling user (and their rows).

`supabase/migrations/20261125120000_harden.sql`: no access for signed-out
users, column limits, one record per store transaction (platform,
transaction_id), at most 200 records per account.

`supabase/migrations/20261125130000_server_checks.sql` (owner, 2026-11-25):
- `purchases` gains verified, status, expires_at, will_renew, revoked_at,
  revoke_reason, environment, original_transaction_id, purchase_token,
  updated_at and package (from the product ID). Only the functions write it;
  users still read their own rows.
- `purchase_events`: one row per store notification, pruned after a year.
- `apple_tokens`: the user's Apple refresh token, kept only to revoke it
  when the account is deleted.
- `support.purchases` and `support.purchase_events`: views by email for the
  owner in the dashboard; not reachable from the app.

Edge Functions (`supabase/functions`): `verify-purchase`, `delete-account`
(revokes the Apple token, then deletes; the app falls back to
`delete_my_account()` if it cannot reach it), `apple-token`,
`apple-notifications`, `google-notifications`.

Setup steps for the owner are in `docs/auth-setup.md`.

## 6. Configuration

Build-time values (`--dart-define`), never committed: `SUPABASE_URL`,
`SUPABASE_KEY` (publishable key), `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`,
and optionally `APPLE_ON_ANDROID=true`. Server keys (Apple, App Store
Connect, Google Play) are Supabase secrets, never in the app. Without
the first two the app has no account features at all (no sign-up page, no
Account row), so offline test builds keep working.

## 7. Store and legal

- App Store privacy label and Play Data Safety change from "Data not
  collected" to: email address, name, user ID, purchase history; linked to
  the user; not used for tracking.
- The privacy policy needs a section on the account (owner wording).
- In-app account deletion is built (required by Apple and Google Play).

## 8. Stages

- [x] V9-1: Supabase auth with Apple and Google, sign-up page after first
  launch, Account screen (sign out, delete), purchase linking, SQL, tests.
- [x] V9-3: hardening, server purchase checks, store notifications, Apple
  token revoke, Apple sign-in on Android, support columns and views.
- [ ] V9-2 (owner): Supabase project, Apple and Google console setup,
  privacy policy and store labels, test on real phones.
