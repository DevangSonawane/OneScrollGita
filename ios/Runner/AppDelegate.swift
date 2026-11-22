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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QuickActionsPlugin") {
      QuickActionsPlugin.register(with: registrar)
    }
    // Apple's own Liquid Glass controls on iOS 26+ (NativeGlass.swift).
    NativeGlass.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - Home Screen Quick Actions
//
// Long-press the app icon: Continue Reading, Today's Verse, Random Verse,
// Bookmarks. The items are declared in Info.plist
// (UIApplicationShortcutItems). This plugin only passes the chosen type to
// Flutter (lib/application/quick_actions.dart), which decides where to go
// with the app's existing data and router.

final class QuickActionsPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private static let typePrefix = "com.onescrollgita.app.quick."

  /// The registered plugin, once Flutter's engine is up.
  private static weak var shared: QuickActionsPlugin?
  /// An action requested before the plugin existed (Control Center intent
  /// on a cold launch).
  private static var earlyAction: String?

  /// Control Center controls (and anything else native) request an action.
  static func request(_ type: String) {
    if let plugin = shared {
      _ = plugin.deliver(type)
    } else if type.hasPrefix(typePrefix) {
      earlyAction = type
    }
  }

  private let channel: FlutterMethodChannel
  /// A shortcut that arrived before Flutter asked for it (cold launch).
  private var pending: String?
  /// Flutter has asked once, so later shortcuts can be sent straight away.
  private var flutterReady = false

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.onescrollgita.app/quick_actions",
      binaryMessenger: registrar.messenger()
    )
    let instance = QuickActionsPlugin(channel: channel)
    shared = instance
    if let early = earlyAction {
      instance.pending = early
      earlyAction = nil
    }
    registrar.addMethodCallDelegate(instance, channel: channel)
    // Scene life cycle (this app uses UIScene): launch and running cases.
    registrar.addSceneDelegate(instance)
    // Without scenes, the app delegate delivers the running case.
    registrar.addApplicationDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "takeInitialAction":
      flutterReady = true
      result(pending)
      pending = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func deliver(_ type: String) -> Bool {
    guard type.hasPrefix(Self.typePrefix) else { return false }
    if flutterReady {
      channel.invokeMethod("action", arguments: type)
    } else {
      pending = type
    }
    return true
  }

  // Launched from terminated by a quick action.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    if let item = connectionOptions?.shortcutItem {
      _ = deliver(item.type)
    }
    // Never claim the connection: Flutter and other plugins need it too.
    return false
  }

  // Chosen while the app is in the background or already active.
  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool {
    let handled = deliver(shortcutItem.type)
    if handled { completionHandler(true) }
    return handled
  }

  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool {
    let handled = deliver(shortcutItem.type)
    if handled { completionHandler(true) }
    return handled
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
  // Listed in the Shortcuts app and in Settings > Action Button > Shortcut.
  // Phrases must name the app and be unique across all shortcuts.
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: VerseOfTheDayIntent(),
      phrases: [
        "Verse of the day in \(.applicationName)",
        "\(.applicationName) verse of the day",
        "Today's verse in \(.applicationName)",
        "What is today's verse in \(.applicationName)",
        "Read me today's verse in \(.applicationName)",
      ],
      shortTitle: "Verse of the Day",
      systemImageName: "text.book.closed"
    )
    AppShortcut(
      intent: OpenTodaysVerseIntent(),
      phrases: ["Open today's verse in \(.applicationName)"],
      shortTitle: "Today's Verse",
      systemImageName: "sun.max"
    )
    AppShortcut(
      intent: OpenRandomVerseIntent(),
      phrases: [
        "Open a random verse in \(.applicationName)",
        "Random verse in \(.applicationName)",
      ],
      shortTitle: "Random Verse",
      systemImageName: "shuffle"
    )
    AppShortcut(
      intent: OpenContinueReadingIntent(),
      phrases: ["Continue reading in \(.applicationName)"],
      shortTitle: "Continue Reading",
      systemImageName: "book"
    )
    AppShortcut(
      intent: OpenBookmarksIntent(),
      phrases: ["Open my bookmarks in \(.applicationName)"],
      shortTitle: "Bookmarks",
      systemImageName: "bookmark"
    )
    AppShortcut(
      intent: StartListeningIntent(),
      phrases: ["Start listening in \(.applicationName)"],
      shortTitle: "Start Listening",
      systemImageName: "headphones"
    )
  }
}

// MARK: - Control Center controls: the app's copy of the intents
//
// Same names, titles and settings as in ios/VerseWidgets/VerseWidgets.swift.
// With openAppWhenRun, iOS opens (or launches) the app and runs this copy.

@available(iOS 16.0, *)
struct OpenTodaysVerseIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Today's Verse"
  static let description = IntentDescription("Open today's verse from the Bhagavad-gītā in One Scroll Gita.")
  static let openAppWhenRun = true
  @MainActor func perform() async throws -> some IntentResult {
    QuickActionsPlugin.request("com.onescrollgita.app.quick.todays-verse")
    return .result()
  }
}

@available(iOS 16.0, *)
struct OpenRandomVerseIntent: AppIntent {
  static let title: LocalizedStringResource = "Open a Random Verse"
  static let description = IntentDescription("Open a random verse from the Bhagavad-gītā in One Scroll Gita.")
  static let openAppWhenRun = true
  @MainActor func perform() async throws -> some IntentResult {
    QuickActionsPlugin.request("com.onescrollgita.app.quick.random-verse")
    return .result()
  }
}

@available(iOS 16.0, *)
struct OpenContinueReadingIntent: AppIntent {
  static let title: LocalizedStringResource = "Continue Reading"
  static let description = IntentDescription("Open the verse you read last in One Scroll Gita.")
  static let openAppWhenRun = true
  @MainActor func perform() async throws -> some IntentResult {
    QuickActionsPlugin.request("com.onescrollgita.app.quick.continue-reading")
    return .result()
  }
}

@available(iOS 16.0, *)
struct OpenBookmarksIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Bookmarks"
  static let description = IntentDescription("Open your bookmarked verses in One Scroll Gita.")
  static let openAppWhenRun = true
  @MainActor func perform() async throws -> some IntentResult {
    QuickActionsPlugin.request("com.onescrollgita.app.quick.bookmarks")
    return .result()
  }
}

@available(iOS 16.0, *)
struct StartListeningIntent: AppIntent {
  static let title: LocalizedStringResource = "Start Listening"
  static let description = IntentDescription(
    "Resume listening to the Bhagavad-gītā recitation in One Scroll Gita (Shravan)."
  )
  static let openAppWhenRun = true
  @MainActor func perform() async throws -> some IntentResult {
    QuickActionsPlugin.request("com.onescrollgita.app.quick.start-listening")
    return .result()
  }
}
