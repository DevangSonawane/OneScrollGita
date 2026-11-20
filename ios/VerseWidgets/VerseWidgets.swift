// Home-screen widgets for iOS. They mirror the Android widgets
// (android/app/src/main/kotlin/.../VerseWidgets.kt): "Verse of the day" and
// "Continue reading". The Flutter app writes the data through home_widget
// into the shared App Group; these widgets only read it. No network.

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

@main
struct VerseWidgetsBundle: WidgetBundle {
  var body: some Widget {
    DailyVerseWidget()
    RecentWidget()
  }
}
