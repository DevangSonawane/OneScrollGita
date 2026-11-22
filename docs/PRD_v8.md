# Gita App: v8 PRD (Siri: verse of the day)

Nov 20, 2026 · owner: @Devang · status: **built on the owner's request**

Extends all earlier PRDs. Scripture-text rules in `CLAUDE.md` still apply in
full: Siri speaks the dataset's translation exactly; nothing is generated.

## 1. What it does

The user says, for example, **"Hey Siri, verse of the day in One Scroll
Gita"**. Siri answers with today's verse, read aloud and shown on screen:
"Bhagavad-gītā 2.47. You have a right to perform your prescribed duty…".
The app does not need to open.

Phrases (Apple requires the app's name in each):
- "Verse of the day in One Scroll Gita"
- "One Scroll Gita verse of the day"
- "Today's verse in One Scroll Gita"
- "What is today's verse in One Scroll Gita"
- "Read me today's verse in One Scroll Gita"

They work as soon as the app is installed (App Shortcuts); users can add
their own shorter phrase in the Shortcuts app.

## 2. How

- iOS **App Intents** (iOS 16+), in the Runner target. Free: part of the iOS
  SDK, runs on the phone, no network, no Apple Intelligence needed, no
  extra entitlement.
- The verse comes from the App Group data the home-screen widgets already
  use (`daily_verses`: the next 30 days, written by the app). So Siri works
  even if the app has not been opened today. Same day rule as the widget:
  the latest stored day that is not in the future.
- Language: the translation in the reading language the user chose (the
  app already stores it that way). Sanskrit is not read aloud (Siri voices
  pronounce it poorly).
- No data yet (app never opened): Siri says "Open One Scroll Gita once to
  load today's verse."

## 2b. Home Screen Quick Actions (owner, 2026-11-22)

Long-press the app icon on iOS: **Continue Reading** (SF Symbol `book`),
**Today's Verse** (`sun.max`), **Random Verse** (`shuffle`), **Bookmarks**
(`bookmark`). Static `UIApplicationShortcutItems` in `ios/Runner/Info.plist`
with stable types `com.onescrollgita.app.quick.*`
(`lib/domain/quick_action.dart`).

- Native side: `QuickActionsPlugin` in `ios/Runner/AppDelegate.swift`
  receives the shortcut through Flutter's scene life cycle (launch from
  terminated) and `windowScene(_:performActionFor:)` (background or
  active), and passes the type over the method channel
  `com.onescrollgita.app/quick_actions`. A launch shortcut is held until
  Flutter asks for it once.
- Flutter side: `lib/application/quick_actions.dart` maps each action to an
  existing route: the persisted `lastVerseId` (or 1.1 when nothing was
  read), the daily-verse provider, a random entry of the bundled dataset,
  and `/profile/bookmarks` (its own empty state when there are none).
  During first launch, shortcuts are ignored (the welcome flow owns the
  screen).
- Android unchanged.

## 2c. Control Center controls (iOS 18+, owner, 2026-11-22)

Four controls users can add to Control Center: **Today's Verse**
(`sun.max`), **Random Verse** (`shuffle`), **Continue Reading** (`book`),
**Bookmarks** (`bookmark`). Built with `ControlWidget` +
`ControlWidgetButton` and App Intents in the existing **VerseWidgets**
widget extension (`ios/VerseWidgets/VerseWidgets.swift`), behind
`if #available(iOS 18.0, *)`, so the deployment target stays iOS 15 and
older iOS versions keep the widgets only.

- Each control runs an App Intent with `openAppWhenRun = true`, defined
  in **both** the extension and the app target (Apple's requirement for
  controls that open their app). iOS opens or launches the app and runs
  the app's copy, which passes the quick action type to
  `QuickActionsPlugin.request` → the Flutter handler used by the Home
  Screen Quick Actions (one implementation of the destinations; the
  controls need no shared data). A request on a cold launch is held until
  Flutter asks for it.
- First attempt (`OpenURLIntent` with the custom `gitaapp://` scheme) did
  nothing on the owner's iPhone; replaced. The `/quick` route stays as a
  harmless link entry point.
- Control kinds: `com.onescrollgita.app.control.{todays-verse,
  random-verse,continue-reading,bookmarks}`.
- No new target, entitlement or App Group change (the extension already
  exists and is signed with the app's team).

## 3. Not in scope

- Android (Google Assistant / Gemini cannot speak an app's answer back the
  same way). Revisit later.
- "Continue reading" or random-verse voice commands (easy follow-ups with
  the same approach).

## 4. TODO

- [x] App Intent and phrases (`ios/Runner/AppDelegate.swift`).
- [ ] Owner check on the iPhone: say each phrase; check English and Hindi.
- [x] Quick actions: Info.plist items, native plugin, Flutter handler,
      tests (`test/widget/quick_actions_test.dart`).
- [x] Owner check of all four quick actions on the iPhone (2026-11-22).
- [x] Control Center controls in the widget extension; `/quick` route;
      tests for the link path.
- [x] Owner check: controls work on the owner's iPhone (2026-11-22).
