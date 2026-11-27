# Account setup (Supabase, Apple, Google)

## Status (2026-11-21)

Done by Claude:
- Supabase project `one-scroll-gita` (ref `oijloaiknanuuhkefsti`, Mumbai, org
  "DevangSonawane's Org"). SQL applied. Apple and Google providers on, email
  sign-up off. Settings live in `supabase/config.toml` (`supabase config push`).
- Secrets, all git-ignored: `auth.env.json` (app keys for
  `--dart-define-from-file`), `supabase/.env` (Google web client secret, used
  by `config push`), `supabase/.db-password` (database password).
- Apple: Sign in with Apple is on for the App ID (via Xcode automatic
  signing); the profile includes it.
- Google Cloud project `one-scroll-gita-auth` (owner sonawane.devang@gmail.com,
  editor officialaniketjha@gmail.com). Consent screen published (In
  production). Clients: web, iOS, and Android for the upload key, debug key,
  Play App Signing key, and Play's post-quantum key.
  iOS URL scheme added to `Info.plist`.

Still to do (owner):
- The consent screen shows officialaniketjha@gmail.com as support email;
  change it on the Branding page if you want another address.
- Test on real phones (no simulator runtime on this Mac).

The steps below are the reference for doing it again from scratch.

Owner steps for PRD_v9. All of this is free: the Supabase free plan, Google
Cloud OAuth clients, and Sign in with Apple (included in the Apple
Developer membership you already have). Until these are done, builds
without the keys simply have no account features.

## 1. Supabase project

1. Create a project at supabase.com (free plan). Pick a region near your
   users (Mumbai for India).
2. SQL editor: paste and run `supabase/migrations/20261121_auth.sql`, then
   `supabase/migrations/20261125120000_harden.sql`. The third
   migration comes after the Edge Functions are deployed (section 3c);
   do both before releasing an app build made after 2026-11-25, since
   those builds send purchases to the functions.
   Authentication > Sign In / Providers: turn **off** Email, Phone and
   Anonymous sign-ins. Only Apple and Google stay on. Settings > API:
   leave only the `public` schema exposed (GraphQL is not used).
3. Project settings > API: copy the **Project URL** and the **publishable
   key** (or the legacy `anon` key). Both are safe in the app; row level
   security protects the data. Never put the `service_role`/secret key in
   the app.
4. Note: free projects pause after about a week with no activity. Any
   sign-in counts as activity; for a live app with few users, check it in
   the dashboard or move to the paid plan later.

## 2. Sign in with Apple (iOS)

1. developer.apple.com > Identifiers > `com.onescrollgita.app`: tick
   **Sign in with Apple**. (The app's entitlement is already added in
   `ios/Runner/Runner.entitlements`.) Regenerate provisioning profiles if
   Xcode asks.
2. Supabase > Authentication > Sign In / Providers > **Apple**: enable it and
   put `com.onescrollgita.app` in **Client IDs**. For native iOS sign-in no
   secret key is needed.

## 3. Sign in with Google (Android and iOS)

In Google Cloud Console (any project, e.g. the one used for Play):

1. OAuth consent screen: app name "One Scroll Gita", support email, the
   privacy policy URL. Scopes: email, profile, openid only. Publish it.
2. Credentials > Create OAuth client ID, three times:
   - **Web application**: this is `GOOGLE_WEB_CLIENT_ID`. No redirect URIs
     needed.
   - **Android**: package `com.onescrollgita.app` and the SHA-1 of **both**
     your upload key and the Play App Signing key (Play Console > Setup >
     App signing). Add the debug key's SHA-1 too for testing.
   - **iOS**: bundle ID `com.onescrollgita.app`. This is
     `GOOGLE_IOS_CLIENT_ID`.
3. iOS URL scheme: in `ios/Runner/Info.plist`, add the iOS client's
   **reversed client ID** (`com.googleusercontent.apps.XXXX`) as a second
   entry in `CFBundleURLSchemes`, next to `gitaapp`. Claude can do this once
   you share the ID.
4. Supabase > Authentication > Providers > **Google**: enable it, put the
   **Web** client ID first and the **iOS** client ID after it in
   **Client IDs** (comma separated), and leave **Skip nonce check** off.
   The app sends its own nonce with Google sign-in, which stops a Google
   token taken from elsewhere from being replayed. If you turned it on
   earlier: switch it off once the build with the nonce (2026-11-25) is the
   one in the stores, and test Google sign-in on iPhone and Android right
   after.

## 3b. Sign in with Apple on Android (optional)

Android has no Apple sheet, so it uses Apple's web page.

1. developer.apple.com > Identifiers > **Services IDs** > new, e.g.
   `com.onescrollgita.app.signin`. Tick Sign in with Apple, Configure:
   primary App ID `com.onescrollgita.app`, domain
   `<project>.supabase.co`, return URL
   `https://<project>.supabase.co/auth/v1/callback`.
2. Keys > new key with **Sign in with Apple** for that App ID. Download the
   `.p8` (only once) and note the Key ID and your Team ID.
3. Supabase > Providers > Apple: add the Services ID to **Client IDs**
   (after the bundle ID) and paste a **Secret Key** made from the `.p8`
   (Supabase's Apple page links a generator). Apple makes this secret
   expire after 6 months: put a reminder in your calendar to renew it.
4. Supabase > Authentication > URL Configuration > **Redirect URLs**: add
   `gitaapp://open/login-callback`.
5. Build with `--dart-define=APPLE_ON_ANDROID=true` (add it to
   `auth.env.json`). Without it Android shows Google only.

## 3c. Edge Functions and their secrets

The functions in `supabase/functions` check purchases with the stores,
take store notifications and revoke the Apple token on account deletion.

1. Deploy (from the repo root, logged in with `supabase login`):

   ```bash
   supabase functions deploy verify-purchase delete-account apple-token apple-notifications google-notifications
   ```

2. Then run `supabase/migrations/20261125130000_server_checks.sql` (after
   the deploy: from then on only the functions write purchase records).
3. Secrets: `supabase secrets set NAME=value`, or Dashboard > Edge
   Functions > Secrets. Each group is optional; without it that part
   quietly does less (records stay unchecked, or no Apple revoke).

   | Secret | What it is |
   | --- | --- |
   | `APPLE_TEAM_ID`, `APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_PRIVATE_KEY` | The Sign in with Apple key from 3b step 2 (the `.p8` contents on one line, newlines written as `\n`). Needed to revoke Apple tokens. |
   | `APPLE_SERVICES_ID` | The Services ID from 3b, if Android Apple sign-in is on. |
   | `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_PRIVATE_KEY` | App Store Connect > Users and Access > Integrations > **In-App Purchase** key. Checks App Store purchases. |
   | `GOOGLE_SERVICE_ACCOUNT_JSON` | A Google Cloud service account key (JSON, one line). In Play Console > Users and permissions, invite its email for One Scroll Gita only, with just "View financial data" (read-only; the server never refunds or cancels). Set up 2026-11-25 as `play-purchase-checker@one-scroll-gita-auth.iam.gserviceaccount.com` (Google Cloud project `one-scroll-gita-auth`, Play Developer API on, no billing needed). |
   | `GOOGLE_RTDN_TOKEN` | A long random string you make up (e.g. `openssl rand -hex 24`). Guards the Google notification URL. |

4. App Store Connect > the app > App Information > **App Store Server
   Notifications**: Version 2, production and sandbox URL
   `https://<project>.supabase.co/functions/v1/apple-notifications`.
5. Google Play: Google Cloud > Pub/Sub > create a topic, give
   `google-play-developer-notifications@system.gserviceaccount.com` the
   Publisher role on it, and set it in Play Console > Monetize >
   Monetization setup > Real-time developer notifications. Add a **push**
   subscription to the topic with endpoint
   `https://<project>.supabase.co/functions/v1/google-notifications?token=<GOOGLE_RTDN_TOKEN>`.
   Use "Send test notification" in Play Console; the function answers 200.
6. Support: in the SQL editor, `select * from support.purchases where
   email = '...'` and `select * from support.purchase_events where email =
   '...' order by received_at`.

## 4. Build with the keys

The keys are passed at build time and never committed:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_KEY=sb_publishable_xxxx --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com --dart-define=GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com
```

For store builds add the same four `--dart-define`s to `flutter build
appbundle` / `flutter build ipa`. Tip: keep them in a git-ignored
`auth.env.json` and pass `--dart-define-from-file=auth.env.json`.

## 5. Before release

- Privacy policy: add the account section (`docs/review-needed.md`).
- App Store Connect > App Privacy and Play Console > Data safety: email,
  name, user ID, purchase history; linked to the user; not for tracking.
  Play also asks for an account-deletion path: "Profile > Account > Delete
  account" in the app.
- `ios/Runner/PrivacyInfo.xcprivacy` still says no data is collected;
  update its collected data types to match the label.
- Test on a real iPhone and Android phone: sign in with each, buy in the
  sandbox while signed in and check a row appears in `purchases` with
  `verified = true`, sign out, sign in again, delete the account (with
  Apple: check the app disappears from Settings > Apple ID > Sign in with
  Apple on the iPhone). On Android with `APPLE_ON_ANDROID`, sign in with
  Apple and check the browser comes back to the app signed in.
