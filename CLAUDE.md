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
- Offline-first. No network calls, no accounts, no analytics, no ads, no push notifications, no in-app purchases, no cloud sync. (v2: local notifications only, see below.)
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
- Do not build audio. When all other v2 stages are finished, tell the owner: "All v2 features except audio are complete. Only audio remains."
