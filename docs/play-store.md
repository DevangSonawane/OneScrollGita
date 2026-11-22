# Publishing One Scroll Gita on Google Play

Package name: `com.onescrollgita.app` (permanent once uploaded).
Version: 1.0.0 (build 1), set in `pubspec.yaml` as `version: 1.0.0+1`.
Raise the build number (`+2`, `+3` …) for every upload.

## 1. Create your upload key (once; keep it safe forever)

```bash
keytool -genkey -v -keystore ~/onescrollgita-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (it is git-ignored):

```
storePassword=<the password you chose>
keyPassword=<the password you chose>
keyAlias=upload
storeFile=/Users/<you>/onescrollgita-upload.jks
```

Back up the `.jks` file and the passwords. If you lose them, you can only
recover through Play App Signing support.

## 2. Build the bundle

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`. Without
`key.properties` the bundle is signed with the debug key and Play rejects it.

## 3. Play Console answers

- **App or game:** App. **Free or paid:** Free.
- **Category:** Books & Reference.
- **Ads:** No ads.
- **Privacy policy:** host `store/privacy-policy.html` (GitHub Pages, Google
  Sites or your website), fill in your email, paste the URL.
- **Data safety:** "No data collected" and "No data shared". The app has no
  INTERNET permission, no accounts and no analytics. Data is not encrypted in
  transit because nothing is transmitted.
- **Content rating questionnaire:** Reference / education. No violence,
  sexual content, gambling, user interaction or data sharing. Religious text
  only. Expected rating: Everyone / 3+.
- **Target audience:** 13 and over (avoids the extra Families policy
  requirements; the app is still fine for all ages).
- **News app:** No. **Government app:** No. **Financial features:** None.
- **Health:** None.
- **Permissions in the bundle:** only Google Play's install-referrer
  permission (used to open a shared verse after install).

## 4. Copyright

The scripture text is from vedabase.cc (Śrīla Prabhupāda's books; rights held
by The Bhaktivedanta Book Trust). Keep your written permission ready: Play can
ask for proof that you may publish it. The app credits the source in Profile →
Credits and in About.

## 5. Testing track

New personal developer accounts must run a closed test with at least 12
testers for 14 days before applying for production. Start with Internal
testing, install on a real Android phone, then Closed testing.

## 6. Shared links

A shared verse link is the Play Store page with the verse as the install
referrer:
`https://play.google.com/store/apps/details?id=com.onescrollgita.app&referrer=verse%3Dbg-02-047`

- Not installed: Play opens the install page; after install, the first
  launch opens that verse.
- Installed: Play shows "Open", which opens the app (at Home, not the verse;
  opening the exact verse needs a website domain with app links, see
  docs/sharing.md).

## Release 1.2.0 (11), 2026-11-21 (in progress)

- Bundle: `flutter build appbundle --release --build-name=1.2.0 --build-number=12 --dart-define-from-file=auth.env.json`
  (production was 10 / 1.1.0; pubspec stays on the iOS number). Signed with the upload key.
- Shravan subscriptions created and active: `shravan_yearly` (base plan `yearly`, ₹2,000)
  and `shravan_monthly` (base plan `monthly`, ₹500). Play allows the exact prices; the App
  Store uses ₹1,999 / ₹499.
- Target audience stays all ages (owner, 2026-11-21), so the Families policy applies.
- Data safety: draft saved with "collects data: yes", encrypted in transit, OAuth accounts.
  Blocked on a delete-account web page (Play requires the URL) and an updated privacy policy.
- The 80 MB bundle must be uploaded by hand (browser automation limit is 10 MB).
- Release notes draft (reviewed: false): "Listen to the Gita with the new Shravan audio plan:
  shlokas recited verse by verse and every chapter narrated. Optional sign-in with Google keeps
  your purchases safe. Reading stays free."
- Build 11 was blocked by Play: the portrait lock implied a required
  `android.hardware.screen.portrait`. The manifest now declares it with
  `required="false"`; rebuilt as 12. Remove bundle 11 from the draft and upload 12.
