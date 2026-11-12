# Gita App: v3 PRD (Sadhak plan: Shloka trainer, Study layer, Paywall)

Nov 12, 2026 · owner: @Devang

This file extends `docs/PRD.md` (v1) and `docs/PRD_v2.md` (v2). Where it
contradicts them, **this file wins** (section 1). Everything else still applies:
offline-first, no backend, design tokens and shared components, glass rules,
accessibility, testing, and above all the scripture-text rules in `CLAUDE.md`.

The "Sankalpa journeys" feature is **not** in this file. The owner will decide on
it after v3 ships.

---

## 0. Instructions for Claude Code

1. Build in the stage order of section 9, one stage per session, with tests.
2. Stop at the end of each stage, run `flutter analyze` and `flutter test`,
   report, and tick the boxes here.
3. Where a default exists in this file, use it and note it. Ask only about
   things this file does not decide.
4. Anything that needs the owner's store accounts or a real phone goes into
   `docs/review-needed.md`.

---

## 1. Overrides to v1 and v2

| Earlier rule | v3 now |
| --- | --- |
| v1: no subscriptions, no in-app purchases | One optional paid plan, "Sadhak", sold through Google Play and the App Store (section 3). |
| v1: no network calls | The **only** exception is the store's own billing service, reached through the official store libraries. The app itself still makes no network calls and has no server. |
| v1 scope table | Word meanings in the reader, highlights, notes, journal, PDF export and the shloka trainer are added. |

**Still true (do not break):**

- Never generate, edit, paraphrase or translate scripture text. Word-for-word
  meanings come from the authorised source through the importer only.
- **Nothing in the scripture is ever paywalled:** every verse, translation
  (EN and HI), purport, word meaning, search, summary, streak and the daily
  verse stay free.
- No accounts, no analytics, no ads, no third-party purchase SDKs (no
  RevenueCat, Adapty, Qonversion and the like), no user data leaves the phone.
- No paid streak freezes, no AI chat, no timed or launch-time upsell pop-ups.

---

## 2. Decisions (change any before the matching stage starts)

| # | Decision | Default | Why |
| --- | --- | --- | --- |
| 1 | Purchase library | Official `in_app_purchase` | No third-party server, no extra data sharing |
| 2 | Receipt checking | On device only, no server | No backend. Some Android piracy is accepted |
| 3 | Products | `sadhak_yearly` (auto-renewing yearly), `sadhak_lifetime` (non-consumable) | Indian users like a one-time option |
| 4 | Prices | About ₹699 a year and ₹1,999 lifetime, **set by the owner in the stores** | The app always shows the store's localised price, never a hard-coded one |
| 5 | Word meanings | Free, in the reader | They are scripture text |
| 6 | Highlights | Free, unlimited, whole-verse, 4 colours | Easy to build; partial-text highlights are hard in Flutter |
| 7 | Notes | One note per verse; free users get up to 10 notes | A taste before paying |
| 8 | Journal and PDF export | Paid | |
| 9 | Trainer free verses | `bg-02-047`, `bg-04-007`, `bg-18-066` (a config list) | Short, well-known verses; owner may swap them |
| 10 | Trainer script | Learn on the transliteration by default, Devanagari toggle | Most beginners read Roman script |
| 11 | Review schedule | +1, +3, +7, +21, +60 days | Simple spaced repetition |
| 12 | Review reminders | Optional, off by default, through the existing local notification engine | Calm by default |

---

## 3. Sadhak plan and paywall

### Entitlement

- One domain value: `Entitlement { free, premium }`, plus a pure function
  `canUse(Feature, Entitlement, usage)` in `domain/premium.dart` that holds
  every free limit in one config class `FreeLimits`. Screens never check prices
  or products themselves.
- `PurchaseRepository` (data layer) wraps `in_app_purchase`: load products,
  buy, restore, listen to the purchase stream, and complete pending purchases.
- The last known entitlement is cached in `shared_preferences`
  (`entitlementCache`, `entitlementCheckedAt`). The app trusts the cache when
  the store cannot be reached, so premium works fully offline. It re-checks on
  launch and on resume, and drops premium only when the store explicitly
  reports no active purchase.
- "Reset all saved data" does **not** remove the entitlement (the store holds
  it); "Restore purchase" always brings it back.
- Debug builds only: a "Pretend premium" switch in Profile (About section,
  next to the typography specimen). It counts only when `kDebugMode`
  (`resolveEntitlement`, tested).
- Debug builds only: when the store has no products yet, the paywall shows
  clearly labelled demo prices (`DemoPurchaseGateway`) so the design can be
  seen and the purchase flow tried. A demo purchase only flips "Pretend
  premium". Release builds always use the real store.
- Known limit: Google Play reports owned purchases explicitly, so a lapsed
  yearly plan is removed on the next launch. The App Store only replays
  purchases, so on iOS a lapsed plan is not removed automatically in v3.

### Paywall screen (`/sadhak`, pushed, full screen)

- Opens **only** when the user taps a locked feature or the "Sadhak" row in
  Profile. Never on launch, never on a timer, never after reading.
- Solid surfaces (not glass). A close button is always visible.
- Content: title "Sadhak", one line of purpose, a short list of what is
  included, the two plans with store prices (yearly shows the per-month
  equivalent from the store data when available), a primary "Continue" button,
  "Restore purchase", and links to the terms of use and privacy policy.
- Copy is calm: no countdowns, no fake discounts, no "only today".
- States: loading products, products unavailable (offline or store error, with
  a "Try again"), purchase pending, success (short thank-you, then back to
  where the user came from), cancelled (silent), error (plain message).
- Copy is in English, like the rest of the app's interface (the language
  setting only changes scripture text). The wording is listed in
  `docs/review-needed.md` for the owner's review.

### Paywall look and motion (built in V3-2)

Patterns from top-converting paywalls (a mood-setting hero, one clear value
line, 3 to 4 benefits, a pre-selected recommended plan, a single "Continue",
honest terms), drawn in the app's own language:

- **Hero:** a slowly turning lotus mandala (three petal rings in opposite
  directions), a soft saffron-and-gold aura drifting on slow ellipses, and
  golden sparks rising. A breathing lotus mark with a soft halo, and
  "साधक" in Devanagari with a light sweep, "SADHAK" beneath.
- **Entrance:** hero, headline, each benefit, plans and button fade and rise
  in sequence over 1.4 s.
- **Plans:** the selected card glows with a saffron border and soft halo; the
  radio springs in.
- **Continue:** a saffron-to-gold pill with a slow light sweep and a press
  scale.
- **Welcome:** after buying, a lotus blooms in the centre of the mandala with
  a ring of light and a burst of sparks.
- Under reduced motion every loop stops and everything appears at once.
- Large text: the hero grows, plan prices move under the title, and only the
  button stays pinned (terms and links scroll).
- No glass on this screen. All colours, sizes and durations are tokens
  (`PremiumColors`, `PaywallMetrics`, `AppDurations`).

### Locked-feature behaviour

- Locked items stay visible with a small lock icon. Tapping opens the paywall
  with a one-line reason ("Unlimited notes are part of Sadhak").
- When a free user hits a limit, nothing they already made is hidden or
  deleted. Existing notes stay readable and editable; only new ones are blocked.
- If premium lapses, the same rule applies: everything stays readable and
  exportable data stays on the phone; only paid actions lock again.

---

## 4. Data changes

### Scripture data (importer only)

- `tool/import_vedabase.dart` keeps the word-for-word meanings that the source
  already contains for every entry in English and Hindi. Today it writes
  `synonyms: null`.
- New per-entry shape:

```json
"synonyms": {
  "en": [ { "word": "karmaṇi", "meaning": "prescribed duties" } ],
  "hi": [ { "word": "कर्मणि", "meaning": "विहित कर्तव्यों में" } ]
}
```

- Parsing (`lib/domain/word_meanings.dart`) splits the source string on `;`
  into pairs, and each pair on its single em dash (`—`). Words and meanings
  keep the source text exactly; only the Markdown emphasis markers are
  removed. A pair with no dash or more than one dash is reported, never
  guessed.
- English must parse completely, or the importer stops before writing.
  A Hindi list with any unsplittable pair is left out **for that entry only**
  (the app shows the English list with a note) and reported. On the current
  source this affects 2 entries, 2.4 and 13.8-12 (`docs/review-needed.md`).
- English words are in IAST. Hindi lists print the word in Devanagari in most
  entries and in IAST in some (about 150 entries), exactly as the source does.
  The two lists are not assumed to line up one-to-one.
- `validate_scripture.dart` checks: every entry has a non-empty EN list with
  no Devanagari words, the HI list is either null or non-empty, no empty word
  or meaning, and checksums match.
- `VerseEntry` gets `wordMeaningsEn` and `wordMeaningsHi` (lists of
  `WordMeaning`) and `wordMeaningsFor(lang)`.

### User data: drift schema version 3 (tested migration from 2)

| Table | Columns | Notes |
| --- | --- | --- |
| `verse_highlights` | `verse_id` TEXT PK, `color` TEXT (`saffron` / `leaf` / `sky` / `lotus`), `updated_at_ms` INTEGER | One per verse |
| `verse_notes` | `verse_id` TEXT PK, `body` TEXT (max 4,000 chars), `created_at_ms`, `updated_at_ms` | One per verse |
| `journal_entries` | `id` INTEGER PK autoincrement, `verse_id` TEXT nullable, `body` TEXT (max 10,000 chars), `created_at_ms`, `updated_at_ms` | |
| `shloka_progress` | `verse_id` TEXT PK, `step` INTEGER (1-5), `status` TEXT (`learning` / `learned` / `mastered`), `review_index` INTEGER, `next_review` TEXT (`YYYY-MM-DD`) nullable, `started_at_ms`, `learned_at_ms` nullable, `last_reviewed_at_ms` nullable | Times are epoch ms like v1 |

- Highlight colours are design tokens, with light and dark variants that keep
  text contrast at 4.5:1 or better.
- "Reset all saved data" clears all four tables. "Clear reading history" clears
  none of them.

### New settings

| Key | Type | Default |
| --- | --- | --- |
| `entitlementCache` | `free` / `premium` | `free` |
| `entitlementCheckedAt` | ISO string | none |
| `trainerScript` | `latin` / `devanagari` | `latin` |
| `reviewRemindersEnabled` | bool | false |

---

## 5. Word meanings in the reader (free)

- Below the transliteration, a quiet "Word meanings" row expands to show every
  pair from the dataset in the current language (EN list, or HI list when
  Hindi is chosen and present, otherwise EN with a one-line note).
- The open/closed state lasts for the session, so it stays open while swiping
  between verses.
- **Decision (V3-1): no per-word tap tooltip.** Tapping the transliteration
  already copies it, and because of sandhi only about 64% of verse words match
  a dictionary word exactly (whole word, plus final ṁ written as m). A
  tooltip that works on two words in three felt broken, so the full list is
  the only view. The trainer can revisit this later.
- Survives text scale 2.0; the toggle is at least 48 dp.

---

## 6. Study layer

### Highlights (free)

- Highlight button in the reader's verse actions opens a 4-colour picker plus
  "Remove". The translation block gets a soft colour band (never glass).
- "Highlights" list in Profile, grouped by colour, newest first.

### Notes (free up to 10, then paid)

- A note icon in the verse actions opens a full-screen editor (solid surface,
  autosave after 600 ms and on leave, character counter near the limit).
- A small note marker shows on verses that have a note.
- "My notes" list in Profile, newest first, with the verse label and the first
  two lines.

### Journal (paid)

- "Journal" in Profile: a list of entries plus a "New entry" button. An entry
  can be linked to a verse ("Write about this verse" from the verse actions).
- Plain text only in v3.

### My Gita notebook PDF (paid)

- Profile → Export → choose: notes, highlights, journal (any mix), then share
  through the system share sheet. The file never leaves the phone otherwise.
- Each item shows the verse label, the Sanskrit and the translation **exactly
  as in the dataset**, and then the user's text. A footer credits the edition
  with the exact attribution wording from the About screen.
- **Known risk:** the `pdf` package may not shape Devanagari correctly. Stage
  V3-5 starts with a spike: if Sanskrit renders wrongly, render each page from
  Flutter widgets to an image and place the images in the PDF. If both fail,
  stop and ask the owner.

---

## 7. Shloka trainer

### Domain (pure Dart, `domain/trainer/`)

- `TrainerUnit`: one entry. Entries with more than 4 transliteration lines are
  learned in parts of 2 lines, then as a whole.
- Step model, the same for every unit:
  1. **Understand**: the full verse with the word-meaning list and the
     translation.
  2. **Some words hidden**: about 30% of words become blanks.
  3. **Most words hidden**: about 70% hidden.
  4. **First letters**: each word shows only its first letter.
  5. **Recite**: the verse is fully hidden; the user recites, then taps
     "Show" and marks "I got it" or "Not yet".
- Words to hide are picked by a seeded pick from `verseId + step`, so the
  same verse always hides the same words (stable and testable). Hiding works on
  the chosen script's own tokens.
- Tapping a blank reveals that one word. More than 2 reveals on a step means
  that step is repeated once before moving on.
- `ReviewSchedule`: after step 5 passes, status becomes `learned` and the first
  review is due in 1 day. Each passed review moves to the next interval (1, 3,
  7, 21, 60). A failed review moves back one interval. Passing the 60-day
  review makes the verse `mastered`.
- Due dates are local `YYYY-MM-DD` strings, like streaks, so daylight-saving
  changes never shift them.

### Screens

- **Entry points:** a "Learn by heart" action in the reader's verse actions,
  and a "Shloka trainer" row in Profile.
- **Trainer home:** a "Due for review" section (count and a "Start review"
  button), "In progress", "Learned and mastered" ("My shlokas"), and a "Pick a
  verse" button that opens the existing chapter and verse selector.
- **Step screen:** one card with the verse (never on glass), a step indicator
  (1 of 5), the script toggle, and one primary button. Under reduced motion,
  blanks fade instead of sliding.
- **Done:** a calm "Learned" card with the next review date and a "Share" text
  button that reuses the share-card system (verse label and the dataset
  Sanskrit only).
- A qualifying trainer session also counts as a read day for the streak (it
  reuses `ReadRule`).

### Free vs paid

- Free: the full flow and reviews for the verses in `FreeLimits.trainerVerses`.
- Paid: any verse, plus the review schedule and review reminders for all of
  them.

### Review reminders (optional)

- A switch on the trainer home ("Remind me when reviews are due"), off by
  default. When on, one local notification at the user's reminder time on days
  that have due reviews, through the existing notification engine and its
  existing channel rules. Text comes from a small new message category,
  `review_due`, written by Claude Code with `reviewed: false`.

---

## 8. Privacy and store notes

- The About and privacy note gain one line: purchases are handled by Google
  Play or the App Store; the app has no server and sends nothing itself.
- **Owner decision (2026-11-12): `INTERNET` stays.** Google Play Billing
  9.1.0 depends on Google's telemetry transport
  (`com.google.android.datatransport`), which adds `INTERNET` to the merged
  release manifest. The app's own code still makes no network calls. The
  About screen says so, and the Play data-safety form must mention it. The
  billing library also adds `com.android.vending.BILLING`.
- The App Store requires links to terms of use (EULA) and a privacy policy on
  the paywall and in the listing. The owner supplies both URLs
  (`lib/core/config/app_links.dart`).

---

## 9. Staged TODO list (do in this order)

### V3-0: Groundwork

- [x] Run `flutter analyze` and `flutter test` on the v2 code and record the
      results in `docs/v3-status.md`.
- [x] Write this file and add the v3 rules to `CLAUDE.md`.
- [x] Fix any v2 test failures found above (separate commits, one cause each).

**Done when:** analyze is clean and the baseline test results are recorded.

### V3-1: Word-for-word data

- [x] Importer keeps EN and HI synonyms using the parsing rule in section 4;
      fails loudly on unparseable pairs.
- [x] Re-run the importer (never hand-edit `assets/scripture/`); update
      checksums.
- [x] Validator checks from section 4, with tests.
- [x] `VerseEntry.wordMeaningsEn` / `wordMeaningsHi` and parsing tests.
- [x] Reader "Word meanings" row (section 5; the tap tooltip was dropped, see
      the decision there), widget tests including text scale 2.0.

**Done when:** every entry shows its word meanings in the reader in EN and HI,
and the validator passes.

### V3-2: Paywall plumbing

- [x] Add `in_app_purchase` (+ `in_app_purchase_android`); `PurchaseGateway`
      (`lib/data/purchases/`), entitlement cache, restore, pending-purchase
      completion.
- [x] `domain/premium.dart`: `Entitlement`, `PremiumFeature`, `FreeLimits`,
      `canUse`, `resolveEntitlement`, `SadhakPlan`, with unit tests.
- [x] Entitlement provider; re-check on launch and resume; offline trusts the
      cache.
- [x] Paywall screen with every state from section 3 (English copy, listed
      for review), look and motion as above.
- [x] Debug-only "Pretend premium" switch, with a test that it never counts
      in release.
- [x] Profile "Sadhak" card (shows "Active" when premium).
- [x] Check the merged release Android manifest for `INTERNET` (present via
      Play Billing; owner chose to keep it).

**Done when:** in debug builds you can switch premium on and off, the paywall
opens from the Profile row, and products load in a store test track (owner
step, listed in `docs/review-needed.md`).

### V3-3: Study layer, part 1

- [x] Drift schema v3 with all four new tables and migration tests from v1
      and v2.
- [x] Highlights: picker, reader colour band, Profile list, colour tokens with
      a contrast test.
- [x] Notes: editor with autosave, verse marker, Profile list, 10-note free
      limit through `canUse`.
- [x] Reset-all-data clears the new tables; tests.

**Done when:** highlights and notes survive a restart, and the 11th note opens
the paywall for a free user.

### V3-4: Shloka trainer

- [x] `domain/trainer/`: units and parts, step model, seeded hiding,
      `ReviewSchedule`, with unit tests (stable hiding, part splitting for long
      entries and ranges, interval up and down, mastered, DST and leap day).
- [x] `shloka_progress` repository (`StudyRepository`).
- [x] Trainer home, step screen, done card, reader and Profile entry points.
- [x] Free-verse limit through `canUse`; locked verses open the paywall.
- [x] Trainer sessions count as read days.
- [ ] Optional review reminders and the `review_due` messages (flagged).
      **Not built** (optional; needs new written messages and a scheduler
      change). The owner can ask for it later.
- [x] Widget tests: full flow for one verse, review pass, repeat after too
      many reveals, locked verse, script toggle, text scale 2.0.

**Done when:** a free user can learn 2.47 end to end and see it due for review
the next day, and a premium user can learn any verse.

### V3-5: Study layer, part 2

- [x] PDF Devanagari decision: the `pdf` package cannot shape Devanagari, so
      every page is drawn by Flutter and placed in the PDF as an image
      (`buildNotebookPdf`). Checked visually: conjuncts render correctly.
      Trade-off: text in the PDF is not selectable.
- [x] Journal list and editor; a linked entry starts from the note editor
      ("Write in your journal").
- [x] Notebook export with item selection and the share sheet; attribution
      footer on every page.
- [x] Tests for export content and paid gating.

**Done when:** a premium user can export a PDF in which the Sanskrit renders
correctly and share it.

### V3-6: Polish and QA

- [x] Accessibility pass on all new screens (labels, 48 dp targets, text scale
      2.0 in light and dark, contrast tests, reduced motion).
- [x] About and privacy note update (section 8).
- [x] Re-review the dependency list: no third-party purchase or analytics
      SDK. `INTERNET` is present only through Play Billing (owner decision).
- [x] `docs/v3-status.md` and `docs/review-needed.md` updated.

**Done when:** `flutter analyze` and `flutter test` pass and every item needing
the owner is listed.

---

## 10. What the owner must do (any time, in parallel)

1. Create `sadhak_yearly` and `sadhak_lifetime` in Google Play Console and App
   Store Connect, set prices, and set up a test track or sandbox testers.
2. Provide the terms of use and privacy policy URLs.
3. Review the paywall copy (EN and HI) and the `review_due` messages.
4. Confirm or change the free limits (section 2, rows 7 and 9).
