# Gita app - rules for Claude Code

## Source of truth
- docs/PRD.md is the product spec. Follow it. Do not add features, screens, packages or infrastructure that it does not describe. If something seems missing, ask.
- Work on ONE stage at a time from section 8 of the PRD. Stop at the end of the stage and report.

## Scripture text (most important rule)
- Never generate, paraphrase, translate, shorten, correct or "fix" Sanskrit, transliteration, translation or purport text.
- Only the importer script in tool/ may write to assets/scripture/. Never edit those files by hand.
- If the validator fails, report the failure to the user. Never patch the data to make it pass.
- Placeholder data must carry isPlaceholder: true and must never ship in a release build.

## Product constraints
- Offline-first. No network calls, no accounts, no analytics, no ads, no push notifications, no in-app purchases, no cloud sync. (v2: local notifications only; v3: one paid plan through the stores. See below.)
- Fonts are bundled assets. Do not use runtime font downloads.
- Out of scope: AI features, chat, social, leaderboards. (v2 allows a gentle streak, keyword/situation search and completion sharing.)

## Architecture
- Layers: presentation, application (Riverpod), domain (pure Dart), data (repositories). Only the data layer touches assets, SQLite or preferences.
- Verse IDs are stable strings (bg-02-047, ranges bg-01-016-018). Store IDs, never list indexes.
- Keep scripture data and user data separate.

## UI rules
- Use design tokens and shared components only. No hard-coded colours, sizes or durations in screens.
- Reading text is never placed on glass. Max 3 glass surfaces on screen. Always keep the frosted and solid fallbacks.
- Honour reduced motion through the Motion helper. Touch targets at least 48 dp. Layouts must survive text scale 2.0.

## Process
- Write tests with each stage. Before saying a stage is done, run flutter analyze and flutter test and report the results.
- Tick the completed boxes in docs/PRD.md.
- Prefer small, reviewable commits. When blocked on content, legal wording or a visual decision, ask the user instead of guessing.

## v2 additions
- v2 spec is in docs/PRD_v2.md. It overrides v1 for notifications, streaks, search, summaries and sharing only.
- Still no backend, no network calls, no analytics. Scripture text is never generated or edited.
- Written content (messages, summaries, theme map) carries reviewed:false until the owner reviews it. List everything needing review in docs/review-needed.md.
- Never invent a helpline number. Never map a verse to a theme from memory; use the dataset text.
- Audio was deferred in v2; it is now specified in docs/PRD_v4.md (see v4 additions).

## v3 additions (Sadhak plan)
- v3 spec is in docs/PRD_v3.md: shloka trainer, study layer (highlights, notes, journal, PDF export) and the paywall. It overrides v1/v2 only where its section 1 says so. Build it one stage at a time from its section 9.
- One paid plan through the official `in_app_purchase` package only. The store's billing service is the only allowed network use. No third-party purchase SDKs, no server, no analytics.
- Never paywall scripture: every verse, translation, purport, word meaning, search, summary, streak and the daily verse stay free. No paid streak freezes, no AI chat, no launch-time or timed upsells.
- All free/paid checks go through `canUse` in domain/premium.dart. Screens never check products or prices. Show store prices, never hard-coded ones.
- Word-for-word meanings come only from the importer. When a free user hits a limit or premium lapses, never hide or delete what they already made.
- The release Android manifest has INTERNET only because Google Play Billing brings it (owner decision, 2026-11-12). The app's own code still makes no network calls.
- Sankalpa journeys are not in v3. Do not build them until the owner writes a spec.

## v4 additions (Shravan audio)
- v4 spec is in docs/PRD_v4.md. Build one stage at a time from its section 9.
- Owner decision (2026-11-19): the app may stream and download audio files from the single configured audio host. No other network use, no tracking, no analytics.
- Shravan is a separate paid package from Sadhak. Listening checks go through `canListen` in domain/shravan.dart. Reading scripture stays free.
- Until the owner supplies recordings, the player uses the pretend engine and placeholder timings marked isPlaceholder; they must never ship in a release build.
- iOS uses the system Now Playing session (lock screen, Dynamic Island). Do not build a custom Live Activity.

## v9 additions (optional account)
- v9 spec is in docs/PRD_v9.md. Owner decision (2026-11-21): an optional account through Supabase Auth, Sign in with Apple and Google only.
- The only extra network use is the single configured Supabase project (sign-in, sign-out, delete account, purchase record). No sync, no analytics.
- Owner decision (2026-11-22): new installs must sign in at the end of first launch (no skip). After that, signing out never blocks reading or anything the user made. Never unlock anything from the Supabase purchase record; the store stays the truth.
- Supabase keys come from --dart-define only. Never commit them.
- Owner decision (2026-11-25): Supabase Edge Functions (supabase/functions) check purchases with the stores, take store notifications and revoke the Apple token on account deletion. Their only outside calls are Apple's and Google's APIs. Apple sign-in on Android uses Apple's web page behind APPLE_ON_ANDROID. Server keys are Supabase secrets, never in the app or the repo.

## v10 additions (Apple Watch)
- v10 spec is in docs/PRD_v10.md: a native SwiftUI watch app (ios/GitaWatch) and complication (ios/GitaWatchWidgets). No Flutter on the watch.
- The watch's verse text is ios/GitaWatch/Shared/gita_watch.json, written only by tool/build_watch_scripture.dart. Re-run it after every import; never edit it by hand.
- The iPhone is the only store of bookmarks and reading position; the watch mirrors IDs over WatchConnectivity (paired watch only, not a network call). Never send scripture text to the watch.
- The watch daily verse (Shared/DailyVerse.swift) must match lib/domain/daily_verse.dart. Change both together and run sh tool/check_watch_daily_parity.sh.

## v11 additions (Listen widgets)
- v11 spec is in docs/PRD_v11.md: Listen widget (iPhone Home and Lock Screen, Android home screen), Listen control (Control Center, Android Quick Settings).
- Every Listen widget or control goes through `quickActionRoute` (Start Listening). Without Shravan it opens the paywall; widgets never decide access and never get purchase data.
