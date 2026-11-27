// Watch face complications for One Scroll Gita (docs/PRD_v10.md section 6).
//
// The verse of the day is worked out on the watch from its own copy of the
// text (Shared/Scripture.swift, Shared/DailyVerse.swift), so the timeline
// holds one entry per day for a week, each starting at local midnight.
// WidgetKit swaps entries on its own; the timeline asks for a reload only
// when it runs out, and the watch app reloads it when the language changes.
// That stays far inside the system's refresh budget. No network.

import SwiftUI
import WidgetKit

struct DailyEntry: TimelineEntry {
  let date: Date
  let verse: Verse?
  let language: String
}

struct DailyProvider: TimelineProvider {
  private static let days = 7

  func placeholder(in context: Context) -> DailyEntry {
    DailyEntry(date: Date(), verse: Scripture.shared.verses.first, language: "en")
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
    completion(entry(on: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    var entries = [entry(on: Date())]
    for d in 1..<Self.days {
      if let day = calendar.date(byAdding: .day, value: d, to: start) {
        entries.append(entry(on: day))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(on date: Date) -> DailyEntry {
    DailyEntry(
      date: date, verse: Scripture.shared.daily(on: date), language: SharedState.language)
  }
}

/// A small lotus, the same shape as the iPhone lock screen widget's.
struct LotusShape: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    let w = r.width, h = r.height
    let base = CGPoint(x: r.midX, y: r.minY + h * 0.92)
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

struct DailyComplicationView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DailyEntry

  private var label: String { entry.verse?.label ?? "Gītā" }

  var body: some View {
    Group {
      switch family {
      case .accessoryInline:
        // Next to the time: "Gītā 2.47".
        Text("Gītā \(label)")
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          VStack(spacing: 1) {
            LotusShape()
              .frame(width: 16, height: 12)
            Text(label)
              .font(.system(size: 12, weight: .semibold, design: .rounded))
              .minimumScaleFactor(0.6)
              .lineLimit(1)
          }
          .padding(.horizontal, 4)
        }
      case .accessoryCorner:
        LotusShape()
          .frame(width: 20, height: 16)
          .widgetLabel("Gītā \(label)")
      default:
        // Rectangular: reference and the start of the translation.
        VStack(alignment: .leading, spacing: 1) {
          HStack(spacing: 4) {
            LotusShape()
              .frame(width: 12, height: 9)
            Text("Gītā \(label)")
              .font(.headline)
              .widgetAccentable()
          }
          Text(entry.verse?.translation(entry.language) ?? "Verse of the day")
            .font(.caption2)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .containerBackground(.clear, for: .widget)
    .widgetURL(URL(string: "gitawatch://today"))
    .accessibilityLabel("Verse of the day, Bhagavad-gītā \(label)")
  }
}

@main
struct DailyVerseComplication: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "WatchDailyVerse", provider: DailyProvider()) { entry in
      DailyComplicationView(entry: entry)
    }
    .configurationDisplayName("Verse of the Day")
    .description("Today's verse from the Bhagavad-gītā.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
  }
}
