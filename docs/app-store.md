# Publishing One Scroll Gita on the App Store

Bundle ID: `com.onescrollgita.app` (same as the Android application id).
Team ID in the Xcode project: `5MU65B6U3F` (Aniket Jha). Check it is the team of the Apple
Developer account you publish with; if not, pick the right team in Xcode →
Runner target → Signing & Capabilities.
Version comes from `pubspec.yaml` (`1.0.0+2` → version 1.0.0, build 2).
Raise the build number for every upload.

Status: written by Claude Code, `reviewed: false`.

## Already done in the project

- iOS display name "One Scroll Gita", app icon (1024 px, no alpha), launch screen.
- `ITSAppUsesNonExemptEncryption = false` in `ios/Runner/Info.plist`: the
  app uses no encryption of its own, so no export-compliance question per
  upload.
- App privacy manifest `ios/Runner/PrivacyInfo.xcprivacy`: no tracking, no
  data collected; declares UserDefaults (CA92.1) and file timestamps (C617.1).
- Android-only code (install referrer, home-screen widgets, Play purchase
  history) is skipped on iOS.

## 1. In Xcode (once, needs your Apple ID)

1. Xcode → Settings → Accounts → add the Apple ID of the developer account.
2. `open ios/Runner.xcworkspace` → Runner target → Signing & Capabilities:
   Team = your team, "Automatically manage signing" on.
3. Add the **In-App Purchase** capability (needed for the Sadhak plan).

## 2. App Store Connect

1. Apps → + → New App: platform iOS, name "One Scroll Gita", primary
   language English, bundle ID `com.onescrollgita.app`, SKU e.g.
   `onescrollgita-ios`.
2. Agreements, Tax and Banking: accept the Paid Apps agreement and add bank
   and tax details (required before any in-app purchase works, even in
   sandbox).
3. In-App Purchases → create `sadhak_lifetime` (Non-Consumable).
   Subscriptions → create a group "Sadhak" and `sadhak_yearly`
   (auto-renewable, 1 year). Same ids as Play. Add a review screenshot of
   the paywall to each.
4. App Privacy: "Data Not Collected".
5. Age rating questionnaire: all "None" → 4+.
6. Category: Books (secondary: Reference).
7. Privacy policy URL: the same hosted `store/privacy-policy.html` as on Play.
8. Listing text: `store/app-store-listing.md`.

## 3. Build and upload

```bash
flutter build ipa --release
```

Then open `build/ios/archive/Runner.xcarchive` in Xcode (Organizer) →
Distribute App → App Store Connect → Upload. Or drag
`build/ios/ipa/*.ipa` into Apple's Transporter app.

## 4. TestFlight

The upload shows up in TestFlight after processing. Add yourself as an
internal tester and test on a real iPhone: reading, reminders, sharing, PDF
export, and buy / restore with a Sandbox account (App Store Connect → Users
and Access → Sandbox).

## 5. Screenshots

Apple does not accept the 1080 x 1920 Play screenshots. Required:
- iPhone 6.9": 1320 x 2868 (iPhone 17 Pro Max simulator), `store/ios/iphone/`.
- iPad 13": 2064 x 2752 (the app also runs on iPad), `store/ios/ipad/`.

## Links

- Paywall: Privacy https://onescrollgita.asynk.in/privacy; Terms = Apple's
  standard EULA on iOS (`AppLinks.termsUrl`). In App Store Connect leave the
  EULA field on "Apple's standard license agreement".
- Shared verse links on iPhone: the App Store page once `AppLinks.appStoreId`
  is set (App Store Connect → App Information → Apple ID).

## Decisions made during the first submission (2026-11-13)

- **Lifetime product id on iOS is `sadhak_lifetime_ios`.** `sadhak_lifetime` was
  used and deleted in App Store Connect, and Apple never frees a deleted id.
  Play keeps `sadhak_lifetime`; the app queries both (`SadhakProducts.all`).
- **Prices:** yearly ₹699, lifetime ₹1,999 (India base; Apple sets the rest).
- **iPhone-only** (`TARGETED_DEVICE_FAMILY = 1`) from build 4, so no iPad
  screenshots are needed. iPads still run it in iPhone mode.
- **App icon** generated from `store/icon-512.png`, scaled up to 1024 (build 6
  onward; builds 2-5 carry the Flutter default icon and must not be submitted).
  Replace with a native 1024 px original when available.
- **Screenshots:** `store/ios/iphone-6.3/` (1206 x 2622, uploaded) and
  `store/ios/iphone-6.9/` (1320 x 2868). Review screenshot for both products:
  `store/ios/review-paywall.jpg`.
- No App Store feature graphic exists; the optional product-page header asset
  needs 3840 x 1646 or larger, so the 1024 x 500 Play graphic is not used.

## Build 7 (2026-11-14)

- **Home-screen widgets on iOS** to match Android: "Verse of the day" and
  "Continue reading" (`ios/VerseWidgets/`, WidgetKit extension
  `com.onescrollgita.app.VerseWidgets`). The app shares data with it through
  the App Group `group.com.onescrollgita.app` (entitlements on both targets;
  privacy manifests declare UserDefaults reason 1C8F.1).
- The paywall asks each store only for its own lifetime id, which fixes the
  duplicate "Lifetime" plan on iOS.
- The Android-only battery tip on the Reminders screen is hidden on iOS.
- Uploaded to App Store Connect from Xcode on 2026-11-14.
