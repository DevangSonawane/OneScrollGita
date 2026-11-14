# App Review notes (reply to Guideline 2.1, 2026-11-14)

Status: written by Claude Code, `reviewed: false`. Check every claim before pasting.

Paste the block below into App Store Connect → the 1.0.0 version → App Review
Information → **Notes** (limit 4,000 characters; this is about 2,900). Upload the
screen recording in the **Attachment** area of the same section, or paste an
unlisted link to it in place of the bracketed line.

---

1. SCREEN RECORDING
The attached recording starts from app launch and shows: first-launch welcome, today's verse, the reader (word meanings, English/Hindi switch, swiping between verses, purport), favourite and bookmark, sharing a verse as an image, turning on a local reminder (with the iOS permission prompt), the free shloka trainer verses, the paywall with both plans and "Restore purchase", and then the paid features unlocked: the reflection journal, a note on a verse, the shloka trainer on any verse, and the notebook PDF export.
The app has no accounts, no login and no user-generated content shared with anyone, so there is no registration, account deletion, reporting or blocking flow.

2. PURPOSE AND AUDIENCE
One Scroll Gita is an offline reader for the Bhagavad-gita As It Is by A.C. Bhaktivedanta Swami Prabhupada. It is for people who want to replace a few minutes of phone scrolling with reading one verse a day. It shows each verse in Sanskrit, transliteration and English or Hindi translation with the full purport, and helps the reader keep a daily habit, memorise verses and keep personal notes.

3. HOW TO USE IT
No login, credentials or sample files are needed. After a short welcome screen on first launch, the Home screen shows today's verse.
- Read: tap the verse or "Continue", then swipe up/down for next/previous verse. Tap "Purport" for the commentary.
- Language: the EN / हि switch at the top of Home and the reader, or Profile → Reading → Translation.
- Save: double-tap a verse or use the Favourite / Bookmark buttons. Lists are under Profile.
- Share: the share button creates an image of the verse.
- Reminders (optional): Profile → Reminders. Notification permission is asked only when switched on. Notifications are local.
- Paid features ("Sadhak" plan): the shloka trainer for any verse with spaced reviews, unlimited notes (10 are free), the reflection journal and PDF export of the user's notebook. Tapping any of these opens the paywall. Products: sadhak_yearly (auto-renewable, 1 year) and sadhak_lifetime_ios (non-consumable). "Restore purchases" is on the paywall. All scripture text, translations, purports, search and the daily verse are free.

4. EXTERNAL SERVICES
Only Apple's StoreKit / In-App Purchase for the Sadhak plan. The app has no server, no third-party SDKs, no analytics, no ads, no AI services and makes no network calls of its own. All texts are bundled in the app and it works fully offline.

5. REGIONAL DIFFERENCES
None. The app works the same in all regions. Only the plan price differs, as set by the App Store for each storefront.

6. THIRD-PARTY MATERIAL
The Bhagavad-gita As It Is text and purports are (c) The Bhaktivedanta Book Trust. They are used with permission and reproduced without alteration; the attribution is shown in the app at the bottom of Profile (Credits) and under Profile → About and credits.

---

## Before resubmitting (owner checklist)

- [x] Menu paths in section 3 checked in the Simulator (2026-11-14).
- [ ] Video: `store/ios/app-review-demo.mp4` (2 min 39 s) was recorded in the
      iOS Simulator with a debug build, not on a physical iPhone as Apple asked.
      The paid part was shown with the debug "Pretend premium" switch (cut out
      of the video), because a Sandbox purchase needs an Apple Account sign-in.
      Safer: record the same flow on a real iPhone with TestFlight and a
      Sandbox tester, including an actual purchase and restore.
- [ ] Bug found while recording and fixed in code: the iOS paywall listed two
      "Lifetime" plans (Apple still returns the old `sadhak_lifetime`). Build
      1.0.0 (6) has this bug. Build 7 (fixed, plus iOS widgets) was uploaded on 2026-11-14.
- [ ] Item 6: attach proof of permission for the BBT text (letter or email).
      This is the item most likely to block approval if missing.
- [ ] On the version page, confirm both in-app purchases are added under
      "In-App Purchases and Subscriptions" and are in "Ready to Submit"
      (Guideline 3.1.1 note in the rejection).
- [ ] The listing says "iPhone and iPad" in What's New, but the build is
      iPhone-only. Change it to "iPhone".
- [ ] Copy on Profile → Reminders says "allow background activity ... in your
      phone's battery settings", which is Android wording; consider hiding it on iOS.
- [ ] Select build 7 on the version page and resubmit.
