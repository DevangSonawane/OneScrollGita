# Gita App: v6 PRD (One-screen paywalls, native back swipe, lock screen widgets, working reminders)

Nov 20, 2026 · owner: @Devang · status: **draft, owner asked to build it now**

Extends all earlier PRDs. Where it contradicts them, **this file wins**.
Scripture-text rules in `CLAUDE.md` still apply in full.

---

## 1. Overrides

| Earlier rule | v6 now |
| --- | --- |
| Paywall hero is a breathing lotus over a mandala (v3) | Sadhak shows an animated **person reading**; Shravan an animated **person listening** (section 3). Drawn in code, no image files, no faces or likeness of a real person. |
| Paywall scrolls (v3) | The paywall fits **one screen without scrolling** on phones at normal text size (section 3). It still scrolls when it cannot fit (text size above 1.3x, very small phones), because layouts must survive text scale 2.0. |
| Pushed pages fade and rise (v1) | On iOS, pushed pages slide in and can be **swiped back from the left edge** like native apps (section 4). Android keeps its own system back gesture. |
| Home-screen widgets only (v2) | Lock screen widgets on iOS; Android where the system allows it (section 5). |
| First-launch reminder step is optional (v5) | The reminder step asks for notification permission straight away when the user taps "Remind me" (v5 already did this; v6 makes it the main button and keeps "Not now"). |

Still true: no tracking, no sensors, no analytics, no guilt, scripture never
paywalled. Device movement, battery or idle detection is **not** used
(owner decision, 2026-11-20).

---

## 2. Notifications that arrive (stage V6-1)

Found while reviewing v5:
- "Send a test notification" always asked for **exact** delivery. On
  Android 12+ without the exact-alarm permission the system refuses it, so
  the test silently failed. It now uses exact only when allowed.
- iOS: delivery is checked on the owner's iPhone with a diagnostic build;
  any cause found is fixed here and recorded in section 7.
- The Reminders screen shows a plain error line (not debug-only) when the
  system refuses to schedule, so failures are never silent.

## 3. One-screen paywalls (stage V6-3)

- Layout, top to bottom: illustration (takes whatever height is left, at
  least 96 dp), name (Devanagari + Latin), headline, one-line subline,
  four one-line benefits, the "always free" line, two compact plan cards,
  then the pinned button and terms.
- Benefit sub-lines are dropped from the paywall (titles only) to save
  height; nothing else is removed.
- **Sadhak illustration:** a seated figure holding an open book, softly
  breathing; pages turn now and then; a few light motes rise. Simple
  rounded shapes in the accent and gold colours, no face details.
- **Shravan illustration:** the same seated figure with headphones, eyes
  closed, gently swaying; sound waves ripple out from the headphones.
- Reduced motion: both are still drawings.
- The thank-you view after buying uses the same figure, still.

## 4. Swipe to go back (stage V6-2)

- iOS: every pushed page (purport, search, reminders, notes, journal,
  trainer, about, library lists, paywall, summaries) uses the native iOS
  page route, so a swipe from the left edge goes back with the page
  following the finger.
- Tabs and the reader itself are not pushed pages and do not change.

## 5. Lock screen widgets (stage V6-4)

- **iOS 16+:** "Verse of the day" adds the lock screen sizes: inline
  (reference, e.g. "Gītā 2.47"), rectangular (reference and the first
  words of the translation), circular (an om-style mark with the verse
  number). "Continue reading" adds rectangular and inline. Same data the
  home-screen widgets already use; tapping opens the verse.
- **Android:** phones have no general lock screen widget API. The existing
  widgets are marked as allowed on the lock screen (`keyguard` category),
  which works on Android versions and devices that support it (tablets and
  the Android 15+ hub). On phones, the "Verse of the day" notification
  remains the lock screen surface.

## 6. Settings tidy (stage V6-5)

- One "About and credits" row; the separate Credits block on Profile moves
  into the About page (shown once).
- Profile rows and section headers are more compact.

## 6b. Owner feedback, 2026-11-20 (built)

- The paywall figure is a **monk**: bald head, grey beard, tilak, closed
  eyes, saffron robe (owner: the first figure looked like it wore a
  headdress). Same monk on Sadhak (reading) and Shravan (listening).
- "Continue reading" widget starts at the **exact resume position** (the
  place the reader stopped), then recent history.
- The round lock screen widget shows a drawn **lotus** instead of Om.

## 8. Owner preview builds

`flutter build ios --release --dart-define=OWNER_PREVIEW=true` makes a
release build for the owner's own phone with the debug-only previews on:
Listen on the pretend engine, demo prices, and the "Pretend Shravan" and
"Pretend premium" switches. Profile shows a red "Owner preview build" row.
**Store builds never pass this flag** (the placeholder audio must never
ship, CLAUDE.md v4).

## 7. Staged TODO list

### V6-0: Spec
- [x] This file.

### V6-1: Notifications
- [x] Test notification uses exact only when allowed.
- [x] Visible error line on the Reminders screen.
- [x] First-launch reminder step: "Remind me" asks permission at once
      (already the main button since v5).
- [ ] iOS delivery confirmed on the owner's iPhone. Diagnostic lines
      (`NOTIFLOG`, marked `TEMP-NOTIF-LOG`) log permission and scheduling;
      remove before release.

### V6-2: Swipe to go back
- [x] iOS pushed pages use the native page route (`_risePage` in
      `app/router.dart`); shell sub-pages already used it via the theme.

### V6-3: One-screen paywalls
- [x] Layout fits one screen; scrolls only when it cannot fit. Checked in
      tests with the real bundled fonts at 390 x 844 and 375 x 667 (short
      screens under 740 dp drop the subline and Latin name and put the
      benefits in a 2 x 2 grid); text scale 2.0 scrolls without overflow.
- [x] Reading figure (Sadhak), listening figure (Shravan), still under
      reduced motion and on the thank-you view
      (`features/premium/figure_art.dart`).

### V6-4: Lock screen widgets
- [x] iOS accessory families (inline, rectangular, circular) on both
      widgets.
- [x] Android `keyguard` category on both widgets.

### V6-5: Settings tidy
- [x] Credits once (Profile footer block removed; About keeps the full
      source), compact rows (8 dp padding, 15 pt titles, 48 dp targets).

### Carried over
- [ ] Long-verse jump on the owner's iPhone (not reproducible in tests;
      diagnostic swipe log still in `reader_screen.dart`, marked
      `TEMP-SWIPE-LOG`, must be removed before release).
