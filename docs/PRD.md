# Bhagavad Gita Offline App — PRD, UI/UX Spec & Build Plan

Oct 28, 2026 · @Devang

## 0. How to use this doc

This doc is written so Claude Code can build the whole app from it, one small stage at a time. Export it as Markdown, save it in your repo as `docs/PRD.md`, and follow the steps below.

1. Export this doc to Markdown and put it at `docs/PRD.md` in a new Flutter project.
2. Copy the "CLAUDE.md rules" block from section 9 into `CLAUDE.md` at the repo root.
3. Paste the kickoff prompt for Stage 0 (section 9). Do one stage per session, run the tests, then tick the boxes.
4. Never let Claude Code skip ahead. Each stage ends with something you can run on a phone.

I resolved every gap in your spec with a low-risk default so you are not blocked. The table below lists them; change any you disagree with before starting.

| # | Decision | Default I chose | Why |
| --- | --- | --- | --- |
| 1 | Scripture storage | 18 bundled JSON files (one per chapter) plus one chapters index, read lazily and cached in memory | Simple, easy to validate in a script, no database copy step, fast enough for 700 verses |
| 2 | State management | Riverpod | Testable, light, works well with async data and persisted settings |
| 3 | Navigation | go\_router with a stateful shell (3 tabs keep their own state) | Keeps each tab's reading position when you switch tabs |
| 4 | User data | SQLite via drift for favourites, bookmarks, history; last position in preferences; shared\_preferences for theme, language, text size | Matches your spec: structured data in SQLite, small settings separate |
| 5 | Daily verse | Pure function of the local date, no storage needed (section 2) | Same verse all day, changes at local midnight, never calls a network |
| 6 | First launch | One skippable screen: choose English or Hindi, then straight to Home | Your spec says "initial setup" but no onboarding; this is the minimum |
| 7 | Reading history | One row per verse (latest visit wins), capped at 200, recorded after the verse stays open 2 seconds | Prevents swipe-through from flooding history |
| 8 | Text size | Included: 5 steps (Small to Extra large) | Needed for accessibility and cheap to build |
| 9 | Orientation and tablets | Portrait only; on tablets content is centred at max 600 px wide | Phone-first; avoids untested layouts |
| 10 | Minimum OS | Android 8.0 (API 26) and iOS 15 | Assumption; confirm against your audience |
| 11 | Search | Not in v1 (you did not list it) | Keeps scope tight |
| 12 | Sharing verse as text or image | Not in v1 | Not in your spec; easy to add later |

Open questions that I could not safely default are collected in section 9.

## 1. Product overview

A free, offline, ad-free Flutter app for reading Srila Prabhupada's Bhagavad-gita As It Is: open it, read one verse, and either stop or keep reading the full scripture. It is meant to replace a few minutes of doom-scrolling, not to compete for attention.

**Working name:** "Gita" (placeholder, see open questions).

### Who it is for

- Beginners who want one verse a day without any setup.
- Regular readers who want to move through chapters quickly and return to where they stopped.
- Devotees who want Prabhupada's purports in a calm, book-like layout, in English or Hindi.

### The core loop

1. Open the app and land on today's verse (Home).
2. Read the Sanskrit and translation. Optionally open the purport.
3. Tap "Continue reading" to enter the Gita tab at the same verse, or close the app. Nothing nags, nothing streaks.

### Principles (every feature must pass these)

- **Effortless:** the app opens to something readable in under 2 seconds, with no sign-in and no permission prompts.
- **Beautiful text:** typography and whitespace come before decoration.
- **Discoverable:** chapter sheet, verse selector, favourites, bookmarks, history.
- **Offline:** every verse and purport is inside the app; no network permission needed.
- **Calm:** no feeds, streaks, badges, leaderboards, notifications, or ads.

### Scope

| In version 1 | Out of version 1 (needs your approval) |
| --- | --- |
| Home with daily verse | Accounts, cloud sync or backup |
| Gita reader: 18 chapters, 700 verses, swipe navigation | AI interpretations or chatbot |
| Dedicated purport page | Social features, comments, communities |
| English and Hindi translation switch; Sanskrit always shown | Streaks, gamification, push notifications |
| Favourites and Bookmarks (separate) | Ads, subscriptions, in-app purchases |
| Reading history and resume | Online fetching or streaming of content |
| Light, dark and system themes; text-size setting | Search, share-as-image (candidates for v1.1) |
| Liquid Glass bottom navigation |  |

### Release criteria (no analytics, so these are checks, not metrics)

- All 700 verses pass the validator and match the authorised source.
- A fresh install works in airplane mode, start to finish.
- Devanagari renders correctly on one low-end Android and one recent iPhone.
- Cold start to first readable verse is under 2 seconds on a mid-range Android phone.
- No text overflow at the largest text size on a 360 px wide screen.

### What the user keeps and loses

Favourites, bookmarks, history and settings live only on the device. Uninstalling the app or switching phones removes them. Version 1 has no cloud backup; the Profile screen says this in plain words.

## 2. Technical architecture

The app is a feature-first Flutter project with four thin layers and no backend. Keep it boring: every layer below exists because a test or a screen needs it.

| Layer | Holds | Rule |
| --- | --- | --- |
| Presentation | Screens, widgets, design system | No database or asset calls; reads state from providers only |
| Application | Riverpod providers and notifiers (reader state, settings, library) | Orchestrates; contains no UI code |
| Domain | Plain Dart models and pure functions (daily verse, verse navigation) | No Flutter imports, 100% unit tested |
| Data | `ScriptureRepository` (assets), `UserDataRepository` (SQLite), `SettingsRepository` (preferences) | The only place that touches storage |

### Folder structure

```text
lib/
  main.dart
  app/                 # app widget, router, theme wiring, bootstrap
  core/
    design/            # tokens, theme, typography, glass widgets, shared components
    utils/             # date helpers, haptics, reduced-motion helper
  domain/
    models/            # Chapter, VerseEntry, Favourite, Bookmark, HistoryItem
    daily_verse.dart   # pure function
    verse_navigation.dart
  data/
    scripture/         # asset loader, JSON parsing, validator hooks
    user/              # drift database, DAOs
    settings/          # shared_preferences wrapper
  features/
    home/
    gita/              # reader, chapter sheet, verse selector
    purport/
    profile/           # library, settings, about/credits
    first_launch/
assets/
  scripture/           # chapters.json, chapter_01.json ... chapter_18.json
  fonts/               # bundled font files + licences
tool/
  validate_scripture.dart   # run in CI and before release
test/  integration_test/  docs/
```

### Packages (let Claude Code confirm current versions with `flutter pub add`)

| Need | Package | Notes |
| --- | --- | --- |
| State | `flutter_riverpod` | No code generation, to keep builds simple |
| Navigation | `go_router` | `StatefulShellRoute` for the 3 tabs |
| User data | `drift` + `sqlite3_flutter_libs` | Type-safe SQLite; in-memory DB for tests |
| Settings | `shared_preferences` | Theme, language, text size, last position |
| Liquid Glass | `liquid_glass_renderer` | Shader-based refraction; pre-release (0.2.0-dev at time of writing), so pin the exact version |
| App info | `package_info_plus` | Version on the About screen |
| Fonts | Bundled font files, not `google_fonts` | `google_fonts` downloads at runtime unless fonts are bundled; offline-first means bundle them |
| Tests | `flutter_test`, `integration_test`, `mocktail` |  |
| Icons and splash | `flutter_launcher_icons`, `flutter_native_splash` | Dev-only |

Do not add analytics, crash reporting SDKs, ads, or Firebase. Before release, run `flutter pub deps` and review the final list before making any privacy claim.

### Daily verse (deterministic, no storage)

Goal: one verse per local calendar day, random-looking, no repeats until every entry has been shown once.

1. Take the local date (year, month, day) and convert it to a day number: whole days since 2024-01-01 using UTC date arithmetic on the local Y-M-D, so DST never shifts it.
2. Let `N` be the number of entries in the dataset. `cycle = day / N`, `position = day % N`.
3. Build a permutation of `0..N-1` with a Fisher-Yates shuffle seeded by `cycle`. Use a small hand-written PRNG (for example mulberry32), not `dart:math Random`, so results never change across Dart versions.
4. If the first entry of this cycle equals the last entry of the previous cycle, swap it with the second.
5. The entry at `position` is today's verse. Recompute on app resume and at local midnight.

Unit tests must cover: same date gives same entry; consecutive days differ; 2 full cycles contain every entry once each; a date across a DST change; a leap day.

### Reader mechanics

- One `PageView` per chapter, one page per entry. Page content scrolls vertically if it is long.
- Reading position is stored by stable verse ID, never by list index, so switching language or theme cannot move the reader.
- Persist last position 600 ms after the page settles (debounced), plus on app pause.
- Chapter edges: the first page has no previous; the last page ends with a quiet "Continue to Chapter N" text button (no automatic chapter jump). On Chapter 18's last entry the button is replaced by "You have reached the end" with a link back to Chapter 1.
- Pre-parse the current chapter plus the next chapter in an isolate so swiping never waits on JSON parsing.

### Gesture conflicts to handle

- Horizontal `PageView` swipe against vertical scrolling of long verses: use the default `PageView` physics and a vertical `SingleChildScrollView` in each page; test diagonal flicks.
- Android gesture navigation back swipe from the screen edge: keep a 16 dp horizontal dead zone at both edges of the reader (content padding), and test on 3-button and gesture navigation.
- iOS edge swipe back works only on pushed routes (the purport page), not on the tab roots, so it does not conflict.
- The glass nav bar floats above content; scrollable areas need bottom padding equal to the bar height plus safe area.

## 3. Data model, content pipeline and validation

Scripture is immutable bundled data; user data is mutable and stored separately. Verse IDs are the only link between them, and they never change once published.

### One gap that changes the data model

In Srila Prabhupada's edition, some consecutive verses are printed together with one shared translation and purport (for example a range such as 1.16-18). So the swipe unit is an **entry** (one verse or a verse range), while the "700 verses" count is over individual verse numbers. The model below supports both. The authorised source decides which ranges exist; Claude Code must not guess them.

### Scripture JSON (per chapter file)

```json
{
  "chapter": 2,
  "entries": [
    {
      "id": "bg-02-047",
      "chapter": 2,
      "verseStart": 47,
      "verseEnd": 47,
      "label": "2.47",
      "sanskrit": ["<line 1 in Devanagari>", "<line 2>"],
      "transliteration": ["<line 1>", "<line 2>"],
      "translation": { "en": "<text>", "hi": "<text>" },
      "purport": { "en": [ { "type": "p", "text": "<text with limited inline markup>" } ], "hi": null },
      "synonyms": null
    }
  ]
}
```

Range entries use `"id": "bg-01-016-018"`, `verseStart: 16`, `verseEnd: 18`, `label: "1.16-18"`.

| Field | Rules |
| --- | --- |
| `id` | `bg-CC-VVV` or `bg-CC-VVV-WWW` for ranges. Stable forever. |
| `sanskrit`, `transliteration` | Arrays of lines exactly as in the source; shown regardless of translation language. |
| `translation.en`, `translation.hi` | Both required for every entry. Empty or missing = validation failure. |
| `purport` | Optional per entry. `null` means the source has none; the UI then hides the purport action. Blocks use `type`: `p` (paragraph), `quote` (quoted verse or text), `sanskrit` (Devanagari line). Inline markup limited to `<i>` and `<b>`; rendered into `TextSpan`s by our own parser, never HTML or WebView. |
| `synonyms` | Reserved, optional word-for-word list. Not shown in v1 unless you approve (open question). |

### Chapters index (`chapters.json`)

- Per chapter: number, English title, Hindi title if the source has one, `verseCount` (individual verses), `entryCount` (swipe pages).
- Source block: source name, edition, rights holder, required attribution text, dataset version, and a SHA-256 checksum for each chapter file.
- `isPlaceholder: true` on any development data. The release build must fail validation if any placeholder is present.

Expected counts (chapters, verses per chapter, entries per chapter) come from the authorised source, never from memory. Stage 1 produces `tool/expected_counts.json` and you approve it once.

### Purport language rule (default)

If the user selects Hindi and a Hindi purport exists, show it. If it does not, show the English purport with one quiet line above it: "Purport is available in English." Never machine-translate.

### Content pipeline

1. You supply the authorised source files (see open questions for format).
2. A one-off importer script in `tool/` converts them to the JSON above. It is the only thing allowed to write into `assets/scripture/`.
3. `tool/validate_scripture.dart` runs on every CI build and before every release.
4. A human spot-check compares at least 20 chosen entries, including ranges, the first and last verse of each chapter, and 10 long purports, character by character against the source. Record the result in `docs/content-review.md`.
5. Rule for Claude Code: never hand-edit, "fix", paraphrase or generate scripture text. If the validator reports a problem, report it to you.

### Validator checks

| Check | Failure means |
| --- | --- |
| Exactly 18 chapters, numbered 1-18 | Build fails |
| Verse count per chapter and total (700) match `expected_counts.json` | Build fails |
| Entries ordered; ranges contiguous with no gaps or overlaps | Build fails |
| IDs unique and match `chapter`, `verseStart`, `verseEnd` | Build fails |
| `label` matches the numbers | Build fails |
| Sanskrit, transliteration, `translation.en`, `translation.hi` non-empty | Build fails |
| Sanskrit field contains Devanagari characters; transliteration has none | Build fails |
| Purport blocks use only allowed types and markup; markup balanced | Build fails |
| Checksums in `chapters.json` match files | Build fails (detects accidental edits) |
| Source and attribution block present | Build fails |
| No `isPlaceholder` in release mode | Release build fails |
| Hidden characters, doubled spaces, unmatched quotes | Warning, listed for human review |

Structural validity does not prove textual accuracy, so step 4 above is mandatory before release.

### User data (local only)

| Store | Contents | Notes |
| --- | --- | --- |
| SQLite (drift) `favourites` | `verse_id` (primary key), `created_at` | Separate from bookmarks |
| SQLite `bookmarks` | `verse_id` (primary key), `created_at` | Separate from favourites |
| SQLite `history` | `verse_id` (primary key), `last_read_at` | One row per verse, newest visit wins, capped at 200 |
| shared\_preferences | `lastVerseId`, `languageCode` (`en`/`hi`), `themeMode` (`system`/`light`/`dark`), `textScaleStep` (0-4), `firstLaunchDone` | Invalid or unknown values fall back to defaults |

- **Orphans:** IDs that no longer exist in the dataset are hidden in the UI and purged at startup.
- **Migrations:** drift `schemaVersion` starts at 1; add a migration test whenever it changes.
- **Clear history** clears the history table only; the resume position stays. **Reset all local data** clears everything and returns to first launch. Both need a confirmation dialog.
- **Fonts and content licence:** the Credits screen shows the attribution text exactly as required by your permission, plus font licences (OFL).

## 4. Design system

The look is a warm, quiet reading room: paper-like backgrounds, charcoal text, one muted saffron accent, and glass used only for floating controls, never behind text you read. All values below are starting tokens; Claude Code defines them once in `core/design/` and tunes them on a real device.

### Colour tokens

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `bg` | #FBF8F3 | #14110F | Screen background |
| `surface` | #FFFFFF | #1D1915 | Sheets, dialogs, cards |
| `surfaceSoft` | #F4EFE7 | #26211C | Chips, input wells, selected rows |
| `hairline` | #E8E1D6 | #342E27 | 1 px dividers and borders |
| `textPrimary` | #232120 | #EDE6DC | Body and shloka |
| `textSecondary` | #6B645C | #B5ACA0 | Transliteration, captions |
| `textTertiary` | #9A9288 | #8A8277 | Hints, disabled |
| `accent` | #D2691E | #E39A5E | Selected icons, active states (not for small text in light mode) |
| `accentText` | #A94E14 | #E39A5E | Accent-coloured text and links |
| `accentSoft` | #F6E3D2 | #3A2A1E | Tinted backgrounds |
| `danger` | #B3261E | #F2B8B5 | Destructive confirm only |

Rules: no pure white text on dark, no pure black backgrounds, no gradients on surfaces, no coloured card borders. Add a contrast test: every text and background pair must reach 4.5:1 (3:1 for large text and icons). Adjust hex values if a pair fails.

### Typography

| Role | Font (all bundled, SIL OFL) | Size / line height | Notes |
| --- | --- | --- | --- |
| Sanskrit shloka | Noto Serif Devanagari; try Tiro Devanagari Sanskrit in the Stage 2 specimen test and keep whichever renders conjuncts best | 26 / 1.75, centred | Never letter-spaced; no hyphenation |
| Transliteration | Literata Italic | 16 / 1.6, centred | Must render full diacritics (ā ī ū ṛ ṅ ñ ṭ ḍ ṇ ś ṣ ṁ ḥ) |
| English translation | Literata | 19 / 1.55 | Primary reading text |
| Hindi translation | Noto Serif Devanagari | 19 / 1.7 | Taller line height for matras |
| Purport body | Literata or Noto Serif Devanagari | 18 / 1.7 | Max width 600 |
| UI labels, tabs, buttons | Inter | 13-16 | 500 weight for labels |
| Titles | Literata SemiBold | 28 / 1.25 | Screen titles |
| Reference label ("2.47") | Inter | 13, letter-spacing +0.4 | Uppercase not used |

Text-size setting (5 steps) multiplies reading text only: 0.85, 0.92, 1.0 (default), 1.12, 1.25. UI chrome follows system text scale, clamped to 1.3, so the nav bar never breaks.

Test set for typography (a debug-only "specimen" screen): long Sanskrit compounds, danda and double danda (| and ||), conjunct-heavy words, Hindi with nukta and chandrabindu, transliteration with every diacritic, a 4,000-word purport, and system text scale at 1.3 and 2.0.

### Spacing, shape, motion tokens

| Group | Values |
| --- | --- |
| Spacing | 4, 8, 12, 16, 24, 32, 48 |
| Reading side padding | 24 (phones), content max width 600 centred |
| Corner radius | 8 (chips), 12 (inputs), 20 (cards), 28 (sheets), 999 (pills) |
| Elevation | `none`, `hairline` (border only), `soft` (one shadow: 0 8 24 at 8% black light, 40% black dark) |
| Icon size | 20, 24, 28 |
| Duration | instant 90 ms, fast 160 ms, base 240 ms, slow 360 ms |
| Curves | `easeOutCubic` default, `easeInOutCubic` for position changes, spring only on the nav droplet |
| Touch target | At least 48 x 48 dp everywhere |
| States | Pressed: scale 0.97 + 8% overlay; focus: 2 px accent ring; disabled: 38% opacity |

### Liquid Glass bottom navigation (signature element)

**What it looks like:** a floating pill, not a full-width bar. Content scrolls underneath and is refracted and blurred through the glass. The selected tab sits in a small glass capsule that behaves like a droplet.

| Property | Spec |
| --- | --- |
| Tabs | Home, Gita, Profile. Icon 24 plus a 12 px label below. Icons: `home_rounded`, `menu_book_rounded`, `person_rounded` (outlined when idle, filled when selected) |
| Size and position | Height 64, width screen minus 40 (max 360), centred, 12 above the bottom safe area, fully rounded |
| Selected state | Droplet capsule behind the tab; icon and label in `accent`; others in `textSecondary` |
| Glass look | Refraction at the edge, soft blur, faint specular highlight on top edge, 1 px translucent border, tint around 55-70% of `surface` so labels stay readable in both themes |
| Interaction | Tap switches tab. Drag horizontally across the bar and the droplet follows the finger, stretches slightly with speed, snaps to the nearest tab on release with a short spring (about 380 ms). One `selectionClick` haptic per change |
| Scroll behaviour | Slides down and fades when the user scrolls down on a list or long page; returns on scroll up or tap near the bottom. Always visible on Home. Disabled in reduced-motion (stays visible) |
| Insets | Scrollable content gets bottom padding equal to bar height + 12 + safe area; use `extendBody` so content flows beneath |
| Package | `liquid_glass_renderer` used directly inside our own `GlassNavBar` widget. Do not depend on third-party tab-bar packages (several are early dev releases); use them only as reference |

**Glass tokens:** keep every tunable (thickness, blur, tint opacity, light intensity, refractive index, border opacity) in one `GlassTokens` class, with separate light and dark values, so you can tune by eye without touching widgets.

**Fallbacks (required):**

1. If shaders or Impeller are unavailable, or a frame-time guard trips on a slow device, switch to a frosted version: `BackdropFilter` blur 20, same tint, hairline border.
2. If the system high-contrast setting is on, or the user turns on "Simplified glass" in Profile, use a solid `surface` pill with a hairline border.
3. Reading text is never placed on glass. Glass is only for floating controls.

**Glass budget:** at most 3 glass surfaces on screen at once (they each cost GPU time). Where glass is used:

| Surface | Glass? |
| --- | --- |
| Bottom navigation pill | Yes, full refraction |
| Reader reference pill ("Chapter 2 · 2.47") floating at the top | Yes, light version |
| Purport page back button and favourite/bookmark pill | Yes, light version |
| Chapter bottom sheet | Header grabber area only; the list itself is solid `surface` for legibility |
| Verse selector popover | Solid `surface` with soft shadow |
| Dialogs, settings rows, text areas | No |

### Shared components (build once, reuse)

`GlassNavBar`, `GlassPill`, `GlassIconButton`, `ShlokaView`, `TransliterationView`, `TranslationView`, `PurportView` (block and inline-markup renderer), `SaveToggleButton` (favourite and bookmark, with animation), `ReferenceChip`, `SectionHeader`, `EmptyState`, `SettingsRow`, `SegmentedChoice` (language and theme), `ConfirmDialog`, `AppBottomSheet`, `VerseListTile` (used by favourites, bookmarks, history). No screen may hand-roll a version of any of these.

## 5. Screen specifications

Three tabs, three full-screen pushed pages, one first-launch screen. Every screen below states layout, behaviour, states and edge cases so Claude Code does not have to guess.

### 5.0 Navigation map

| Route | Screen | Notes |
| --- | --- | --- |
| `/welcome` | First launch | Shown once; skipped when `firstLaunchDone` is true |
| `/home` | Home tab | Daily verse |
| `/gita?verse=<id>` | Gita tab (reader) | Optional `verse` query jumps to that entry without animation |
| `/profile` | Profile tab | Library, preferences, data |
| `/profile/favourites`, `/profile/bookmarks`, `/profile/history` | Library lists | Pushed above the tab, nav pill stays visible |
| `/profile/about` | About, Credits and Sources | Attribution, fonts, version, privacy note |
| `/purport/:verseId` | Purport page | Root navigator, full screen, no nav pill |

Each tab keeps its own state when you switch tabs (the reader stays on the same verse). Tapping the active tab scrolls that tab to the top or, on the reader, does nothing. Any saved-verse tap anywhere calls `go('/gita?verse=<id>')`.

### 5.1 First launch (`/welcome`)

- Warm `bg`, centred wordmark "Gita" in Literata, one line: "Read the Bhagavad-gita As It Is. No account. No internet needed."
- A large two-option choice: English or Hindi (हिन्दी). English is preselected.
- One button: "Begin". Text under it: "You can change this later in Profile."
- No permission prompts, no tutorial, no carousel. Sets `firstLaunchDone` and goes to Home with a 240 ms fade.
- Edge cases: if the app is killed on this screen, it shows again next launch.

### 5.2 Home (`/home`)

```text
+--------------------------------+
| Wednesday, 28 October   [EN|हि] |  <- date (secondary), language toggle
|                                |
| TODAY'S VERSE                  |  <- small, accentText
|                                |
|   <Sanskrit, centred, 26>      |
|   <Sanskrit line 2>            |
|                                |
|   <transliteration, italic>    |
|                                |
|   <translation, 19, left>      |
|                                |
|   Bhagavad-gita 2.47           |  <- ReferenceChip
|                                |
|  [Read in Gita ->]  Purport    |  <- accentSoft button, text button
|        (heart)  (bookmark)     |  <- SaveToggleButtons
|                                |
|  Continue: Chapter 3, 3.12  >  |  <- quiet row, only if a position exists
|        [ glass nav pill ]     |
+--------------------------------+
```

- **Content:** Sanskrit, transliteration, translation in the selected language, chapter and verse reference. Whitespace is generous: 32 between blocks, 24 side padding.
- **Actions:** "Read in Gita" opens the reader at this entry. "Purport" opens the purport page (hidden if the entry has no purport). Heart toggles Favourite, bookmark toggles Bookmark. They are separate, each updates instantly (optimistic) and persists.
- **Language toggle:** swaps the translation with a 160 ms cross-fade; same entry stays.
- **Daily verse:** from the pure function in section 2. Re-evaluated when the app resumes and at local midnight, with a gentle 240 ms cross-fade if the day changed while the app was open.
- **Long verses:** the whole page scrolls vertically; nothing is clipped; buttons stay below the translation.
- **Continue row:** shows last read position from `lastVerseId`. Hidden on a fresh install. Single line, tertiary style, not a card.
- **Entrance motion:** Sanskrit, transliteration, translation fade in with an 8 px upward slide, staggered 60 ms. Skipped under reduced motion.
- **States:** loading (scripture not parsed yet) shows the plain `bg` for under 300 ms, no spinner; load error shows a calm message and a Retry button (details only in debug).
- **Do not add:** quotes carousel, streak counter, share button, "verse of the week", banners.

### 5.3 Gita reader (`/gita`)

```text
+--------------------------------+
| [Ch 2 · Yoga of Knowledge v]   |  <- glass top row (light glass)
| [2.47 v]               [EN|हि] |
| ============-------------      |  <- 2 px chapter progress line
|                                |
|      <Sanskrit, centred>       |
|                                |
|      <transliteration>         |
|                                |
|      <translation>             |
|                                |
|   (heart) (bookmark) [Purport] |  <- inline action row
|                                |
|        [ glass nav pill ]      |
+--------------------------------+
```

**Layout and behaviour**

- **Swipe first:** horizontal swipe moves to the previous or next entry inside the chapter. Page transition: the incoming page fades from 60% to 100% and slides 12 px; the outgoing page fades to 60%. Total 240 ms, never blocks the next swipe.
- **Top row (floating glass):** a chapter pill showing chapter number and title (ellipsis if long) opens the chapter sheet; a verse pill showing the current label (e.g. "2.47" or "1.16-18") opens the verse selector; the language toggle sits at the right. Pills are at least 44 dp high and wrap to two rows on narrow screens as drawn.
- **Progress line:** a 2 px accent line under the top row shows position inside the chapter (entry index / entry count). Decorative; excluded from screen readers.
- **Reading surface:** Sanskrit (centred), transliteration (centred, italic, secondary), translation (left aligned for readability), in that order. Sanskrit is visually distinct by size and font. Page scrolls vertically if text is long; the swipe still works.
- **Actions (inline, below the translation):** Favourite, Bookmark, Purport (hidden when the entry has none). Nothing else.
- **Language switch:** cross-fades the translation in 160 ms, keeps the same entry and scroll offset; Sanskrit and transliteration stay.
- **Position:** saved as `lastVerseId` 600 ms after a page settles and on app pause. An entry is added to history after it has been visible for 2 seconds.
- **Resume:** opening the Gita tab for the first time in a session shows `lastVerseId`; with none stored it shows Chapter 1, first entry.
- **Edges:** the first entry has nothing before it (a light overscroll glow). The last entry of each chapter shows a quiet text button "Continue to Chapter N" below the actions; on Chapter 18 it reads "You have reached the end of the Gita" with "Begin again at Chapter 1".
- **Preloading:** the next and previous entries are built ahead; the next chapter is parsed in the background.
- **Haptics:** `selectionClick` only when choosing from a selector; none on swipes.
- **Error:** if a chapter file fails to load, show a calm message and Retry inside the reader; the nav pill still works.

### 5.4 Chapter sheet (bottom sheet)

```text
+--------------------------------+
|            ----                |  <- grabber (glass header)
|  Chapters                      |
|  (1)  Observing the Armies...  |
|        NN verses               |
|  (2)  Contents of the Gita...  |  <- current chapter highlighted
|        72 verses               |
|  ... 18 rows ...               |
+--------------------------------+
```

- Slides up in 360 ms (ease-out), up to 85% of screen height, draggable to dismiss, scrim at 40%.
- 18 rows, each: number in a circle, full chapter title (up to 2 lines), "N verses" (secondary). Current chapter has `accentSoft` background and a check mark. Scrolls to the current chapter on open.
- Row height at least 64 dp. Tapping a row closes the sheet and opens that chapter at its first entry; if it is the current chapter, it just closes.
- Chapter titles and verse counts come from `chapters.json`; the counts shown are individual verses.

### 5.5 Verse selector (compact sheet)

- Opens from the verse pill as a bottom sheet about 45% tall: title "Chapter 2 - 72 verses" and a wrapping grid of chips, 5 per row on a 360 dp screen, each at least 48 x 44.
- Chips show the label ("47" or "16-18"). The current entry is filled with `accent`. Entries with a favourite or bookmark show a small dot (optional polish, Stage 8).
- Tap jumps to that entry with a 240 ms animated page change (a jump without animation if more than 5 entries away) and closes the sheet.
- Handles chapters from 20 to 78 verses without scrolling problems; the sheet grows to a maximum of 70% and scrolls.
- There is no permanent left rail.

### 5.6 Purport page (`/purport/:verseId`)

```text
+--------------------------------+
| (<)                (h)(b)(Aa)  |  <- glass back, glass action pill
|                                |
|  BHAGAVAD-GITA 2.47            |
|  <Sanskrit, centred>           |
|  <transliteration>             |
|  <translation>                 |
|  ------------------------      |
|  PURPORT                       |
|  <paragraph>                   |
|  <paragraph>                   |
|    | <quoted verse, indented>  |
|  <paragraph>                   |
|  [ Back to verse ]             |
+--------------------------------+
```

- **Feels like a typeset book page:** no cards, no boxes. A single hairline separates verse and purport. Text column max 600, side padding 24, paragraph spacing 14, line height 1.7, no justification (ragged right avoids rivers).
- **Top controls (floating glass):** back button at left; at right one pill with Favourite, Bookmark and "Aa" (text-size popover with the 5 steps and a live "Aa" preview). The pill fades to 70% opacity while scrolling down and returns on scroll up.
- **Reading progress:** a 2 px accent line at the very top grows as you scroll. Decorative.
- **Content:** reference, Sanskrit, transliteration, translation in the selected language, then purport blocks rendered by `PurportView` (`p`, `quote`, `sanskrit`, inline italic and bold).
- **Language:** follows the app language. When Hindi is selected but only an English purport exists, a one-line note appears above it: "Purport is available in English."
- **Back:** glass back button, Android system and predictive back, and iOS edge swipe. Returning leaves the reader on the same entry (the reader state is untouched). While the app runs, reopening the same purport restores its scroll offset.
- **Transition:** slides up 16 px with a fade, 240 ms; reversed on back. Under reduced motion it is a plain 160 ms fade.
- **Long purports:** the page is a single lazy `CustomScrollView` (one sliver per block) so a 4,000-word purport scrolls smoothly and never overflows.
- **Reachability:** only entries with a purport show the entry button; if the route is opened for an entry without one (a bad link), show "This verse has no purport" and a back button.
- **Defaults not in your spec:** text selection and copy are off in v1; no previous/next-verse arrows here; no summaries or AI text of any kind.

### 5.7 Profile (`/profile`)

There is no account, photo or username. Profile is a quiet local library plus settings.

```text
+--------------------------------+
| Your library                   |  <- Literata 28
| Saved on this device only      |
|                                |
| Continue: Chapter 3, 3.12    > |
|                                |
| Favourites                 12 >|
| Bookmarks                   4 >|
| History                    38 >|
|                                |
| READING                        |
| Translation   [English|हिन्दी] |
| Theme    [System|Light|Dark]   |
| Text size      A --o------ A   |
| Simplified glass          ( )  |
|                                |
| ABOUT                          |
| About and credits            > |
|                                |
| YOUR DATA                      |
| Clear reading history          |
| Reset all saved data           |  <- danger colour
| Your favourites, bookmarks and |
| history are stored only on     |
| this phone and are not synced. |
|        [ glass nav pill ]      |
+--------------------------------+
```

- **Layout:** one scrolling page with grouped rows (`SettingsRow`), hairline dividers, no cards. Counts update live.
- **Continue row:** same behaviour as on Home; hidden if there is no position.
- **Library lists (Favourites, Bookmarks, History):** pushed page with a back button and a title. Each `VerseListTile` shows the reference ("2.47"), the chapter title in secondary text and the first 2 lines of the translation in the selected language. Newest first. Tap opens the reader at that verse. Swipe left (or long-press menu for screen readers) removes an item from Favourites or Bookmarks with an "Undo" snackbar for 5 seconds. History has "Clear" in the top right with a confirmation dialog. A list can hold hundreds of items, so use a lazy `ListView.builder`.
- **Translation:** changes language everywhere immediately and is persisted.
- **Theme:** System, Light, Dark; applied with a 240 ms cross-fade; persisted. Invalid stored value falls back to System.
- **Text size:** 5-step slider with a live sample sentence; applies to Sanskrit, transliteration, translation and purport.
- **Simplified glass:** off by default; when on, all glass surfaces use the solid fallback.
- **Reduced motion:** follows the phone's system setting, no in-app switch.
- **Clear reading history:** confirmation dialog: "Clear your reading history? Favourites and bookmarks are kept." It does not clear the resume position.
- **Reset all saved data:** confirmation dialog naming exactly what will be removed (favourites, bookmarks, history, settings, resume position); the destructive button uses `danger`. After reset, the app returns to the first-launch screen.
- **About and credits:** app version, the exact attribution and permission wording you supply, edition and source, font licences, and a plain privacy note ("works offline, no account, reading stays on this device"). Do not publish the privacy note until the final dependency list has been reviewed.

### 5.8 Empty states

All three share one `EmptyState` component: a 72 dp soft `accentSoft` circle with an outline icon, a title in Literata, one short sentence, one quiet button. No guilt, no exclamation marks.

| Screen | Icon | Title | Sentence | Button |
| --- | --- | --- | --- | --- |
| Favourites | Heart outline | No favourites yet | Tap the heart on any verse to keep it here. | Open the Gita |
| Bookmarks | Bookmark outline | Nothing bookmarked | Bookmark a verse to find your place again. | Open the Gita |
| History | Clock outline | No reading history | Verses you read will appear here. | Read today's verse |

"Open the Gita" goes to the reader at the last position. "Read today's verse" goes to Home.

### 5.9 Save toggles (Favourite and Bookmark)

- Two separate toggles with distinct icons (heart, bookmark), both 48 x 48 touch targets, both with semantic labels ("Add to favourites" / "Remove from favourites", same for bookmarks).
- State changes instantly (optimistic), then persists; if persistence fails, revert and show a short snackbar.
- Animation: icon cross-fades from outline to filled with a 1.0 to 1.15 to 1.0 scale over 200 ms, plus a `lightImpact` haptic. No confetti, no bounce.
- The same verse shows the same state on Home, reader, purport page and library, driven by one provider.

## 6. Motion, accessibility, performance and privacy

### Motion

| Moment | Motion | Duration |
| --- | --- | --- |
| Verse swipe | Fade 60% to 100% plus 12 px slide | 240 ms |
| Language switch | Cross-fade of translation only | 160 ms |
| Chapter and verse sheets | Slide up, ease-out; scrim fade | 360 ms |
| Nav pill droplet | Spring settle after tap or drag | about 380 ms |
| Nav pill hide and show on scroll | Slide 24 px and fade | 200 ms |
| Favourite and bookmark | Icon cross-fade with 1.15 scale pulse | 200 ms |
| Purport page open | Slide up 16 px plus fade | 240 ms |
| Theme change | Colour cross-fade | 240 ms |
| Home entrance | Staggered fade and 8 px rise | 60 ms stagger |

- **Reduced motion:** when the system asks for it (`MediaQuery.disableAnimations`), replace slides and springs with 120-160 ms fades, keep the nav pill visible, and skip entrance staggers. Wrap this in one helper, `Motion.of(context)`, and use it everywhere.
- No bounce except the nav droplet spring. No animation may delay reading: input is accepted while any transition runs.
- Use Flutter's built-in animation widgets (`AnimatedSwitcher`, `AnimatedOpacity`, `PageView` transforms, spring simulation for the droplet). Add no animation package.

### Accessibility

- Screen readers (TalkBack and VoiceOver): every control has a label; the reader page announces "Chapter 2, verse 47, page 12 of 72" when it changes; Sanskrit is marked with locale `sa` or `hi` where the platform supports it; decorative lines and glass layers are excluded.
- Contrast: 4.5:1 for text, 3:1 for icons and large text, checked by an automated test over all token pairs in both themes.
- Touch targets at least 48 x 48 dp; the nav pill tabs at least 56 wide.
- Text scale: layouts must hold at system text scale 2.0 without overflow (nav pill labels clamp to 1.3).
- Never rely on colour alone: selected tab also uses a filled icon; saved verses use filled icons.
- Focus order and keyboard or switch access: pills, selectors and toggles are focusable with a visible ring.

### Performance targets (mid-range Android, release build)

- Cold start to first readable verse under 2 s; no jank (frames under 16 ms for 60 Hz) while swiping between entries.
- JSON parsing off the UI thread; one chapter in memory plus neighbours, not the whole Gita.
- Glass: if frame time exceeds budget for 30 consecutive frames, switch to the frosted fallback for the session.
- App size: record the bundle size at Stage 1 and again at release. Fonts: ship only needed weights and consider subsetting; do not ship unused font files.
- Run Flutter DevTools performance overlay on a low-end Android device at Stage 7 and record results in `docs/perf.md`.

### Privacy and platform

- No accounts, analytics, ads, crash-reporting SDKs or network calls. The Android release manifest should not request `INTERNET` (the debug manifest will for hot reload); verify this in the built APK.
- No notification permission requests, and no notification infrastructure.
- On iOS, add no tracking keys; fill the App Store privacy answers only after reviewing the final dependency list.
- Backups: decide whether Android auto-backup and iCloud device backup may include the local database. Default: allow the platform's normal device backup (this is not app-run cloud sync), and describe it honestly on the Credits screen only if you keep it on. Listed as an open question.
- Store listing and legal: the attribution wording and permission terms you hold must appear in About and in the store description where required.

## 7. Testing plan and risks

### Testing plan

Tests are written with each stage, not at the end. A stage is not done until its tests pass.

| Level | What to cover |
| --- | --- |
| Unit | Daily verse (same date same entry, consecutive days differ, full cycle covers all entries, DST and leap day); verse navigation and chapter boundaries including ranges; favourite and bookmark add, remove, persist; history cap, dedupe and ordering; theme, language and text-size persistence with invalid stored values; scripture validator (a passing fixture and one failing fixture per check); purport markup parser; orphan ID purge; drift migration |
| Widget | Home; chapter sheet; verse selector; reader (swipe, first and last entry, language switch keeps entry); purport page with a very long purport; favourites, bookmarks and history lists; Profile and settings; all three empty states; every screen in light and dark; text scale 1.0, 1.3 and 2.0 on a 360 x 640 screen; reduced motion; glass fallback path |
| Integration | First launch with no network, then read every chapter offline (swipe through all entries of one chapter, jump to the last entry of each chapter); switch English and Hindi; add and remove favourites and bookmarks; kill and restart and confirm state restored; open purport and return to the same entry; resume the last-read verse; clear history; reset all data returns to first launch |
| Golden (optional) | Home and reader screenshots in light and dark for regression of typography |
| Manual device pass | One low-end Android, one mid-range Android, one recent iPhone: Devanagari rendering, glass performance, gesture navigation back swipe, notch and safe areas, airplane mode |
| Content review | The character-by-character spot check from section 3, recorded in `docs/content-review.md` |

### Risks and mitigations

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Scripture text errors | Wrong text in a sacred book is the worst failure | Importer-only writes, checksums, validator, human spot-check, no AI-generated text ever |
| Verse ranges mishandled | Wrong counts, broken navigation, wrong daily verse | Entry model with `verseStart` and `verseEnd`; counts from the source; tests with ranges |
| Devanagari rendering | Broken conjuncts or clipped matras look careless | Bundled fonts, specimen screen in Stage 2, generous line height, test on real devices |
| `liquid_glass_renderer` is pre-release | API can change; may be slow on weak GPUs | Pin the exact version, isolate behind `GlassNavBar`, keep the frosted and solid fallbacks, frame-time guard |
| Glass hurting legibility or battery | Reading comes first | Glass only on floating controls, budget of 3 surfaces, no text on glass |
| Gesture conflicts | Swipe vs vertical scroll vs system back | Dead zones at edges, tests on gesture and 3-button navigation, diagonal flick tests |
| Asset size and startup | Large purports slow cold start | Per-chapter JSON, isolate parsing, lazy loading, measure at Stage 1 and 7 |
| Font licences | Shipping a font you may not redistribute | Use only OFL fonts, include licence files and list them on the Credits screen |
| Missing or misformatted purports | Not every entry has the same shape | Nullable purport, block-based format, validator reports; UI hides the action when absent |
| Hindi purports may not exist | Mixed-language experience | Default rule in section 3: show English with a quiet note |
| Store review | Apps with scripture and permissions can be questioned | Keep the permission paper handy; attribution on the Credits screen and in the listing |
| Platform differences | iOS and Android render and navigate differently | Use platform-adaptive transitions, test on both, no platform-only features in v1 |
| Data lost on uninstall | Users may expect favourites to survive | Say it plainly in Profile; consider an export in v1.1 |

## 8. Staged TODO list for Claude Code

Work one stage per session. Each stage ends with something runnable and passing tests; tick the boxes in `docs/PRD.md` as you go. Do not start a stage before the previous one's "Done when" is true.

### Stage 0: Project setup

- [ ] Create the Flutter project (Android and iOS only), set the package name and app name placeholder "Gita".
- [ ] Set portrait-only orientation; minimum Android 8.0 (API 26), iOS 15.
- [ ] Add packages from section 2 with `flutter pub add`; pin `liquid_glass_renderer` to an exact version.
- [ ] Create the folder structure from section 2; add `analysis_options.yaml` with strict lints.
- [ ] Add `CLAUDE.md` (rules in section 9), `docs/PRD.md`, `docs/content-review.md` stub.
- [ ] Set up CI: `flutter analyze`, `flutter test`, and `dart run tool/validate_scripture.dart`.
- [ ] Native splash (warm `bg`) and a placeholder app icon.
- [ ] Confirm release Android manifest has no `INTERNET` permission.

**Done when:** the app launches an empty screen on both platforms and CI is green.

### Stage 1: Scripture data and validator

- [ ] Ask the user for the authorised source files and their format; do not proceed with guesses.
- [ ] Write the models: `Chapter`, `VerseEntry` (with `verseStart`, `verseEnd`, `label`), `PurportBlock`.
- [ ] Create a small, clearly labelled placeholder dataset (3 chapters, includes one range entry, one entry with no purport, one long purport, real Devanagari strings) with `isPlaceholder: true`.
- [ ] Write `ScriptureRepository`: loads `chapters.json`, loads a chapter on demand in an isolate, caches the last 3 chapters, exposes lookups by ID, neighbours, and chapter entries.
- [ ] Write the purport inline-markup parser (`<i>`, `<b>`) into `TextSpan`s with tests.
- [ ] Write `tool/validate_scripture.dart` with every check in section 3, plus a fixture test for each failing case.
- [ ] Write `tool/expected_counts.json` from the source and get the user's approval.
- [ ] Write the importer for the real source into `assets/scripture/` and run it; produce checksums.
- [ ] Record asset size and startup time in `docs/perf.md`.

**Done when:** validator passes on the real data (or on the placeholder in dev), repository tests pass, nothing outside the importer wrote to `assets/scripture/`.

### Stage 2: Design system and typography

- [ ] Bundle fonts (Noto Serif Devanagari, Literata, Inter) with licence files; declare in `pubspec.yaml`.
- [ ] Implement tokens: colours (light and dark), type scale, spacing, radii, elevation, durations, curves, `GlassTokens`.
- [ ] Build `ThemeData` for both themes with `ColorScheme` and text themes from tokens.
- [ ] Build shared components from the section 4 list (without glass): `ShlokaView`, `TransliterationView`, `TranslationView`, `ReferenceChip`, `SectionHeader`, `EmptyState`, `SettingsRow`, `SegmentedChoice`, `ConfirmDialog`, `AppBottomSheet`.
- [ ] Build the debug-only specimen screen and test every item in the typography test set; compare Noto Serif Devanagari vs Tiro Devanagari Sanskrit and record the choice.
- [ ] Contrast test over all token pairs in both themes.
- [ ] `Motion.of(context)` helper for reduced motion.

**Done when:** specimen screen renders correctly on a real Android and iPhone in both themes, at text scale 1.0 and 2.0, with no overflow; contrast test passes.

### Stage 3: App shell, navigation and Liquid Glass bar

- [ ] Implement `go_router` with `StatefulShellRoute` and the routes in section 5.0 (screens are simple placeholders).
- [ ] Implement `GlassNavBar` using `liquid_glass_renderer`: floating pill, droplet selection, drag to switch, haptic, spring settle.
- [ ] Implement fallbacks: frosted (`BackdropFilter`), solid (high contrast or Simplified glass), and the frame-time guard.
- [ ] Scroll-hide behaviour with a `NavBarVisibility` provider; bottom inset helper for scrollables.
- [ ] `GlassPill` and `GlassIconButton` (light glass) for later screens.
- [ ] Widget tests: tab switching, state kept per tab, fallback selection, reduced motion keeps bar visible.
- [ ] Tune `GlassTokens` on a real iPhone and a mid-range Android over both a light and a dark colourful background.

**Done when:** the pill looks right and stays smooth over scrolling content on both phones; fallbacks switch correctly.

### Stage 4: User data and settings

- [ ] Drift database: `favourites`, `bookmarks`, `history`; DAOs; schemaVersion 1 with a migration test harness.
- [ ] `SettingsRepository` with validation and defaults for language, theme, text size, `lastVerseId`, `firstLaunchDone`.
- [ ] Providers: `savedStateProvider(verseId)` (favourite, bookmark), counts, history list, settings notifiers.
- [ ] History rule: add after 2 s visible, dedupe, cap 200.
- [ ] Orphan purge at startup.
- [ ] Unit tests for every item above, including invalid stored preferences.
- [ ] Apply theme mode and text size app-wide through providers.

**Done when:** all unit tests pass, and a restart restores settings and saved items in a quick manual test.

### Stage 5: Gita reader

- [ ] `verse_navigation.dart` pure logic (previous, next, chapter edges, ranges) with tests.
- [ ] Reader `PageView` per chapter with the page transition and preloading.
- [ ] Floating top row: chapter pill, verse pill, language toggle, progress line.
- [ ] Chapter bottom sheet (5.4) and verse selector sheet (5.5).
- [ ] Inline action row with `SaveToggleButton`s and Purport button (hidden when no purport).
- [ ] Position persistence (debounced) and resume; deep link `?verse=` jump.
- [ ] Edge behaviours, "Continue to Chapter N" and the Chapter 18 ending.
- [ ] Language switch cross-fade that keeps entry and scroll.
- [ ] Android edge dead zones; test diagonal flicks.
- [ ] Widget and integration tests: swipe through a chapter offline, jump via selector, boundaries, language switch keeps position.

**Done when:** you can read every placeholder or real chapter end to end by swiping, switch chapters, jump to any entry, and resume after a restart.

### Stage 6: Home and daily verse

- [ ] `daily_verse.dart` with mulberry32 PRNG and the permutation rule; all unit tests from section 2.
- [ ] Home screen per 5.2 including actions, continue row, language toggle, entrance motion.
- [ ] Refresh the verse on app resume and at local midnight.
- [ ] First-launch screen per 5.1 and the redirect logic.
- [ ] Widget tests: Home in light and dark, long verse, no purport, day change.

**Done when:** Home shows the same verse all day across restarts and a different one the next day (test by changing the device date).

### Stage 7: Purport page

- [ ] `PurportView` with block types and inline markup.
- [ ] Page per 5.6: glass back and action pill, text-size popover, progress line, lazy slivers.
- [ ] Transition and reduced-motion variant; scroll offset restored in-session.
- [ ] Hindi selected with English-only purport note; no-purport fallback page.
- [ ] Tests with a 4,000-word placeholder purport: no overflow, smooth scroll, back returns to the same entry.

**Done when:** a very long purport reads comfortably at all 5 text sizes in both themes.

### Stage 8: Profile and library

- [ ] Profile page per 5.7 with live counts and the continue row.
- [ ] Favourites, Bookmarks, History lists with `VerseListTile`, swipe to remove plus undo, history clear.
- [ ] Preferences: translation, theme, text size slider, Simplified glass.
- [ ] Data management dialogs: clear history, reset all data; return to first launch after reset.
- [ ] About, Credits and Sources screen with the exact attribution text and font licences.
- [ ] Empty states per 5.8.
- [ ] Optional polish: dots on the verse selector for saved entries.
- [ ] Widget tests for every screen above, plus integration tests for save, remove, restart and reset.

**Done when:** every item in the Profile spec works and survives a restart.

### Stage 9: Polish, accessibility and performance

- [ ] Review every transition against the motion table; verify reduced motion everywhere.
- [ ] Add semantics: labels, reader page announcements, locale tags for Devanagari, exclusion of decoration.
- [ ] Text scale 2.0 pass on a 360 x 640 screen for every screen; fix overflow.
- [ ] Performance run on a low-end Android; fix jank; record in `docs/perf.md`.
- [ ] Final glass tuning; confirm the 3-surface budget.
- [ ] Dark theme review screen by screen (not an inversion): check warm accents and glow.

**Done when:** accessibility and performance targets in section 6 are met.

### Stage 10: Release preparation

- [ ] Replace placeholder data with the real dataset; validator passes with no placeholders.
- [ ] Complete the character-by-character content review and sign off in `docs/content-review.md`.
- [ ] Review the final dependency list (`flutter pub deps`); verify no network permission, no analytics, no ads.
- [ ] Finalise attribution wording on the About screen and in store listings.
- [ ] App name, icon, splash, store screenshots (light and dark) and descriptions.
- [ ] Full manual device pass (section 7) and full integration run in airplane mode.
- [ ] Build signed Android App Bundle and iOS archive; test the release builds, not debug builds.

**Done when:** release builds pass the full checklist and you approve them.

## 9. Claude Code kickoff and open questions

### CLAUDE.md rules (copy into the repo root)

```markdown
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
- Offline-first. No network calls, no accounts, no analytics, no ads, no notifications, no in-app purchases, no cloud sync.
- Fonts are bundled assets. Do not use runtime font downloads.
- Out of scope: AI features, chat, social, streaks, search, sharing (until approved).

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
```

### Kickoff prompts

**Stage 0** (paste into Claude Code in an empty folder, after copying this doc to `docs/PRD.md`):

```text
Read docs/PRD.md in full. Create CLAUDE.md using the rules block in section 9. Then do Stage 0 only from section 8. Do not start Stage 1. When finished: tick the completed boxes in docs/PRD.md, list what you did, tell me how to run the app, report analyze and test results, and stop.
```

**Every later stage** (change the number):

```text
Read CLAUDE.md and docs/PRD.md. Do Stage N only from section 8, following the screen specs in section 5 and the design system in section 4. Write the tests listed for this stage. Ask me before making any decision the PRD does not cover. When finished: tick the boxes, report analyze and test results, tell me how to see the result on a device, and stop.
```

**Stage 1 extra line** (you must supply the source files first): "My authorised source files are in `source/` and are in \<format>. Look at them and tell me how they map to the JSON schema in section 3 before writing the importer."

### Open questions (only the ones I could not safely default)

| # | Question | My default if you do not answer |
| --- | --- | --- |
| 1 | In what format is the authorised source (PDF, EPUB, database, JSON, spreadsheet), and does it include the Hindi translation, any Hindi purports, Hindi chapter titles and the word-for-word synonyms? | Stage 1 stops and asks when it sees the files |
| 2 | What is the exact attribution wording and any conditions in your permission (placement, credit lines, logos, redistribution limits)? | A placeholder block on the About screen marked "needs your wording" that fails the release check |
| 3 | App name, bundle ID or package name, and developer name for the store listing? | "Gita" and a placeholder ID |
| 4 | Should word-for-word synonyms (if the source has them) appear on the purport page in v1? | Stored but not shown in v1 |
| 5 | Should Android and iOS device backup be allowed to include the local database? | Allowed; the Credits screen states honestly what backs up |
| 6 | Are Android 8.0 and iOS 15 acceptable minimum versions for your audience? | Yes |
| 7 | Would you like visual mockups of Home, the reader, the purport page and Profile (light and dark) before Stage 2 so you can approve the look? | Skip; build directly and tune on device |

Once you answer 1 and 2, Stage 1 and Stage 10 are unblocked. Stages 0, 2 to 9 can start immediately with placeholder data.
