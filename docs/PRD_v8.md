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

## 3. Not in scope

- Android (Google Assistant / Gemini cannot speak an app's answer back the
  same way). Revisit later.
- "Continue reading" or random-verse voice commands (easy follow-ups with
  the same approach).

## 4. TODO

- [x] App Intent and phrases (`ios/Runner/AppDelegate.swift`).
- [ ] Owner check on the iPhone: say each phrase; check English and Hindi.
