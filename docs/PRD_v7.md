# Gita App: v7 PRD (One English font, new Home, Go to verse)

Nov 20, 2026 · owner: @Devang · status: **built on the owner's request; owner review on device pending**

Extends all earlier PRDs. Where it contradicts them, **this file wins**.
Scripture-text rules in `CLAUDE.md` still apply in full.

## 1. Overrides

| Earlier rule | v7 now |
| --- | --- |
| English reading text in Literata (serif) (v1) | **All English text in Inter**, reading and UI alike (the face of the settings and Shravan pages). Devanagari keeps its own faces. Inter covers every IAST letter in the dataset (checked). English reading sizes one step down (translation 17, transliteration 16, purport 16, word meanings 15), because Inter reads larger. Widgets use the system sans. |
| Nav pill shows icons only (v1) | Each tab shows its **name under the icon** (Home, Gita, Profile, Listen). Pill height 58. |
| Reader top bar has a "More" menu (v1) | **Removed** (owner). Chapter summary keeps its own button; search is on Home. |
| Separate chapter sheet and verse selector (v1 sections 5.4, 5.5) | One **"Go to verse"** sheet (section 3). |
| Home: today's verse, then a Continue button (v5) | New Home (section 2). |

## 2. Home

Top to bottom: date, language toggle and search; a time-of-day greeting
with a small "Day N" streak chip (hidden when there is no streak); the
**Continue reading** card (chapter name, a progress bar of verses read in
that chapter, "N of M verses", "You are at 2.24"; tap to continue; hidden
until something has been read); **Today's verse** as a card (shloka and
translation, favourite, bookmark, Purport, Read in Gita; the full verse with
transliteration is in the reader); "How are you feeling?"; the pinned
"Continue at 2.24" button.

Not built (owner, 2026-11-20): the "Your journey" chapter circles.

"Verses read" = every verse that counted as read for the streak, plus
reading history (`readVerseIdsProvider`). Kept by "Clear history", like
the streak.

## 3. Go to verse

Opened from both the chapter and the verse pill. A reference box ("2.47",
"18 66", "BG 2:47"; a reference outside the chapter explains itself), a
row of chapter tiles (Devanagari and Latin number, title, reading progress;
the current chapter selected), and the chosen chapter's verses: read verses
tinted, the current one outlined, favourites marked with a heart, with a
legend. Summary link per chapter.

## 4. Fixes in this round

- iOS back swipe on Profile detail pages (Bookmarks, Favourites, History,
  Notes, Highlights, Reminders, About): they used go_router's
  no-transition page; now the native page on each platform.

## 4b. Owner feedback, 2026-11-20 (built)

- **Long verses no longer skip on a fast flick.** The page swiper no longer
  takes the finger at all; only the verse scrolls. A page turns only from
  a swipe that starts at the verse's top or bottom (40 px pull, or a quick
  flick of at least 8 px at 700 px/s). Momentum never turns a page. Short
  verses still turn on one quick swipe.
- Go to verse shows **one number format**, in the reading language:
  "Chapter 2" and Latin verse numbers in English, "अध्याय २" and Devanagari
  verse numbers in Hindi.
- The separate **verse pill under the chapter pill is removed**. The top
  bar is one row: "2.47 · Contents of the Gita" (opens Go to verse), the
  summary button and the language toggle.
- Temporary on-device logs (swipe and notification) removed.
- **Whole-screen swipes, native page feel** (owner, 2026-11-20): the verse's
  swipe area fills the page (it had shrunk to the text after the "more
  below" fade was added). A swipe past a verse's edge now drags the pages
  with the finger and the pager's own physics settle it: past half the
  screen, or a quick flick, goes on; otherwise it springs back. Fast
  flicks inside a long verse still only scroll the verse.
- **One swipe to the next verse** (owner, 2026-11-20): a finger drag that
  reaches a verse's end carries straight on and moves the pages with it
  (no second swipe needed). Momentum from a flick is never a drag, so a
  flick still can't turn the page.
- **Short verses are centred** vertically; long ones start at the top.

## 4c. Reader rebuilt on one scroll (owner, 2026-11-20: "the selling feature")

The page swiper with a scroll inside each verse is gone; the hand-off
between the two made swipes feel laggy and inconsistent. Now each chapter
is **one scroll**, verse after verse (`CustomScrollView` anchored at the
opened verse so any verse opens instantly), with `VerseSnapPhysics`
(`features/gita/verse_snap_physics.dart`):

- Every verse is at least one screen tall; short verses are centred and
  behave as pages: one swipe, one verse; a short slow drag springs back.
- Inside a long verse, a fling scrolls freely but stops at the verse's end
  (or start); it never skips into the next verse.
- At a verse's end, one more swipe goes to the next verse's top; at its
  start, back to the previous verse. A slow drag more than halfway into the
  next verse settles there.
- The finger always moves the text directly: no hand-off, nothing to
  glitch. Removed: the page fade, the "more below" fade, edge-drag code.

### 4d. Swipe fixes after device testing (2026-11-20)

- Snapping skipped measuring during a frame, so on the phone it never ran
  and swipes flowed freely. Now only the one debug-only layout case is
  skipped.
- A snap could be re-decided mid-flight when the next verse laid out,
  landing 2-3 verses ahead. Each swipe now locks its target verse until
  the next touch (cleared by jumps).
- Swipes must be deliberate: at least 550 px/s and 24 px of movement;
  smaller touches spring back.

## 5. TODO

- [x] Inter for English text; widgets sans.
- [x] Nav labels; More menu removed.
- [x] Profile detail pages swipe back (tests for five pages).
- [x] Home redesign with Continue reading card (tests).
- [x] Go to verse sheet (tests: tile, grid, reference box, bad reference;
      text scale 2.0).
- [ ] Owner review on device.
- [ ] Tests for the rebuilt reader not run (owner asked not to test or
      install this round); test finders now point at the chapter scroll.
- [x] Long-verse flick skip (single scroller; tests for flicks, a new swipe
      from the bottom, and short verses).
