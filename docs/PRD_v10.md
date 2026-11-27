# Gita App: v10 PRD (Apple Watch companion)

Nov 25, 2026 · owner: @Devang · status: **built on the owner's request (Task 5); watch device testing pending**

Extends all earlier PRDs. Where it contradicts them, **this file wins**.
Scripture-text rules in `CLAUDE.md` still apply in full: the watch shows the
dataset's text exactly; nothing is generated, shortened or changed.

## 1. Overrides

| Earlier rule | v10 now |
| --- | --- |
| iOS app is Flutter only, plus the widget extension | A **native SwiftUI watchOS app** (`ios/GitaWatch`) and its **complication extension** (`ios/GitaWatchWidgets`) ship inside the iOS app. No Flutter on the watch. |
| Only the importer writes scripture files | `tool/build_watch_scripture.dart` writes the watch's copy, `ios/GitaWatch/Shared/gita_watch.json`, from `assets/scripture/`. It copies fields exactly and never writes to `assets/scripture/`. |
| The app's own code talks to no device but the phone | The iPhone app talks to the **paired Apple Watch** through Apple's WatchConnectivity. This is not a network call: no server, no internet, no analytics. |

## 2. What the watch does

Home list (title "Gita"):

1. **Today**: the verse of the day, the same verse the iPhone shows that day.
2. **Random Verse**, with an "Another Verse" button.
3. **Continue Reading**: opens the verse the iPhone reader last stopped at
   (its `lastVerseId`). Shows "Read on your iPhone first" until one arrives.
4. **Bookmarks**: the iPhone's bookmarks, newest first; tap to read.
5. **Now Playing**: the system Now Playing controls (section 5).
6. Footer: the dataset's attribution line, as in the app's About.

A verse screen shows the reference ("Chapter 2 · Verse 47"), the Sanskrit,
the transliteration and the translation in the iPhone's reading language
(Hindi when chosen and present, otherwise English, the app's own rule).
Purports and word meanings stay on the iPhone. Read with the Digital Crown.

## 3. Text on the watch

- The watch ships its own copy of the fields it shows (about 0.8 MB, 657
  entries), so it reads offline, without the phone, and the phone never
  sends scripture. Entry order is the app's order.
- `test/data/watch_scripture_test.dart` fails if the copy is out of date or
  differs from the app's text in any field. After a new import, run
  `dart run tool/build_watch_scripture.dart`.
- The generator refuses placeholder data, and a release watch build stops
  at launch if the file is marked `isPlaceholder`.

## 4. Sync

- The iPhone is the **only** store of bookmarks and the reading position.
  The watch keeps a read-only mirror of the IDs. One database, no merging.
- What crosses: `{v: 1, lang, lastVerseId, bookmarks: [ids]}` (bookmarks
  capped at 500). Flutter sends it on any change
  (`lib/application/watch_sync.dart`); `ios/Runner/WatchSync.swift` stores it
  and sends it as WatchConnectivity's **application context** (latest state
  only; the system delivers it when the watch can take it).
- When the watch app opens and the phone is reachable, it asks for the
  latest state; the phone answers natively, even before Flutter starts.
- The watch caches the last state, so with the iPhone away everything still
  opens; bookmarks and Continue Reading are as of the last sync.
- Bookmarking and reading position are not changed from the watch (v10
  scope). Reading on the watch does not move the iPhone's reading place.

## 5. Audio

- No audio engine on the watch. Shravan playback runs on the iPhone
  (just_audio + audio_service), which publishes the system Now Playing
  session; the watch's **Now Playing** screen (WatchKit `NowPlayingView`)
  and the system's own Now Playing app control it.
- Independent watch playback was considered and not built: it would need a
  second engine, audio downloads to the watch over its own network, and the
  Shravan entitlement checked on the watch, which has no store receipt of
  the iPhone purchase. Revisit only with an owner spec.

## 6. Complications

- One WidgetKit complication, "Verse of the Day", in the circular,
  rectangular, inline and corner families. It shows the reference (e.g.
  "Gītā 2.47"); rectangular adds the start of the translation.
- The timeline holds seven daily entries starting at local midnight and
  reloads when it runs out (`.atEnd`); the watch app reloads it only when
  the language changes. No background refresh is needed, so it stays inside
  Apple's budget.
- Tapping it opens today's verse in the watch app.

## 7. Platform

- watchOS 10.0 or later. Bundle IDs `com.onescrollgita.app.watchkitapp` and
  `com.onescrollgita.app.watchkitapp.widgets`, team 5MU65B6U3F, automatic
  signing, App Group `group.com.onescrollgita.app` on both.
- Version and build number follow the iOS app (`FLUTTER_BUILD_NAME` /
  `FLUTTER_BUILD_NUMBER`).
- Android is unchanged; the Dart sync is a no-op off iOS.

## 8. Stages

- [x] V10-1 Watch app, complication, sync, tests (2026-11-25)
- [ ] V10-2 Owner device test on a paired Apple Watch (`docs/review-needed.md`)
