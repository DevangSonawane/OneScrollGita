import AppIntents
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Local reminders show while the app is open too.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - Siri: verse of the day (docs/PRD_v8.md)
//
// "Hey Siri, verse of the day in One Scroll Gita". Siri reads today's
// verse from the App Group data the home-screen widgets already use
// (written by the app for the next 30 days), so it works offline and
// without opening the app. The text is the dataset's translation, as is.


/// Today's verse from the shared widget data (same rule as the widget: the
/// latest stored day that is not in the future).
private enum DailyVerseStore {
  struct Verse: Decodable {
    let id: String
    let label: String
    let text: String
    let date: String?
  }

  static func today() -> Verse? {
    guard
      let raw = UserDefaults(suiteName: "group.com.onescrollgita.app")?
        .string(forKey: "daily_verses"),
      let data = raw.data(using: .utf8),
      let items = try? JSONDecoder().decode([Verse].self, from: data)
    else { return nil }
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = .current
    f.dateFormat = "yyyy-MM-dd"
    let key = f.string(from: Date())
    return items.last { ($0.date ?? "") <= key }
  }
}

@available(iOS 16.0, *)
struct VerseOfTheDayIntent: AppIntent {
  static var title: LocalizedStringResource = "Verse of the day"
  static var description = IntentDescription(
    "Hear today's verse from the Bhagavad-gītā."
  )
  static var openAppWhenRun: Bool = false

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let verse = DailyVerseStore.today() else {
      return .result(dialog: "Open One Scroll Gita once to load today's verse.")
    }
    return .result(dialog: "Bhagavad-gītā \(verse.label). \(verse.text)")
  }
}

@available(iOS 16.0, *)
struct GitaAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: VerseOfTheDayIntent(),
      phrases: [
        "Verse of the day in \(.applicationName)",
        "\(.applicationName) verse of the day",
        "Today's verse in \(.applicationName)",
        "What is today's verse in \(.applicationName)",
        "Read me today's verse in \(.applicationName)",
      ]
    )
  }
}
