# Gita App: v5 PRD (Polish, reliability and a calm habit loop)

Nov 20, 2026 · owner: @Devang · status: **draft, needs owner review; V5-1 to V5-6 coded, untested**

Extends `docs/PRD.md`, `docs/PRD_v2.md`, `docs/PRD_v3.md` and
`docs/PRD_v4.md`. Where it contradicts them, **this file wins** (section 1).
Scripture-text rules in `CLAUDE.md` still apply in full.

---

## 0. Instructions for Claude Code

1. Build in the stage order of section 8, one stage per session, with tests.
2. Stop at the end of each stage, run `flutter analyze` and `flutter test`,
   report, and tick the boxes here.
3. Anything visual that is not specified here (new colours, icons, layouts
   beyond those described) is the owner's decision: ask.

---

## 1. Overrides to earlier PRDs

| Earlier rule | v5 now |
| --- | --- |
| Android reminders use inexact scheduling only; exact-alarm permissions removed (v2 section 5) | Use **exact** scheduling when the system already allows it, otherwise inexact. `SCHEDULE_EXACT_ALARM` is declared (never `USE_EXACT_ALARM`). The app never prompts for it on its own; a row on the Reminders screen opens the system page if the user wants on-time delivery (section 3). |
| Rebuilding the schedule cancels all notifications (v2 section 5) | The rebuild cancels **pending** notifications only, so ones already delivered stay in the notification centre. |
| First launch is one skippable language screen (v1 section 5.1) | A short guided first launch that ends with the first verse read (section 4). Owner decision (2026-11-22): no Skip; every step is answered, with Back to the previous step. |

Still true: no analytics, no accounts, no backend, no guilt language, no
streak freezes, no launch-time or timed upsells, scripture is never
paywalled, and nothing the user made is ever hidden or deleted.

---

## 2. Decisions (owner, 2026-11-20)

| # | Decision | Value |
| --- | --- | --- |
| 1 | Direction | A habit people are glad to have, not "addictive". Ideas from the two reference videos are used only in their calm form (see section 7). |
| 2 | Mascot | **None.** No mascot anywhere, now or later. |
| 3 | Free plan | Stays. Scripture, search, summaries, streak and daily verse stay free. Sadhak and Shravan stay separate paid packages. |
| 4 | Analytics | None in the app. The owner reads the App Store Connect and Play Console dashboards (retention, conversion, uninstalls, trial-to-paid) instead. |
| 5 | Order | Fix the reading experience and notifications first. Icon, screenshots and store listing come last, once the owner is happy with the UI. |
| 6 | Free trials | An introductory free trial on Sadhak and Shravan, set up in the store consoles. The app shows the trial text from the store, never a hard-coded one. Length to be chosen by the owner. |

---

## 3. Reading polish and reliability (stage V5-1)

### 3.1 One type ramp for verse text
The shloka, transliteration and translation must read as one family with a
clear, even step between them (the owner reported the transliteration
looking oddly small between a large shloka and a large translation).

| Role | Size (x reading scale) | Notes |
| --- | --- | --- |
| Sanskrit shloka | 22 | Devanagari, centred |
| Transliteration | 17 | Italic, secondary colour, centred |
| Translation (EN and HI) | 18 | Primary colour |
| Purport body | 17 | |
| Word meanings | 16 | |

All sizes live in `ReadingType` in `core/design/typography.dart`; screens and
derived styles (player, trainer, purport Sanskrit) never hard-code them.

### 3.2 Bottom nav comes back on any upward move
- Today the pill only returns after scrolling up inside a long verse, so after
  swiping back through short verses it stays hidden.
- New rule: any upward intent shows it straight away: dragging up inside a
  verse, swiping back to the previous verse, or pulling down at the top of a
  verse. Downward drags inside a verse still hide it. Tapping near the
  bottom edge still shows it. Home always shows it.

### 3.3 Smoother verse swiping
- Each verse page has its own repaint boundary, so the page fade and shift
  during a swipe do not repaint the verse text on every frame.

### 3.4 Notifications that arrive
- Each notification is scheduled on its own; one failure (for example a time
  that passed while scheduling) never stops the rest. Times less than one
  minute away are skipped.
- Android: exact delivery when the system allows it, otherwise inexact
  (section 1). Reminders screen row "Deliver at the exact time" (Android 12+
  only, shown while exact delivery is not allowed) opens the system page.
- If the device time zone name is unknown to the time-zone database, use a
  zone with the device's current UTC offset instead of UTC, so reminders are
  not shifted by hours.
- Reminders screen button "Send a test notification" (shown while reminders
  are on): one notification about 5 seconds later, so the user can confirm
  delivery on their phone.
- Errors while scheduling are kept (last error and time) and shown in debug
  builds only.

---

## 4. Guided first launch (stage V5-3)

Steps, total under a minute. Owner decision (2026-11-22): there is no "Skip"; each step has one clear action and a Back arrow:
1. Language (English or Hindi), as today.
2. "What brings you to the Gita?" Peace, Guidance, Study, Learning by heart.
   One tap. Stored locally only; used to choose the first verse and which
   Home entry is shown first. No account, nothing leaves the phone.
3. The first verse, chosen from a short owner-reviewed list per answer (verse
   ids only, `reviewed: false` until the owner approves). Reading it counts
   day 1 with the existing qualifying-read rule.
4. Optional daily reminder with a time picker. Notification permission is
   asked only if the user turns it on.
5. Home.

---

## 5. Home and chapter end (stages V5-4, V5-5)

### Home
- One primary "Continue" button inside the thumb zone (lower half of the
  screen): "Continue at 2.48", or "Today's verse" when nothing is in
  progress.
- A "How are you feeling?" row that opens the existing situation search.
- Optionally (owner to confirm), at most once a day, a quiet "A verse for
  you" card using a verse the user has not opened in the last 60 days.

### End of a chapter
- At the last verse of a chapter: two equal choices, "Continue to Chapter
  N+1" and "Reflect on this chapter" (opens a new journal entry linked to the
  chapter, through the existing journal; free users keep the existing
  limits from v3).
- The pause at the end of a chapter stays. No auto-advance.

---

## 6. Store work (stages V5-6, V5-7)

- V5-6: free trials (decision 6). Paywall shows the store's introductory
  offer text and price, for example "7 days free, then ₹X/year". If the store
  offers no trial for this account, nothing about trials is shown.
- V5-7 (after the owner signs off the UI): value-led screenshot captions and
  refreshed listing text. The app icon may be refined; **no mascot**.

---

## 7. Ideas considered and how they are used

| Idea (source video) | Used as |
| --- | --- |
| Internal trigger, "the itch" | "How are you feeling?" entry to situation search |
| One-tap core action, "lazy thumb" | Continue button in thumb reach; day counts after one verse |
| Default next step, "paved path" | Home always shows the next step |
| Variable reward, "slot machine" | Only as varied content (random verse, varied messages). No random badges or loot. |
| No stopping cues, "bottomless pit" | **Not used.** Chapter ends keep their pause. |
| Stored value, "piggy bank" | Notes, highlights, journal and progress, always exportable. No lock-in. |
| Analytics (PostHog) | **Not used.** Store dashboards instead. |
| Onboarding to a first success | Guided first launch (section 4) |
| Remove free plan, card-required trial | **Free plan kept.** Store trials only. |
| Rebrand with mascot | **No mascot.** |

---

## 8. Staged TODO list

### V5-0: Spec
- [x] This file (draft). Owner review pending.

### V5-1: Reading polish and reliability
- [x] Type ramp tokens (`ReadingType`), all reading styles use them.
- [x] Nav pill returns on any upward move, including page swipes back.
- [x] Repaint boundary per verse page.
- [x] Notifications: per-item scheduling, one-minute margin, pending-only
      cancel, time-zone offset fallback, exact when allowed on Android.
- [x] Reminders screen: "Deliver at the exact time" row (Android) and "Send
      a test notification".
- [x] Tests for the above written (`test/widget/v5_polish_test.dart`,
      `test/data/notification_service_test.dart`,
      `test/design/typography_ramp_test.dart`). **Not run yet**: the owner
      asked to defer the test run to the simulator session.
- [ ] `flutter test` passes.
- [ ] Owner checks on a real iPhone and Android phone (see
      `docs/review-needed.md`).

### V5-2: Small UI/UX fixes
- [x] Raw title sizes moved to `TitleSizes` tokens (welcome, profile,
      streak card, completion share, paywall price, Sadhak card, notebook
      PDF).
- [x] Verse share image uses the reader's ramp (it had 20 / 13 / 15, the
      same uneven step the owner reported in the reader).
- [x] Shravan player verse text uses one factor for all roles (it mixed
      0.82, 0.9, 0.86 and an unscaled Hindi translation).
- [x] Long verses (owner report, 2026-11-20): reading to the end with a
      flick turned to the next verse. Now only a drag that **starts** at
      the top or bottom edge turns the page (40 px pull); momentum never
      does. A soft fade at the bottom shows when more text is below
      (`ReaderMetrics`).
- [ ] Owner walks through every screen on a phone and lists what else
      feels off; fixed in a follow-up pass of this stage.

### V5-3: Guided first launch
- [x] Section 4: language, "What brings you to the Gita?", first verse
      (counts day 1, saved as the Continue position), optional reminder.
      No Skip (owner, 2026-11-22); Back on every step after language.
- [x] Answer-to-theme map in `domain/first_launch.dart` (Peace -> peace,
      Guidance -> confusion, Study -> knowledge, Learning by heart -> study),
      reviewed:false. The first verse is the theme's top verse from
      `assets/search/themes.json`; no verse chosen from memory.
- [ ] Use the answer to order Home entries (left for later; Home has one
      layout for everyone for now).

### V5-4: Home
- [x] Continue button pinned just above the nav pill ("Continue at 2.48",
      or "Read today's verse"). Replaces the old Continue row on Home.
- [x] "How are you feeling?" card with five dataset themes (peace, stress,
      confusion, sadness, anger) opening situation search.
- [ ] "A verse for you" card: waiting for the owner's yes (section 5).

### V5-5: Chapter end
- [x] "End of Chapter N" pause with two choices: Continue to Chapter N+1,
      Reflect on this chapter. Reflect opens a journal entry for Sadhak,
      otherwise a free note on the chapter's last verse (existing v3 note
      limit applies). Also offered after Chapter 18.

### V5-6: Store free trials
- [x] The app reads the store's free trial (Google Play free first phase;
      App Store introductory offer in free-trial mode) and shows "7 days
      free, then ₹X a year", "Start free trial" and honest trial terms.
      Nothing shows when the store offers no trial. On Google Play the trial
      offer is the one bought, so the trial applies.
- [x] `in_app_purchase_storekit` added to pubspec (same official plugin
      family, already a transitive dependency) to read the App Store offer.
- [ ] Owner: create the trial in Play Console (base plan offer, "free
      trial" phase) and App Store Connect (introductory offer), choose the
      length.

### V5-7: Store screenshots and listing
- [x] Caption draft: `store/v5-screenshot-captions.md` (reviewed:false).
- [ ] Images and listing text, after the owner signs off the UI.

### Not run for any v5 stage
- `flutter test` (owner deferred it to the simulator session). Tests for
  V5-3 to V5-6 are in `test/widget/v5_polish_test.dart`.
