# Gita App: v2 PRD (Streaks, Notifications, Share, Search, Summaries)

This file extends `docs/PRD.md` (v1). Read v1 and `CLAUDE.md` first. Where this file contradicts v1, **this file wins** (see section 1). Everything else in v1 still applies: offline-first, no backend, design tokens, shared components, liquid glass rules, accessibility, testing.

---

## 0. Instructions for Claude Code (read first)

1. Build everything in this file **in the stage order of section 14**, one stage per session, with tests, exactly as in v1.
2. **Do everything except the audiobook.** Audio is blocked on recordings and permission that only the owner can provide (section 13). Do not build any audio UI, player, hosting code, or placeholders.
3. When every other stage is finished, **stop and tell the owner exactly this**: "All v2 features except audio are complete. Only audio remains." Then list what the owner must do (section 15). Do not start audio on your own.
4. Where content needs the owner's review (message bank, Hindi strings, chapter summaries, theme map, helpline number), write it, mark it `reviewed: false`, add it to `docs/review-needed.md`, and carry on. Do not wait for review to continue building.
5. Where something needs a physical phone or the owner's accounts (real-device notification test, store setup), do everything you can, then list it in `docs/review-needed.md`.
6. Never ask the owner a question that has a default in this file. Use the default and note it.
7. Update `CLAUDE.md` with the section 1 overrides and the rules in section 12 before starting V2-0.

---

## 1. Overrides to v1

| v1 said | v2 now |
| --- | --- |
| No notifications | Local notifications are allowed (section 5). Ask permission only when the user switches reminders on. |
| No streaks or gamification | A gentle streak is allowed (section 4). No leaderboards, no social comparison, no guilt language. |
| No AI-generated interpretations | Chapter summaries (section 9) and notification text (section 6) are written content, always labelled as **not part of Srila Prabhupada's text**. |
| No search | Keyword search and situation search are added (sections 10, 11). |
| No sharing | Sharing a completion card through the phone's share sheet is added (section 8). |

**Still true (do not break):**
- No backend, no accounts, no analytics, no ads, no network calls, no `INTERNET` permission in the release Android manifest.
- Never generate, edit, paraphrase or invent scripture text (Sanskrit, transliteration, translation, purport). Anything derived from scripture is built from the bundled dataset only.
- Never attribute written messages, summaries or quotes to Srila Prabhupada unless the exact text comes from the dataset.
- Everything works offline.

---

## 2. Feature summary

| # | Feature | Needs permission | Needs content |
| --- | --- | --- | --- |
| A | Reading streak and "Good work" popup | None | ~60 popup messages |
| B | Local notifications (daily, streak, random verse) | Notification permission, requested on opt-in | Message bank |
| C | Message bank (500+ written messages) | None | Written by Claude Code, reviewed by owner |
| D | Completion share card | None | None |
| E | Keyword search | None | None |
| F | Chapter summaries | None | 18 summaries |
| G | Situation search ("sadness", "free thinking") | None | About 100 themes mapped to verses |
| H | Audio | None | **Blocked: recordings and permission** |

---

## 3. Data and storage changes

Bump the drift schema to **version 2** with a tested migration from version 1.

### New tables

| Table | Columns | Notes |
| --- | --- | --- |
| `read_days` | `date` TEXT primary key (`YYYY-MM-DD`, local date), `verse_count` INTEGER, `first_read_at` TEXT | One row per day that counted |
| `read_day_verses` | `date` TEXT, `verse_id` TEXT, primary key (`date`, `verse_id`) | Distinct verses that qualified that day |
| `notif_assignments` | `date` TEXT, `slot` TEXT (`morning` / `evening`), `message_id` TEXT, `verse_id` TEXT nullable, primary key (`date`, `slot`) | Makes a day's message stable across reschedules |
| `search_history` | `query` TEXT primary key, `last_used_at` TEXT | Cap 20, clearable |

### New settings (shared_preferences)

| Key | Type | Default |
| --- | --- | --- |
| `remindersEnabled` | bool | false |
| `reminderTime` | `HH:mm` | `08:00` |
| `streakNudgeEnabled` | bool | true (only active when reminders are on) |
| `streakNudgeTime` | `HH:mm` | `20:30` |
| `verseNotifsEnabled` | bool | true (only active when reminders are on) |
| `lastScheduleRebuildAt` | ISO string | none |
| `streakPopupShownDate` | `YYYY-MM-DD` | none |
| `milestonesShown` | list of ints | empty |

Invalid stored values fall back to defaults, as in v1.

### "Reset all saved data" and "Clear reading history"

- Reset all saved data also clears `read_days`, `read_day_verses`, `notif_assignments`, `search_history`, cancels all scheduled notifications, and resets v2 settings.
- Clear reading history clears history only. Streak data is kept (it is not history).
- Add "Clear search history" in Profile, in the data section.

---

## 4. Stage A: Streak and "Good work" popup

### What counts as a "read day"

A day counts when the user has a **qualifying read** on that local calendar day. Keep these in one config class `ReadRule` so they are easy to change:

- Reader or purport page: the verse is visible, the app is in the foreground, for **5 seconds**.
- Home: the daily verse qualifies after **10 seconds** visible, or immediately when the user taps "Read in Gita", "Purport", Favourite or Bookmark on it.
- Each distinct verse counts once per day toward `verse_count`.
- The local date is the device's local calendar date. A day boundary is local midnight. Use plain year-month-day strings, so daylight-saving changes never shift a day.
- Ignore any `read_days` row dated in the future (device clock set forward then back).

### Streak calculation (pure function, `domain/streak.dart`)

- `currentStreak`: number of consecutive days with a row, ending **today** if today has a row, otherwise ending **yesterday** (the streak is still alive until today ends). If neither today nor yesterday has a row, it is 0.
- `longestStreak`, `totalDays`, `totalVerses` (sum of `verse_count`).
- No "streak freeze", no repair, no purchase. Keep it simple.

### Popup

- Trigger: the moment today first qualifies. Show once per day (`streakPopupShownDate`).
- Style: a small solid card (not glass) that slides up above the nav pill, 4 seconds auto-dismiss or tap to dismiss, one light haptic. Never blocks swiping or scrolling. Under reduced motion: fade only.
- Content: a message from the `popup_good_work` category, plus the streak line: "Day {streak}". If the streak is 1, say "Day 1. A beginning."
- Buttons: a quiet "Share" text button (opens the share card, section 8). Nothing else.
- Milestones (1, 3, 7, 21, 40, 108, 365): use a `milestone` message for that number instead, and show it at most once per number (`milestonesShown`).
- After a missed day: the first read shows a `comeback_popup` style message from the `comeback` category, not a streak-broken message. No guilt.

### Profile streak card

- A calm card at the top of Profile: current streak number (large), "day streak", longest streak, total days read, and a 7-dot strip for the last 7 days (filled for read days). No red colours, no warnings.
- Zero state: "Read one verse to begin your streak."

### Wording default

The owner liked "Krishna is watching you, keep it up." Default to warmer wording such as "Krishna is pleased with your effort." Avoid "watching" and any surveillance feeling. All wording lives in the message bank JSON, so it can be changed without code.

---

## 5. Stage B: Notifications

### Packages (confirm current versions and APIs from each package's docs before coding)

`flutter_local_notifications`, `timezone`, `flutter_timezone`. No push services, no Firebase.

### Platform setup

- **Android:** `POST_NOTIFICATIONS` (Android 13+), `RECEIVE_BOOT_COMPLETED` and the package's boot receiver so schedules survive reboot. Use **inexact** scheduling (`inexactAllowWhileIdle`) so no exact-alarm permission is needed; delivery within a few minutes is acceptable. Three notification channels: "Daily reading reminder", "Streak nudges", "Verse of the day". A monochrome small icon. Tapping opens the app.
- **iOS:** ask for notification permission only when the user turns reminders on. iOS keeps at most **64** pending local notifications, so never schedule more than that.
- Confirm after building that the release Android manifest still has **no** `INTERNET` permission.

### Settings UI: Profile, "Reminders" page (new row under Reading)

- Master switch "Daily reminder". Turning it on triggers the permission request. If denied: show a calm explanation and a button that opens the system settings. Keep the switch off.
- Time picker for the reminder time (default 8:00).
- Switch "Streak nudge in the evening" with time (default 20:30).
- Switch "Verse of the day notifications".
- A short note: "Reminders are scheduled on this phone. Nothing is sent from a server."
- A tip for phones that block background work: "If reminders arrive late, allow background activity for this app in your phone's battery settings."

### Types of notification

| Slot | Category | When it is scheduled |
| --- | --- | --- |
| morning | `invite`, `reflection`, `random_verse` (rotating) | Every day at the reminder time |
| morning | `comeback` | A day on which the user has not opened the app for 1 or more days |
| evening | `streak_risk` | Only when the current streak is 1 or more and today has not counted |

Milestone messages are shown in the in-app popup only, not as notifications.

### Scheduler (pure Dart logic plus a thin plugin wrapper; unit test the logic)

Rebuild the schedule **on every app open and resume**, and after settings change:

1. Cancel all pending notifications.
2. If reminders are off or permission is missing, stop.
3. Schedule a window of the **next 14 days** (max 28 notifications, well under the iOS limit).
4. For each day `D` in the window and each slot:
   - If `D` is today and the time has already passed, skip.
   - If `D` is today and today has already counted, skip both slots (the user already read).
   - Choose the category (section above). Rotation for the morning slot when the user is active: `invite, random_verse, reflection, invite, random_verse, invite, reflection`, repeating.
   - If a `notif_assignments` row exists for `(D, slot)`, reuse that message. Otherwise pick a message at random seeded by the date, excluding message ids assigned in the last **60 days**, and save the assignment.
5. When today first counts, immediately cancel today's pending notifications (the evening nudge must not fire after the user has read).
6. **Back-off so the app never nags:**
   - After **3 days** without opening the app: stop the evening nudge.
   - After **7 days**: send only one morning notification every 3 days.
   - After **30 days**: send nothing until the app is opened again.
7. On time-zone change or device-clock change (detected on resume), rebuild.

### Random verse notifications (`random_verse`)

- Pick an entry at random from the dataset, not equal to today's daily verse, not shown in the last 60 days.
- Title: a short lead-in from the bank (for example "A verse for today"). Body: the verse's translation in the user's language, cut at a word boundary to about 120 characters with "…" if shortened, followed by the reference, for example "BG 2.47". Do not alter the words. Store the verse id in `notif_assignments`.
- Tapping opens the reader at that verse (`/gita?verse=<id>`).

### Notification text limits

Title at most 40 characters, body at most 140 characters, plain text, at most one emoji (a lotus or folded hands) in a message, and many messages have none.

---

## 6. Stage C: Message bank (500+ written messages)

The bank is a bundled JSON file, `assets/messages/messages.json`, about 100-150 KB. Claude Code writes it, in original wording.

### Schema

```json
{
  "version": 1,
  "messages": [
    {
      "id": "invite-0001",
      "category": "invite",
      "title": { "en": "A quiet minute", "hi": "..." },
      "body": { "en": "One verse is enough for today.", "hi": "..." },
      "reviewed": false
    }
  ]
}
```

Placeholders allowed in text: `{streak}` and `{days}`. If `hi` is missing, the app uses `en`.

### Categories and minimum counts

| Category | Min count | Used in | Tone |
| --- | --- | --- | --- |
| `invite` | 150 | Morning notification | Warm, short, inviting |
| `streak_risk` | 100 | Evening notification | Gentle reminder that today is still open |
| `comeback` | 80 | Morning notification and popup after a gap | Welcoming, no guilt |
| `milestone` | 30 | In-app popup (keyed by day number) | Quietly proud |
| `reflection` | 120 | Morning notification | A thoughtful question or prompt |
| `popup_good_work` | 60 | In-app popup | Encouraging |
| `verse_lead_in` | 20 | Title for random verse notifications | Short |

That is **560 written messages** plus the 700-entry dataset for random verse notifications.

### Writing rules

- Original wording only. No quotations attributed to Srila Prabhupada or any other person. Do not quote scripture inside the bank; verse text comes only from the dataset at run time.
- No fear, shame, guilt, pressure or surveillance language. Do not say "you failed", "you lost your streak", "you are lazy", "Krishna is watching you", or similar.
- No claims about spiritual results, miracles, health or guaranteed outcomes.
- Inclusive for beginners; do not assume the reader's background.
- No duplicates or near-duplicates. Vary sentence openings.
- Hindi versions: write them for every message, flag all as `reviewed: false`, and add them to `docs/review-needed.md` for a native speaker to check.

### Tone examples (guidance only; write fresh ones)

- invite: "One verse is enough for today. Ready when you are."
- streak_risk: "Your {streak}-day reading is still open today. One verse keeps it going."
- comeback: "Welcome back whenever you are ready. Your place in the Gita is saved."
- milestone (7): "7 days of reading. A real habit is forming."
- reflection: "What is one thing you are holding on to today? Read a verse and sit with it."
- popup_good_work: "Good work. Krishna is pleased with your effort. Keep it up."

### Validator (`tool/validate_messages.dart`, run in CI)

Checks: ids unique; every category meets its minimum count; title at most 40 and body at most 140 characters; no empty text; no exact duplicates; no banned phrases (`watching you`, `failed`, `lazy`, `shame`, `guilt`, `lost your streak`, `you must`); placeholders valid; milestone messages exist for 1, 3, 7, 21, 40, 108 and 365; Hindi present flag reported (warning only). Write messages in batches by category and run the validator after each batch.

### Size check

Record the file size in `docs/perf.md`. It should stay well under 300 KB.

---

## 7. Privacy and permissions summary

- New permissions: notifications (asked only when the user turns reminders on) and, on Android, boot-completed so reminders survive a restart. Nothing else.
- All streak, search and reminder data stays on the phone. Sharing only hands an image to the system share sheet; the app itself makes no network call.
- Update the About screen's privacy note to say so, after re-checking the final dependency list (as in v1).

---

## 8. Stage D: Completion share card

- Entry points: "Share" on the Good-work popup, and a "Share" button on the Profile streak card.
- Card content (choose automatically): if the user has a streak of 2 or more, "{N}-day reading streak"; otherwise "I read today's verse". Add total verses read, the date, and "Bhagavad-gita As It Is" in small text. No Sanskrit or purport text is required on the card.
- Design: portrait 1080 x 1350, warm `bg`, saffron accent, Literata for the number, current theme (light or dark) at the time of sharing. Quiet and minimal, no confetti. Same fonts as the app; confirm they are loaded before rendering.
- Implementation: render an off-screen widget with a `RepaintBoundary` to a PNG (pixel ratio 3), save to a temp file, share with `share_plus`. No upload, no network.
- Caption: "I'm reading the Bhagavad-gita daily." A store link is added later through a single config constant `shareLink` (empty for now; omit it when empty).
- Do not include any personal data (no name, no location).

---

## 9. Stage F: Chapter summaries

- 18 summaries of about 150-250 words each, in English, with Hindi versions flagged for review.
- **Source rule:** write each summary only from the bundled text of that chapter (translations in the dataset). Do not add outside facts or claims. Do not quote the purport beyond a few words. Do not write "Prabhupada says" unless that is explicit in the dataset text.
- **Label:** every summary page and the card shows: "Summary. Not part of Srila Prabhupada's text."
- File: `assets/summaries/summaries.json` with `chapter`, `en`, `hi`, `reviewed`. Validate: exactly 18, non-empty, word-count range, the label constant present in the UI.
- UI: each row in the chapter sheet gets a small "Summary" text button. It opens a full-screen summary page `/gita/summary/:chapter` (reading typography as in the purport page, glass back button) with a "Start chapter" button that opens the reader at the first entry. Also add an "i" icon button in the reader's top row for the current chapter.
- Summaries follow the app language (English or Hindi, falling back to English).
- Add to `docs/review-needed.md` as "needs owner review before release".

---

## 10. Stage E: Keyword search

### Index

- Build a local SQLite FTS5 index from the bundled JSON on first launch (and when the dataset version changes), in an isolate with a one-time "Preparing search" note. 700 entries is quick. Keep the index separate from user data (its own database file or its own tables).
- Columns: `entry_id` (unindexed), `label`, `translation_en`, `translation_hi`, `transliteration`, `sanskrit`, `purport` (plain text with markup stripped).
- Tokenizer: `unicode61` with diacritic removal, so "krsna", "krishna" and "kṛṣṇa" can match. Add a small alias list (`assets/search/aliases.json`) mapping common spellings to the transliterated forms (for example `krishna` to `kṛṣṇa`, `arjun` to `arjuna`, `geeta` to `gītā`). Build it from words that actually appear in the dataset; never invent entries.
- Ranking: `bm25` with column weights (translation highest, then transliteration, then purport). Prefix matching for words typed so far.
- Hindi text works with the unicode61 tokenizer on whitespace-separated words.

### Search page (`/search`, pushed, full screen)

- Entry: a search icon button (glass icon button) at the top right of Home, next to the language toggle, and a search icon in the reader's top row overflow. No fourth tab.
- Autofocused input, debounce 250 ms, clear button, recent searches (max 20, clearable), and 10-12 suggested theme chips (from section 11 themes) when the box is empty.
- Results list: `VerseListTile`-style rows showing the reference, chapter title, and a highlighted snippet in the selected language. Group results as "Translation matches" and "Purport matches" when both exist. Tap opens the reader at that entry.
- Empty result: "No verses found. Try a different word."
- All lazy lists; typing must never jank.

---

## 11. Stage G: Situation search ("sadness", "free thinking")

### Theme map

- `assets/search/themes.json`: about **100-150 themes**, each with `id`, `title` (en/hi), `synonyms` (English, Hindi, and common Hinglish spellings, for example "udaas", "gussa"), `verseIds` (3-8 entries, ranked), `reviewed: false`.
- **How to build it without guessing (mandatory process):**
  1. For each theme, search the bundled dataset with the FTS index (translations and purports) using the theme's keywords.
  2. Read the candidate verse texts from the dataset and keep only verses whose text actually addresses the theme.
  3. Never choose verses from memory of "which verse is about X". Every mapped verse must be justified by its dataset text.
  4. Validate that every `verseId` exists and no theme has fewer than 3 verses.
  5. Export `docs/theme-review.csv` with theme, verse label and a short snippet of the verse translation so the owner can check each mapping quickly.
- Example themes (not exhaustive): peace of mind, anger, fear, grief, doubt, duty, purpose, detachment, devotion, control of the mind, success and failure, loneliness, stress, desire, patience, freedom and free will, knowledge, humility, forgiveness, sadness, motivation, death and the soul, work and results.

### Matching

- Normalise the query (lowercase, trim, remove diacritics).
- Match against theme titles and synonyms: exact, then prefix, then fuzzy (edit distance 1 for words of 5 letters or more). Short multi-word queries ("free thinking") match if any synonym phrase matches.
- If a theme matches: show a heading "Verses on {theme}" with the theme's verses first, then keyword results below.
- If no theme matches: keyword results only.
- Do not use any network or language model.

### Sensitive queries (required)

For queries about suicide, self-harm, wanting to die, or abuse (include English, Hindi and Hinglish variants):
- Show a calm message first: "If you are in pain or thinking of harming yourself, please talk to someone you trust or contact a local crisis line right now. You do not have to carry this alone." Provide one tappable line to call the local helpline number defined in a config file, and mark that number in `docs/review-needed.md` as **must be verified by the owner before release** (Claude Code must not invent a number).
- Then, below, optionally show the matched verses of the closest themes (for example hope, shelter, courage), with no medical or promise-like wording.
- Do not store these queries in `search_history`.

---

## 12. Rules to add to CLAUDE.md

```markdown
## v2 additions
- v2 spec is in docs/PRD_v2.md. It overrides v1 for notifications, streaks, search, summaries and sharing only.
- Still no backend, no network calls, no analytics. Scripture text is never generated or edited.
- Written content (messages, summaries, theme map) carries reviewed:false until the owner reviews it. List everything needing review in docs/review-needed.md.
- Never invent a helpline number. Never map a verse to a theme from memory; use the dataset text.
- Do not build audio. When all other v2 stages are finished, tell the owner: "All v2 features except audio are complete. Only audio remains."
```

---

## 13. Audio (Stage H, blocked: do not build)

Audio needs recordings and the right to use them. The owner will decide between: (a) permission from the BBT for their audio, (b) volunteer-recorded Sanskrit shlokas, (c) the phone's built-in text-to-speech for translations only. Claude Code must not build anything for audio until the owner writes a new spec. When the other stages are done, only report that audio remains and list what the owner needs to provide (section 15).

---

## 14. Staged TODO list (do in this order)

### V2-0: Setup
- [x] Update `CLAUDE.md` with section 12; copy this file to `docs/PRD_v2.md`; create `docs/review-needed.md`.
- [x] Add packages from section 5 and `share_plus` (confirm versions and current APIs).
- [x] Drift schema v2 with migration and migration test; add new settings keys with validation.
- [ ] Android manifest permissions (`POST_NOTIFICATIONS`, boot receiver); confirm no `INTERNET` in the release manifest. (Permissions added; merged release manifest not checked yet.)

**Done when:** the app builds on both platforms, migration test passes, v1 tests still pass.

### V2-1: Streak and popup (Stage A)
- [x] `ReadRule` config and qualifying-read detection (reader, purport, Home) with tests.
- [x] `domain/streak.dart` with unit tests: consecutive days, gap, today-not-read still alive, longest streak, future-dated rows ignored, leap day, daylight-saving change.
- [x] Persist `read_days` and `read_day_verses`.
- [x] Popup (once per day, milestones, comeback variant) using a starter set of 30 `popup_good_work`, `comeback` and `milestone` messages from the bank.
- [x] Profile streak card with 7-dot strip and zero state.
- [x] Reset and clear-history behaviour from section 3.

**Done when:** reading a verse for 5 seconds starts a streak, the popup shows once that day, and everything survives a restart.

### V2-2: Notification engine (Stage B)
- [x] Scheduler logic (pure Dart) with unit tests: 14-day window, skip when read, category choice, rotation, 60-day no-repeat, stable assignments, back-off after 3, 7 and 30 days, iOS limit.
- [x] Plugin wrapper, channels, permission flow on opt-in, denied state UI, boot handling.
- [x] Rebuild on open, resume, settings change, time-zone change; cancel today's notifications when today counts.
- [x] Random verse notifications using dataset text, truncation rule, tap opens the reader at that verse.
- [x] Profile "Reminders" page (section 5).
- [x] Starter bank of at least 60 messages across categories so it works end to end.

**Done when:** on a real phone a reminder arrives at the chosen time, tapping it opens the app, and reading cancels the evening nudge. (Real-device check goes to `docs/review-needed.md` if you cannot do it.)

### V2-3: Full message bank (Stage C)
- [x] Write the full bank to the counts in section 6, batch by category, validating after each batch.
- [ ] `tool/validate_messages.dart` in CI.
- [x] Hindi versions written and flagged; record file size.

**Done when:** the validator passes with 500 or more written messages.

### V2-4: Share card (Stage D)
- [x] Off-screen card widget, PNG render, share sheet, both entry points.
- [ ] Widget tests for card variants in light and dark.

**Done when:** sharing from the popup and from Profile opens the system share sheet with the image.

### V2-5: Keyword search (Stage E)
- [x] FTS5 index build in an isolate, versioned by dataset version, with tests (diacritics, aliases, Hindi, prefix).
- [x] Search page, recent searches, suggested chips (can be a short fixed list until V2-7), results, empty state.
- [x] Search icon on Home and in the reader; "Clear search history" in Profile.

**Done when:** typing "krishna" or "kṛṣṇa" or a Hindi word returns relevant entries quickly and opens the right verse.

### V2-6: Chapter summaries (Stage F)
- [x] Write 18 summaries from the dataset text only; Hindi versions flagged.
- [x] Validator, summary page, "Summary" button in the chapter sheet, reader "i" button, label on every summary.

**Done when:** every chapter opens its summary and "Start chapter" opens the reader.

### V2-7: Situation search (Stage G)
- [x] Build `themes.json` using the mandatory process in section 11; export `docs/theme-review.csv`.
- [x] Theme matcher with tests (synonyms, Hindi and Hinglish, fuzzy, multi-word).
- [x] Search page integration: theme results first, keyword results below; suggested chips from real themes.
- [x] Sensitive-query handling and the helpline config (flag the number for owner verification).

**Done when:** "sadness" and "free thinking" return themed verses first, sensitive queries show the care message, and every mapped verse id exists.

### V2-8: Polish and QA
- [ ] Accessibility pass on all new screens (labels, text scale 2.0, contrast, reduced motion).
- [ ] Performance check: search typing smooth, popup does not delay swipes, schedule rebuild is fast.
- [ ] Full integration test: read, popup, restart, streak persists; notification opt-in denied path; offline run; reset all data.
- [ ] Update the About and privacy note: reminders are local, no data leaves the phone. Re-review the dependency list; confirm no network permission.
- [x] Write `docs/v2-status.md`.

**Done when:** `flutter analyze`, `flutter test` and the integration run pass.

---

## 15. Completion protocol (what to tell the owner at the end)

When V2-8 is done, send the owner a message that starts with exactly:

> **All v2 features except audio are complete. Only audio remains.**

Then list:
1. The items waiting on the owner's review (from `docs/review-needed.md`): message bank wording, Hindi strings, 18 chapter summaries, the theme map (`docs/theme-review.csv`), the helpline number, the share link constant.
2. What was tested only in simulation and needs a real phone (notification delivery on at least one Android and one iPhone).
3. What the owner must provide before audio can start: which audio route (BBT permission, volunteer recordings, or phone text-to-speech), the audio files if any, and the hosting choice.

Then stop. Do not begin audio.
