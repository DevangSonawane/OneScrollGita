# Needs owner review (v2)

Everything here was written or set up by Claude Code and is marked
`reviewed: false` where the data allows it. Nothing below blocks development;
all of it must be checked **before release**.

## Must be verified before release

| Item | Where | What to check |
| --- | --- | --- |
| **Crisis helpline number** | `lib/core/config/helpline.dart` | Left **empty on purpose** (Claude Code must not invent a number). While empty, sensitive searches show the care message without a call line. Add a verified local number and service name. |
| Share link | `lib/core/config/app_links.dart` → `shareLink` | Empty for now, so the streak caption has no link. Set the store link. |
| Real-device notifications | — | Not tested on a phone. Check on at least one Android and one iPhone: a reminder arrives at the chosen time, tapping opens the app (verse notifications open that verse), reading a verse cancels the evening nudge, reminders survive a restart. |
| Release manifest | `android/app/src/main/AndroidManifest.xml` | After the first release build, confirm the **merged** release manifest has no `INTERNET` permission (main manifest has none; only debug/profile do). |

## v3: source data notes

| Item | Where | What to check |
| --- | --- | --- |
| Hindi word meanings, 2.4 | vedabase.cc source (`tool/.cache/vedabase_cc/hi/bg/2/4.json`) | A comma separates two pairs where a semicolon belongs. The app shows the English list for this verse. If vedabase.cc fixes it, re-run the importer. |
| Hindi word meanings, 13.8-12 | `tool/.cache/vedabase_cc/hi/bg/13/8-12.json` | One word has no meaning. Same fallback to English. |
| v3 paywall, stores, copy | `docs/PRD_v3.md` section 10 | Create `sadhak_yearly` and `sadhak_lifetime` in Play Console and App Store Connect, set prices, add testers. |
| Terms and privacy URLs | `lib/core/config/app_links.dart` | Privacy: https://onescrollgita.asynk.in/privacy (both stores). Terms: Apple standard EULA on iOS; Android has no terms link yet. Check the privacy page mentions store purchases. |
| Paywall wording | `lib/features/premium/paywall_screen.dart`, `lib/domain/premium.dart` (reason lines) | Headline, benefits, badges ("Recommended", "One-time"), terms line, welcome text. |
| `INTERNET` permission from Play Billing | Play Console data-safety form | Kept by owner decision. Declare Google Play Billing's diagnostic data in the data-safety form. |
| Real purchase test | phone + test track | Buy, cancel, pending, restore, and a lapsed yearly plan on Android. |
| Trainer and study wording | `lib/features/trainer/`, `lib/features/study/` | Step prompts, empty states, "Learned" text, notebook cover and footer. |
| Free limits | `lib/domain/premium.dart` (`FreeLimits`) | 10 notes; trainer verses 2.47, 4.7, 18.66. |
| PDF on a phone | Profile → Export my Gita notebook | Create and share a PDF; open it in a PDF viewer. Text in it is an image, so not selectable. |

## Written content (wording)

| Item | Where | Notes |
| --- | --- | --- |
| Message bank, 564 messages | `assets/messages/messages.json` | Original wording, no quotations. Validated by `dart run tool/validate_messages.dart`. Check tone. |
| Hindi for every message | same file, `hi` fields | Needs a native speaker. |
| 18 chapter summaries (EN + HI) | `assets/summaries/summaries.json` | Written only from the bundled translations of each chapter, 198-249 words each. Shown with "Summary. Not part of Srila Prabhupada's text." Hindi needs a native speaker. **Needs owner review before release.** |
| Theme map, 105 themes | `assets/search/themes.json`, `docs/theme-review.csv` | Every verse was found with FTS keyword search of the dataset and kept only when its translation addresses the theme. Mark each CSV row yes/no. Hindi titles and Hinglish synonyms also need a look. A "gratitude" theme was dropped because no verse text clearly addressed it. |
| Spelling aliases | `assets/search/aliases.json` | Common spellings mapped to the dataset's transliterated spellings (for example `krishna` → `kṛṣṇa`). Built from words that occur in the dataset. |
| Sensitive-query word list | `lib/domain/search/sensitive.dart` | English, Hindi and Hinglish phrases. Add any you think are missing. |

## Defaults chosen (PRD said "use the default and note it")

- Popup wording avoids "watching"; uses "Krishna is pleased with your effort."
- Milestone popups: 4-5 messages per milestone (1, 3, 7, 21, 40, 108, 365), rotated by date.
- Comeback messages never mention the length of the gap.
- An extra preference `lastOpenedDate` was added; the notification back-off (3 / 7 / 30 days) needs it.
- Notification channels: "Daily reading reminder" (invite, reflection, comeback), "Streak nudges", "Verse of the day".
- Notification icon: a plain open-book vector (`android/app/src/main/res/drawable/ic_notification.xml`). Replace with a branded monochrome icon if you like.
- Search suggestions show the first 12 themes.
- There is no CI in this repository yet. The validators are ready to run in CI: `dart run tool/validate_scripture.dart`, `dart run tool/validate_messages.dart`, `dart run tool/validate_content.dart`.

## Not done yet (on your instruction)

`flutter test`, debugging and building an APK were deferred until everything
was written. The new tests are written but have **not been run**.

## App Store (iOS)

| Item | Where | What to check |
| --- | --- | --- |
| App Store listing text | `store/app-store-listing.md` | Subtitle, keywords, description (adapted from the Play listing; widgets removed, streak/notification claim changed). |
| Paywall terms and privacy links | `lib/core/config/app_links.dart` | Set (Apple standard EULA + hosted privacy page). Build 2 on App Store Connect predates this; upload build 3. |
| Shared links on iPhone | `lib/core/config/app_links.dart` → `appStoreId` | iOS shares the App Store page once `appStoreId` is filled in; until then it shares the Play link. |
| Sadhak products in App Store Connect | `docs/app-store.md` section 2 | `sadhak_yearly` (subscription), `sadhak_lifetime` (non-consumable), Paid Apps agreement. |
| Signing team | Xcode → Runner → Signing | Project has team `5MU65B6U3F` (Aniket Jha); confirm it is the publishing account. |

## v4: Shravan audio (UI preview built)

| Item | Where | What to check |
| --- | --- | --- |
| Try the audio UI | Debug build → Listen pill | Library, player, mini player, sleep timer, Sanskrit-only, repeat, summary playback. Audio is silent with estimated lengths. |
| Recordings: file layout | — | One file per shloka, or one per chapter? Voice only, or with music? |
| Two samples | — | Send one shloka and one translation recording to tune compression by ear. |
| Library copy | `lib/features/listen/` | "The Gita, recited. Each shloka, then its meaning." and player labels. |
| Summaries before recording | `assets/summaries/summaries.json` | Review the written summaries before they are narrated. |

## v5 (stages V5-1, V5-2): check on real phones

| Item | What to check |
| --- | --- |
| Tests | `flutter test` was not run for V5-1/V5-2 (owner deferred it to the simulator session). Run it first. |
| Notifications, iPhone | Reminders on, tap "Send a test notification", lock the phone: it arrives in about 5 s. Then set the reminder 2-3 minutes ahead and close the app. |
| Notifications, Android | Same as iPhone. On Android 14+, the "Deliver at the exact time" row appears; turn it on in the system page and confirm reminders arrive on the minute. If they still arrive late on Xiaomi/Oppo/Vivo/Samsung, allow background activity in battery settings. |
| Play Console | The app now declares `SCHEDULE_EXACT_ALARM` (not `USE_EXACT_ALARM`). No declaration form is needed for it, but check the pre-launch report. |
| Type ramp | Shloka 22, transliteration 17 (was 15), translation 18. Check the reader, Home daily verse, purport, Shravan player and the share image at small and large reading sizes. |
| Nav pill | Hide it by scrolling down a long verse, then swipe back one verse: it must come back immediately. |
| Swiping | Swipe through a chapter quickly; it should feel smoother. Pull-to-turn on long verses now needs a shorter pull. |
| PRD_v5 | Draft. Confirm decisions in section 2 and pick the free-trial length. |

## v5 (stages V5-3 to V5-7)

| Item | Where | What to check |
| --- | --- | --- |
| First-launch answers | `lib/domain/first_launch.dart` | reviewed:false. Peace -> "peace" theme (first verse 2.66), Guidance -> "confusion", Study -> "knowledge", Learning by heart -> "study". Check each first verse fits. |
| First-launch copy | `lib/features/first_launch/welcome_screen.dart` | "What brings you to the Gita?", option hints, "Your first verse", "Day 1. A beginning.", "Remind me at ...". |
| Home | `lib/features/home/home_screen.dart` | Continue button position above the nav pill; "How are you feeling?" card wording and the five themes shown. "A verse for you" card not built: say yes or no. |
| Chapter end | reader | "Take a moment, then go on when you are ready." and "Reflect on this chapter". Free users get a note (not the journal). |
| Free trials | Play Console, App Store Connect | Create the trial offers and pick the length. Then open the paywall on a real phone: "7 days free, then ₹X a year" and "Start free trial" should appear; without a trial, nothing about trials shows. |
| Trial terms wording | `lib/features/premium/paywall_screen.dart` | "... Cancel before the trial ends in Google Play / your App Store settings and you will not be charged." Legal check. |
| Screenshot captions | `store/v5-screenshot-captions.md` | Draft only, for later. Hindi captions still to write. |

## v6

| Item | Where | What to check |
| --- | --- | --- |
| Owner preview flag | `lib/core/config/build_flags.dart` | Never build a store upload with `--dart-define=OWNER_PREVIEW=true`. Profile shows a red "Owner preview build" row when it is on. |
| Monk figure | `lib/features/premium/figure_art.dart` | Look on both paywalls, light and dark. |
| Lock screen widgets | iOS lock screen > Customize | Verse of the day (inline, rectangle, lotus circle) and Continue reading. |

## v9 (optional account)

| Item | Where | What to check |
| --- | --- | --- |
| Setup | `docs/auth-setup.md` | Done. Consent screen support email is officialaniketjha@gmail.com. |
| Sign-up copy | `lib/features/account/sign_up_screen.dart` | "Keep your purchases safe", the subline, the privacy line, "Not now". |
| Google button look | same file | Plain outlined button, no Google "G" logo yet. Google's brand rules prefer their logo; supply the asset or approve as is. |
| Delete wording | `lib/features/account/account_screen.dart` | Delete dialog text about cancelling store subscriptions (Apple requirement). |
| Privacy policy | `store/privacy-policy.html` | Add a section on the optional account (email, name, purchase record, deletion). Legal wording is yours. |
| Store labels | App Store Connect, Play Console | Change "Data not collected" to email, name, user ID, purchase history (linked, not tracking). Play: also add the account-deletion URL or in-app path. |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` | Still says no data collected. Update the collected data types to match the new App Store label. |
| Android Apple sign-in | — | Not built. Say if you want it. |

## v9: App Store resubmission (build 9, 2026-11-21)

| Item | Where | What to check |
| --- | --- | --- |
| App Review notes | `docs/app-review-notes-submit.txt` (pasted into App Store Connect) | `reviewed: false`. Rewritten by Claude Code for the optional account (sections 1, 3, 4). |
| App Privacy label and privacy manifest | App Store Connect > App Privacy; `ios/Runner/PrivacyInfo.xcprivacy` | Email, name, user ID, purchase history: linked to the user, app functionality, not tracking. |
| Privacy policy page | https://onescrollgita.asynk.in/privacy | Still needs an account section (Supabase sign-in, deletion). |
| Review video | `app-review-demo.mp4` | Recorded before sign-in existed; does not show the sign-up page. |
| Shravan subscription text | App Store Connect > Subscriptions > Shravan | Display name "Shravan Yearly"/"Shravan Monthly", description "Hear every shloka recited and every chapter told." Paywall badge "Flexible" on the monthly plan (`paywall_screen.dart`). |
| Shravan prices | App Store Connect | ₹1,999 / year and ₹499 / month (no ₹2,000 / ₹500 tier). Play Console products not created yet. |
| Play release notes 1.2.0 | `docs/play-store.md` | Draft "What's new" text. |
| Account deletion page | website `/delete-account` | Missing (404). Required by Play Data safety for apps with accounts. |

## Onboarding and sign-up redesign (2026-11-22)

| Item | Where | What to check |
| --- | --- | --- |
| Required sign-in, no skip | `lib/features/account/sign_up_screen.dart` | Owner decision. Risk: App Store rejection under guideline 5.1.1(v), and a new install with no internet cannot finish first launch. |
| Onboarding wording (reviewed: false) | `lib/features/first_launch/welcome_screen.dart`, `sign_up_screen.dart` | "Timeless wisdom, one verse at a time…", "Take a slow breath…", reminder text and "I will come back on my own", "Keep your journey safe" and the three benefit lines. |
| Intro numbers | welcome screen | Verses and chapters are counted from the dataset; "2 languages" means the English and Hindi translations. |
| Apple and Google buttons | `lib/features/account/sign_in_buttons.dart`, `brand_logos.dart` | Custom buttons drawn to each brand's guidelines (Apple logo from the sign_in_with_apple package, Google's four-colour G). Check them on a phone in light and dark mode. |
| Real-device sign-in | iPhone + Android | Apple and Google sheets open, finish, and land on Home. A sign-in with no reply now stops after 25 s with the offline line. |

## Onboarding v2: feature tour (2026-11-23)

| Item | Where | What to check |
| --- | --- | --- |
| New step order | `lib/features/first_launch/welcome_screen.dart` | Numbers → first verse + streak → swiping demo → Sadhak trainer demo → Shravan 1.1 → sign-in. The language choice, "What brings you here" and the reminder step were removed: language follows the phone (Hindi phones get Hindi), reminders are in Profile. |
| First verse | welcome screen | It is today's daily verse (the same one Home shows), so some days it is a less inviting verse. Say if you want a fixed opening verse instead. |
| Free 1.1 recording | `versePreviewProvider` in `lib/application/audio_providers.dart` | Everyone hears 1.1 (Sanskrit + translation) once during onboarding, without Shravan. It needs internet; offline it shows a "check your connection" line. |
| Demo verses | `DemoVerses` in `onboarding_demos.dart` | Swiping: 2.20 to 2.23. Trainer: 2.47, hidden words picked by the trainer's own rule. |
| Tour wording (reviewed: false) | welcome screen, `onboarding_demos.dart` | "One swipe, one verse", "Learn shlokas by heart", "Listen to every shloka", the streak lines, the "SADHAK" / "SHRAVAN" badges. No prices or buy buttons (v3: no launch-time upsells). |

## Home, trainer and text size (2026-11-23)

| Item | Where | What to check |
| --- | --- | --- |
| Home layout | `lib/features/home/` | Removed: date, EN/हि toggle, search button, streak chip, Continue reading card and the "Continue at …" button (search stays in the Gita tab and "See all"). Added: "Hi, {first name}" / "How are you?", the Sadhak and Shravan banners, short feeling cards. |
| Auto-sliding plan banners | `home_extras.dart` (`PlanBanners`) | Owner request. Note the v3 rule "no launch-time or timed upsells": the banners sit on Home and slide every 4 s (not under reduced motion), but they never pop up or block anything. Confirm this is fine with you. Owners of a plan see "Open" / "Listen" instead of "Explore". |
| Feeling words (reviewed: false) | `homeFeelings` in `home_extras.dart` | Peace, Stress, Confusion, Sadness, Anger, Fear, Lonely, Motivation, Grief, Doubt; each opens the dataset theme. Hindi readers see the dataset's Hindi theme titles. |
| "3D" icons | `Icon3D` in `lib/core/design/tactile.dart` | Drawn in code (gradient tile, gloss, coloured shadow). Supply real 3D artwork if you want rendered icons. |
| Trainer word bank | `lib/features/trainer/word_bank.dart` | Steps 2 to 4 now fill blanks from 3D word buttons in reading order, the same as the onboarding demo. A wrong word shakes and counts as one "help". Tapping a blank still reveals it. Step 5 (recite) is unchanged. |
| Default text size | `defaultTextScaleStep` in `lib/domain/models/app_settings.dart` | Now step 2 of 5 ("small", 0.92) instead of the middle. People who never changed it get the smaller size after updating. |
