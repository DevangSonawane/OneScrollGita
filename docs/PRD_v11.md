# Gita App: v11 PRD (Listen widgets and controls)

Nov 27, 2026 · owner: @Devang · status: **built (owner request, 2026-11-27); Android not yet run on a device**

Extends all earlier PRDs. Where it contradicts them, **this file wins**.
Scripture-text rules in `CLAUDE.md` still apply in full. No new network use.

## 1. Owner decisions (2026-11-27)

- "I want the Listen widget everywhere": Home Screen, Lock Screen, quick
  controls, wherever the app already has widgets or controls.
- Tapping a Listen widget or control **opens the app and plays**, but only
  with **Shravan**. Without it the tap opens the Shravan paywall over the
  Listen tab and nothing plays (no loophole). The check is the app's own
  `canListen` in `domain/shravan.dart`; the widgets never decide access.
- Platforms: **iPhone and Android**.
- The Listen page has no download buttons (owner, 2026-11-27).

## 2. What already covers "controls while playing"

No new work: while audio plays, `just_audio_background` gives the system
media controls on the iPhone Lock Screen, Control Center, Dynamic Island and
the paired Apple Watch's Now Playing, and the Android media notification and
lock screen. Shortcuts / Action Button already have "Start Listening".

## 3. New pieces

All of them open `gitaapp://open/quick?type=com.onescrollgita.app.quick.start-listening`
(or run the existing `StartListeningIntent`), so there is one implementation
of what happens next (`quickActionRoute` in `application/quick_actions.dart`):

| With Shravan | Without Shravan |
| --- | --- |
| Listen tab, then the player, resuming the last place (or chapter 1) | Listen tab, then the Shravan paywall (`/shravan?reason=recitation`). Nothing plays. |

### iPhone (widget extension `ios/VerseWidgets`)

- **Listen widget** (`ListenWidget`), Home Screen small and medium: the
  chapter's cover (owner artwork), the chapter name in the reading language
  (English or Hindi, from the dataset), "Chapter 2 · 2.47" (Hindi: "अध्याय २ · 2.47"),
  and a play button. Medium adds the "Shravan" heading.
- **Lock Screen** (iOS 16+): circular (headphones + chapter number),
  rectangular (heading, chapter name, verse), inline (one line).
- **Control Center** (iOS 18+): **Listen** control (`headphones`) running
  `StartListeningIntent`, copied into the extension as the other controls are.
- Covers: 400 px copies in `ios/VerseWidgets/ListenCovers.xcassets`, made by
  `tool/build_chapter_art.sh`.

### Android

- **Listen widget** (`ListenWidget`, home screen and keyguard where the
  launcher allows): same content as the iPhone medium widget. Covers in
  `res/drawable-nodpi/listen_cover_NN.jpg`, made by the same script.
- **Quick Settings tile** "Listen" (Android 7+, `ListenTileService`): opens
  the same link.

### Shared data

The app writes one App Group / SharedPreferences key, `listen_state`:
`{chapter, title, label, lang}`: the last place listened to (or chapter 1),
the title in the reading language, the verse label, and the reading language
(for "Chapter 2" / "अध्याय २"). No access or purchase
data is written for the widgets. Updated when the place or the language
changes.

## 4. Stages

- [x] V11-1 Spec (this file), CLAUDE.md note.
- [x] V11-2 Flutter: `listen_state` sync; Start Listening without Shravan
      opens the paywall; tests.
- [x] V11-3 iPhone: Listen widget, Lock Screen, Control Center control, covers.
- [x] V11-4 Android: Listen widget, Quick Settings tile, covers.
- [x] V11-5 flutter analyze, flutter test, iOS release build installed on
      the owner's iPhone; Android debug APK builds.
- [ ] V11-6 Owner checks the widgets on device (iPhone and Android).
