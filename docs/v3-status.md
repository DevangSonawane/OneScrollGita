# v3 status

Spec: `docs/PRD_v3.md`.

| Stage | State |
| --- | --- |
| V3-0 Groundwork | Done (2026-11-12). See baseline below. |
| V3-1 Word-for-word data | Done (2026-11-12). See below. |
| V3-2 Paywall plumbing | Done. |
| V3-3 Study layer, part 1 | Done. |
| V3-4 Shloka trainer | Done (optional review reminders not built). |
| V3-5 Study layer, part 2 | Done. |
| V3-6 Polish and QA | Done, except real-device checks. |

## V3-0 baseline (first run of the v2 test suite)

- `flutter analyze`: no issues.
- `flutter test`, first run: 154 passed, 2 failed, both in
  `test/widget/app_flow_test.dart`. Both were outdated tests, not app bugs:
  - "empty states and library list" looked for Flutter's `BackButton`; the
    library screen uses the shared `LucideBackButton`. The test now finds that.
  - "reset all data returns to first launch": the Profile page got taller in v2
    (streak card), and `scrollUntilVisible` scrolled the first `Scrollable` in
    the tree instead of Profile's vertical list. The test now names that list.
- `flutter test` after the fixes: **156 passed, 0 failed.**
- Integration tests (`integration_test/`) still not run; they need a device or
  simulator. Real-device notification check is still pending
  (`docs/review-needed.md`).

## Source data check

The cached importer source (`tool/.cache/vedabase_cc/`) has word-for-word
meanings for all 653 entries in English and in Hindi. The importer currently
drops them (`synonyms: null`). V3-1 keeps them.

## V3-1 Word-for-word data

- Importer (`tool/import_vedabase.dart`) now keeps the source's word meanings:
  9,541 English pairs on all 653 entries; Hindi on 651 entries. Re-run from the
  cache only (no network). A diff check confirmed that nothing but `synonyms`,
  `datasetVersion` and checksums changed in `assets/scripture/`.
- Two Hindi source entries have a malformed pair, so those entries show the
  English list: 2.4 (a comma where a semicolon belongs) and 13.8-12 (a word
  with no meaning). Listed in `docs/review-needed.md`. The data was not edited.
- Scripture JSON grew from 4.4 MB to 5.9 MB uncompressed (JSON compresses well
  in the app bundle).
- The search index rebuilds once on the next launch because `datasetVersion`
  changed (expected).
- Reader: "Word meanings" toggle under the transliteration. The per-word tap
  tooltip was dropped (`docs/PRD_v3.md` section 5).
- Results: `flutter analyze` clean; `flutter test` 169 passed, 0 failed;
  `validate_scripture` PASS (0 errors, 6 existing quote warnings).
- Not checked on a real phone yet.

## V3-2 Paywall plumbing

- Packages: `in_app_purchase` 3.3.1 and `in_app_purchase_android` 0.5.5
  (official). No third-party purchase SDK.
- Logic: `lib/domain/premium.dart` (free/paid rules, limits, plans),
  `lib/data/purchases/purchase_gateway.dart` (store, debug demo, fallback),
  `lib/application/premium_providers.dart` (entitlement + paywall
  controller). Entitlement is cached in preferences, re-checked on launch and
  resume, and kept by "Reset all saved data".
- UI: `lib/features/premium/` (paywall, hand-drawn art, Profile card). Route
  `/sadhak?reason=<feature>`; `openPaywall(context, reason: ...)` for later
  stages.
- Debug builds: "Pretend premium" switch in Profile; demo prices on the
  paywall when the store has no products.
- Visually checked from rendered screenshots (light, dark, 360 px at text
  scale 2.0, entrance, bloom, welcome, Profile card). Several fixes came from
  that review (aura edge, halo, scroll behaviour, large-text layout).
- Results: `flutter analyze` clean; `flutter test` 204 passed, 0 failed
  (35 new).
- **Open: `INTERNET` in the merged release manifest.** Google Play Billing
  9.1.0 depends on `com.google.android.datatransport` (Google's telemetry
  transport), which adds `INTERNET`. Purchases themselves go through the Play
  Store app and do not need it. Owner decision pending: remove the permission
  in the app manifest (`tools:node="remove"`), or keep it and update the
  privacy wording. **Decided: keep it** (About privacy note updated). Test a
  purchase on a real phone.
- Not done here (owner): store products, prices, test track, terms and
  privacy URLs.

## V3-3 to V3-6 (study layer, trainer, journal, notebook, QA)

- Database v3: `verse_highlights`, `verse_notes`, `journal_entries`,
  `shloka_progress`; migrations from v1 and v2 tested. "Reset all saved data"
  clears them; a Sadhak purchase is kept.
- Highlights (free, 4 colours, reader band, Profile list); notes (free up to
  10, autosave, marker on the verse, Profile list); journal (paid, can start
  from a verse's note); notebook PDF (paid).
- Shloka trainer: five steps, seeded hiding, long verses in parts, repeat a
  step after more than 2 reveals, spaced reviews 1/3/7/21/60 days, mastered.
  Free verses 2.47, 4.7, 18.66. Sessions count as read days. Roman/Devanagari
  toggle remembered.
- PDF: pages drawn by Flutter and placed as images (the `pdf` package cannot
  shape Devanagari). Checked visually; attribution footer on every page.
- Visual review from rendered screenshots fixed: uneven word baselines in the
  trainer, a first-letter bug on words that start with an apostrophe, and an
  app-bar overflow at text scale 2.0.
- Not built: optional trainer review reminders (needs new written messages
  and a scheduler change).
- Results: `flutter analyze` clean; `flutter test` 262 passed, 0 failed;
  `validate_scripture`, `validate_messages` and `validate_content` pass.
- Still needs a real phone: purchases on a test track, PDF sharing, the
  trainer and note flows on a small Android, integration tests.
