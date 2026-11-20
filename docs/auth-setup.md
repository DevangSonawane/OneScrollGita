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
2. SQL editor: paste and run `supabase/migrations/20261121_auth.sql`.
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
   **Client IDs** (comma separated), and turn on **Skip nonce check**
   (needed for Google sign-in on iOS).

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
  sandbox while signed in and check a row appears in `purchases`, sign
  out, sign in again, delete the account.
