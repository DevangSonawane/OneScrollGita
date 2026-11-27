// Home-screen widgets for iOS. They mirror the Android widgets
// (android/app/src/main/kotlin/.../VerseWidgets.kt): "Verse of the day",
// "Continue reading" and "Listen" (PRD_v11). The Flutter app writes the data through home_widget
// into the shared App Group; these widgets only read it. No network.

import AppIntents
import SwiftUI
import WidgetKit

private let appGroup = "group.com.onescrollgita.app"
private let appName = "One Scroll Gita"

// MARK: - Shared data

private struct VerseItem: Decodable {
  let id: String
  let label: String
  let text: String
  let date: String?
}

private func readItems(_ key: String) -> [VerseItem] {
  guard
    let raw = UserDefaults(suiteName: appGroup)?.string(forKey: key),
    let data = raw.data(using: .utf8),
    let items = try? JSONDecoder().decode([VerseItem].self, from: data)
  else { return [] }
  return items
}

private func dayString(_ date: Date) -> String {
  let f = DateFormatter()
  f.calendar = Calendar(identifier: .gregorian)
  f.locale = Locale(identifier: "en_US_POSIX")
  f.timeZone = .current
  f.dateFormat = "yyyy-MM-dd"
  return f.string(from: date)
}

/// Opens the app at [verseId] (the app's /verse route), or just opens it.
private func openURL(_ verseId: String?) -> URL {
  guard let id = verseId,
    let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  else { return URL(string: "gitaapp://open")! }
  return URL(string: "gitaapp://open/verse?id=\(encoded)")!
}

// MARK: - Colours (same values as android/.../values*/widget_colors.xml)

private extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(UIColor { traits in
      let hex = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1)
    })
  }

  static let widgetBg = Color(light: 0xFBF8F3, dark: 0x1D1915)
  static let widgetChip = Color(light: 0xF4EFE7, dark: 0x26211C)
  static let widgetText = Color(light: 0x232120, dark: 0xEDE6DC)
  static let widgetTextSecondary = Color(light: 0x5F5850, dark: 0xB5ACA0)
  static let widgetAccent = Color(light: 0xA04A12, dark: 0xE39A5E)
}

private extension View {
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(Color.widgetBg, for: .widget)
    } else {
      padding(16).background(Color.widgetBg)
    }
  }
}

// MARK: - Lock screen (iOS 16+, PRD_v6 section 5)

/// Families each widget offers: the home-screen sizes, plus the lock screen
/// sizes on iOS 16 and later.
private func families(_ home: [WidgetFamily], lock: Bool) -> [WidgetFamily] {
  if #available(iOSApplicationExtension 16.0, *), lock {
    return home + [.accessoryInline, .accessoryRectangular, .accessoryCircular]
  }
  return home
}

private func isLockScreen(_ family: WidgetFamily) -> Bool {
  if #available(iOSApplicationExtension 16.0, *) {
    switch family {
    case .accessoryInline, .accessoryRectangular, .accessoryCircular:
      return true
    default:
      return false
    }
  }
  return false
}

/// A small lotus drawn as a shape (five petals over a soft base), used on
/// the round lock screen widget instead of a symbol.
private struct LotusShape: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    let w = r.width, h = r.height
    let base = CGPoint(x: r.midX, y: r.minY + h * 0.92)
    // Seven almond petals fanned around the base, the centre one tallest.
    let petals: [(angle: CGFloat, length: CGFloat, width: CGFloat)] = [
      (-78, 0.52, 0.17), (78, 0.52, 0.17),
      (-50, 0.72, 0.21), (50, 0.72, 0.21),
      (-24, 0.86, 0.23), (24, 0.86, 0.23),
      (0, 0.95, 0.25),
    ]
    for petal in petals {
      let len = h * petal.length, half = w * petal.width / 2
      var leaf = Path()
      leaf.move(to: .zero)
      leaf.addQuadCurve(to: CGPoint(x: 0, y: -len), control: CGPoint(x: -half * 1.6, y: -len * 0.5))
      leaf.addQuadCurve(to: .zero, control: CGPoint(x: half * 1.6, y: -len * 0.5))
      leaf.closeSubpath()
      let t = CGAffineTransform(translationX: base.x, y: base.y)
        .rotated(by: petal.angle * .pi / 180)
      p.addPath(leaf, transform: t)
    }
    return p
  }
}

/// "2.47" from "Bhagavad-gītā 2.47"-style labels (labels are already short).
private func shortLabel(_ v: VerseItem?) -> String { v?.label ?? "Gītā" }

@available(iOSApplicationExtension 16.0, *)
private struct LockView: View {
  let family: WidgetFamily
  let header: String
  let verse: VerseItem?
  let empty: String

  var body: some View {
    switch family {
    case .accessoryInline:
      // One line next to the clock: "Gītā 2.47 · first words".
      Text(verse.map { "Gītā \($0.label) · \($0.text)" } ?? empty)
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: 0) {
          LotusShape()
            .frame(width: 22, height: 15)
            .widgetAccentable()
          Text(shortLabel(verse))
            .font(.system(size: 11, weight: .semibold))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
        }
        .padding(2)
      }
    default:
      VStack(alignment: .leading, spacing: 1) {
        Text(verse.map { "\(header) · \($0.label)" } ?? header)
          .font(.system(size: 12, weight: .semibold))
          .widgetAccentable()
        Text(verse?.text ?? empty)
          .font(.system(size: 13))
          .lineLimit(3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private extension View {
  /// Lock screen widgets have no coloured card; home-screen ones do.
  @ViewBuilder func lockAwareBackground(_ family: WidgetFamily) -> some View {
    if isLockScreen(family) {
      if #available(iOS 17.0, *) {
        containerBackground(.clear, for: .widget)
      } else {
        self
      }
    } else {
      widgetBackground()
    }
  }
}

private struct Header: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .bold))
      .tracking(0.9)
      .foregroundColor(.widgetAccent)
  }
}

// MARK: - Verse of the day

private struct DailyEntry: TimelineEntry {
  let date: Date
  let verse: VerseItem?
}

private struct DailyProvider: TimelineProvider {
  /// The latest stored day that is not in the future, like the Android widget.
  static func verse(on day: Date, in items: [VerseItem]) -> VerseItem? {
    let key = dayString(day)
    return items.last { ($0.date ?? "") <= key }
  }

  func placeholder(in context: Context) -> DailyEntry {
    DailyEntry(date: Date(), verse: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
    let now = Date()
    completion(DailyEntry(date: now, verse: Self.verse(on: now, in: readItems("daily_verses"))))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
    // The app stores the next 30 days, so the widget changes at midnight
    // without the app being opened.
    let items = readItems("daily_verses")
    let cal = Calendar.current
    let now = Date()
    var entries = [DailyEntry(date: now, verse: Self.verse(on: now, in: items))]
    var day = cal.startOfDay(for: now)
    for _ in 0..<30 {
      guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
      entries.append(DailyEntry(date: day, verse: Self.verse(on: day, in: items)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

private struct DailyView: View {
  let entry: DailyEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), isLockScreen(family) {
      LockView(
        family: family,
        header: "Verse of the day",
        verse: entry.verse,
        empty: "Open One Scroll Gita"
      )
      .lockAwareBackground(family)
      .widgetURL(openURL(entry.verse?.id))
    } else {
      homeBody
    }
  }

  private var homeBody: some View {
    VStack(alignment: .leading, spacing: 0) {
      Header(text: "VERSE OF THE DAY")
      Text(entry.verse?.text ?? "Open One Scroll Gita to load today's verse.")
        .font(.system(size: family == .systemSmall ? 13 : 15))
        .lineSpacing(2)
        .foregroundColor(.widgetText)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 8)
      Text(entry.verse.map { "Bhagavad-gītā \($0.label)" } ?? appName)
        .font(.system(size: 12))
        .foregroundColor(.widgetTextSecondary)
        .padding(.top, 6)
    }
    .widgetBackground()
    .widgetURL(openURL(entry.verse?.id))
  }
}

struct DailyVerseWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DailyVerseWidget", provider: DailyProvider()) { entry in
      DailyView(entry: entry)
    }
    .configurationDisplayName("Verse of the day")
    .description("Today's verse from the Bhagavad-gītā. Changes every day.")
    .supportedFamilies(families([.systemSmall, .systemMedium, .systemLarge], lock: true))
  }
}

// MARK: - Continue reading

private struct RecentEntry: TimelineEntry {
  let date: Date
  let items: [VerseItem]
}

private struct RecentProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecentEntry {
    RecentEntry(date: Date(), items: [])
  }

  func getSnapshot(in context: Context, completion: @escaping (RecentEntry) -> Void) {
    completion(RecentEntry(date: Date(), items: readItems("history_items")))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RecentEntry>) -> Void) {
    // The app reloads this widget whenever the history changes.
    let entry = RecentEntry(date: Date(), items: readItems("history_items"))
    completion(Timeline(entries: [entry], policy: .never))
  }
}

private struct RecentView: View {
  let entry: RecentEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *), isLockScreen(family) {
      LockView(
        family: family,
        header: "Continue",
        verse: entry.items.first,
        empty: "Start reading"
      )
      .lockAwareBackground(family)
      .widgetURL(openURL(entry.items.first?.id))
    } else {
      homeBody
    }
  }

  private var homeBody: some View {
    VStack(alignment: .leading, spacing: 0) {
      Header(text: "CONTINUE READING")
      if let first = entry.items.first {
        Link(destination: openURL(first.id)) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Bhagavad-gītā \(first.label)")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.widgetText)
            Text(first.text)
              .font(.system(size: 14))
              .lineSpacing(2)
              .lineLimit(family == .systemSmall ? 3 : 4)
              .foregroundColor(.widgetText)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.top, 8)
        if family != .systemSmall && entry.items.count > 1 {
          HStack(spacing: 6) {
            ForEach(Array(entry.items.dropFirst().prefix(3)), id: \.id) { item in
              Link(destination: openURL(item.id)) {
                Text(item.label)
                  .font(.system(size: 12))
                  .foregroundColor(.widgetText)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 4)
                  .background(Capsule().fill(Color.widgetChip))
              }
            }
          }
          .padding(.top, 8)
        }
      } else {
        Text("Verses you read will appear here.")
          .font(.system(size: 14))
          .foregroundColor(.widgetTextSecondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .padding(.top, 8)
      }
    }
    .widgetBackground()
    .widgetURL(openURL(entry.items.first?.id))
  }
}

struct RecentWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "RecentWidget", provider: RecentProvider()) { entry in
      RecentView(entry: entry)
    }
    .configurationDisplayName("Continue reading")
    .description("The verse you read last, and a few before it.")
    .supportedFamilies(families([.systemSmall, .systemMedium], lock: true))
  }
}

// MARK: - Control Center controls (iOS 18+, docs/PRD_v8.md)
//
// Each control runs an intent that opens the app (openAppWhenRun). The same
// intents are defined in the app target (ios/Runner/AppDelegate.swift), as
// Apple requires; iOS runs the app's copy, which hands the Home Screen
// Quick Action type to Flutter. The app decides the destination with its
// own data (last-read position, daily verse, dataset, bookmarks).
// Keep names, titles and types identical in both files.

// MARK: - Listen (PRD_v11)
//
// The last place listened to, from the app ("listen_state": chapter, title
// in the reading language, verse label). Tapping opens the app through the
// Start Listening link; the app plays only with Shravan, otherwise it shows
// the paywall. The widget never knows about purchases.

private struct ListenState: Decodable {
  let chapter: Int
  let title: String
  let label: String
  let lang: String?
}

private func readListen() -> ListenState? {
  guard
    let raw = UserDefaults(suiteName: appGroup)?.string(forKey: "listen_state"),
    let data = raw.data(using: .utf8)
  else { return nil }
  return try? JSONDecoder().decode(ListenState.self, from: data)
}

private let listenURL = URL(
  string: "gitaapp://open/quick?type=com.onescrollgita.app.quick.start-listening")!

private func devanagariDigits(_ n: Int) -> String {
  let digits: [Character] = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"]
  return String(String(n).map { digits[Int(String($0))!] })
}

/// "Chapter 2 · 2.47", or "अध्याय २ · 2.47" when reading in Hindi.
private func listenSubtitle(_ s: ListenState) -> String {
  let chapter = s.lang == "hi" ? "अध्याय \(devanagariDigits(s.chapter))" : "Chapter \(s.chapter)"
  return s.label.isEmpty ? chapter : "\(chapter) · \(s.label)"
}

private func coverName(_ chapter: Int) -> String {
  String(format: "cover%02d", min(max(chapter, 1), 18))
}

private struct ListenEntry: TimelineEntry {
  let date: Date
  let state: ListenState
}

private let listenFallback = ListenState(
  chapter: 1, title: "Observing the Armies on the Battlefield of Kurukṣetra",
  label: "", lang: "en")

private struct ListenProvider: TimelineProvider {
  func placeholder(in context: Context) -> ListenEntry {
    ListenEntry(date: Date(), state: listenFallback)
  }

  func getSnapshot(in context: Context, completion: @escaping (ListenEntry) -> Void) {
    completion(ListenEntry(date: Date(), state: readListen() ?? listenFallback))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ListenEntry>) -> Void) {
    // The app reloads this widget whenever the place or language changes.
    completion(Timeline(
      entries: [ListenEntry(date: Date(), state: readListen() ?? listenFallback)],
      policy: .never))
  }
}

private extension Color {
  static let onCover = Color.white
  static let onCoverSoft = Color.white.opacity(0.88)
}

/// The white disc with a play triangle.
private struct PlayDisc: View {
  let size: CGFloat
  var body: some View {
    ZStack {
      Circle().fill(Color.white)
      Image(systemName: "play.fill")
        .font(.system(size: size * 0.4, weight: .bold))
        .foregroundColor(.widgetAccent)
        .offset(x: size * 0.04)
    }
    .frame(width: size, height: size)
    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
  }
}

private struct CoverScrim: View {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: .black.opacity(0.35), location: 0),
        .init(color: .clear, location: 0.35),
        .init(color: .black.opacity(0.75), location: 1),
      ],
      startPoint: .top, endPoint: .bottom)
  }
}

private struct ListenView: View {
  let entry: ListenEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    Group {
      if #available(iOSApplicationExtension 16.0, *), isLockScreen(family) {
        lock.lockAwareBackground(family)
      } else if family == .systemSmall {
        small
      } else {
        medium
      }
    }
    .widgetURL(listenURL)
  }

  private var s: ListenState { entry.state }

  // Small: the cover fills the widget; name and play over its foot.
  @ViewBuilder private var small: some View {
    let content = VStack(alignment: .leading, spacing: 2) {
      HStack {
        Image(systemName: "headphones")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(.onCover)
        Spacer()
        PlayDisc(size: 34)
      }
      Spacer(minLength: 0)
      Text(s.title)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(.onCover)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
      Text(listenSubtitle(s))
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.onCoverSoft)
        .lineLimit(1)
    }
    if #available(iOS 17.0, *) {
      content.containerBackground(for: .widget) {
        ZStack {
          Image(coverName(s.chapter)).resizable().scaledToFill()
          CoverScrim()
        }
      }
    } else {
      content
        .padding(14)
        .background(
          ZStack {
            Image(coverName(s.chapter)).resizable().scaledToFill()
            CoverScrim()
          })
    }
  }

  // Medium: cover on the left, words and a Play button on the right.
  private var medium: some View {
    HStack(spacing: 14) {
      Image(coverName(s.chapter))
        .resizable()
        .scaledToFill()
        .frame(width: 112, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      VStack(alignment: .leading, spacing: 3) {
        Header(text: "SHRAVAN")
        Text(s.title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.widgetText)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
        Text(listenSubtitle(s))
          .font(.system(size: 12))
          .foregroundColor(.widgetTextSecondary)
          .lineLimit(1)
        Spacer(minLength: 4)
        HStack(spacing: 6) {
          Image(systemName: "play.fill").font(.system(size: 11, weight: .bold))
          Text("Play").font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.widgetAccent))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .widgetBackground()
  }

  @available(iOSApplicationExtension 16.0, *)
  @ViewBuilder private var lock: some View {
    switch family {
    case .accessoryInline:
      Label("\(listenSubtitle(s)) · \(s.title)", systemImage: "headphones")
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: 0) {
          Image(systemName: "headphones")
            .font(.system(size: 15, weight: .semibold))
            .widgetAccentable()
          Text(s.lang == "hi" ? devanagariDigits(s.chapter) : "\(s.chapter)")
            .font(.system(size: 12, weight: .semibold))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
        }
        .padding(2)
      }
    default:
      VStack(alignment: .leading, spacing: 1) {
        Label(listenSubtitle(s), systemImage: "headphones")
          .font(.system(size: 12, weight: .semibold))
          .widgetAccentable()
        Text(s.title)
          .font(.system(size: 13))
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct ListenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ListenWidget", provider: ListenProvider()) { entry in
      ListenView(entry: entry)
    }
    .configurationDisplayName("Listen")
    .description("Continue listening to the Gītā where you stopped (Shravan).")
    .supportedFamilies(families([.systemSmall, .systemMedium], lock: true))
  }
}

@available(iOSApplicationExtension 16.0, *)
struct OpenTodaysVerseIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Today's Verse"
  static let description = IntentDescription("Open today's verse from the Bhagavad-gītā in One Scroll Gita.")
  static let openAppWhenRun = true
  func perform() async throws -> some IntentResult { .result() }
}

@available(iOSApplicationExtension 16.0, *)
struct OpenRandomVerseIntent: AppIntent {
  static let title: LocalizedStringResource = "Open a Random Verse"
  static let description = IntentDescription("Open a random verse from the Bhagavad-gītā in One Scroll Gita.")
  static let openAppWhenRun = true
  func perform() async throws -> some IntentResult { .result() }
}

@available(iOSApplicationExtension 16.0, *)
struct OpenContinueReadingIntent: AppIntent {
  static let title: LocalizedStringResource = "Continue Reading"
  static let description = IntentDescription("Open the verse you read last in One Scroll Gita.")
  static let openAppWhenRun = true
  func perform() async throws -> some IntentResult { .result() }
}

@available(iOSApplicationExtension 16.0, *)
struct OpenBookmarksIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Bookmarks"
  static let description = IntentDescription("Open your bookmarked verses in One Scroll Gita.")
  static let openAppWhenRun = true
  func perform() async throws -> some IntentResult { .result() }
}

@available(iOSApplicationExtension 16.0, *)
struct StartListeningIntent: AppIntent {
  static let title: LocalizedStringResource = "Start Listening"
  static let description = IntentDescription(
    "Resume listening to the Bhagavad-gītā recitation in One Scroll Gita (Shravan)."
  )
  static let openAppWhenRun = true
  func perform() async throws -> some IntentResult { .result() }
}

@available(iOSApplicationExtension 18.0, *)
struct TodaysVerseControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.onescrollgita.app.control.todays-verse") {
      ControlWidgetButton(action: OpenTodaysVerseIntent()) {
        Label("Today's Verse", systemImage: "sun.max")
      }
    }
    .displayName("Today's Verse")
    .description("Open today's verse in One Scroll Gita.")
  }
}

@available(iOSApplicationExtension 18.0, *)
struct RandomVerseControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.onescrollgita.app.control.random-verse") {
      ControlWidgetButton(action: OpenRandomVerseIntent()) {
        Label("Random Verse", systemImage: "shuffle")
      }
    }
    .displayName("Random Verse")
    .description("Open a random verse in One Scroll Gita.")
  }
}

@available(iOSApplicationExtension 18.0, *)
struct ContinueReadingControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.onescrollgita.app.control.continue-reading") {
      ControlWidgetButton(action: OpenContinueReadingIntent()) {
        Label("Continue Reading", systemImage: "book")
      }
    }
    .displayName("Continue Reading")
    .description("Open the verse you read last in One Scroll Gita.")
  }
}

@available(iOSApplicationExtension 18.0, *)
struct BookmarksControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.onescrollgita.app.control.bookmarks") {
      ControlWidgetButton(action: OpenBookmarksIntent()) {
        Label("Bookmarks", systemImage: "bookmark")
      }
    }
    .displayName("Bookmarks")
    .description("Open your saved verses in One Scroll Gita.")
  }
}

@available(iOSApplicationExtension 18.0, *)
struct ListenControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.onescrollgita.app.control.listen") {
      ControlWidgetButton(action: StartListeningIntent()) {
        Label("Listen", systemImage: "headphones")
      }
    }
    .displayName("Listen")
    .description("Continue listening in One Scroll Gita (Shravan).")
  }
}

@main
struct VerseWidgetsBundle: WidgetBundle {
  var body: some Widget {
    DailyVerseWidget()
    RecentWidget()
    ListenWidget()
    // Control Center (iOS 18+). Older iOS versions get the widgets only.
    if #available(iOSApplicationExtension 18.0, *) {
      TodaysVerseControl()
      RandomVerseControl()
      ContinueReadingControl()
      BookmarksControl()
      ListenControl()
    }
  }
}
