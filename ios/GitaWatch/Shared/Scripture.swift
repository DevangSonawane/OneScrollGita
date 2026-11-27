// The watch's copy of the verse text: gita_watch.json, generated from
// assets/scripture/ by tool/build_watch_scripture.dart (never edit it by
// hand). Shared by the watch app and its complications. Read-only.

import Foundation

struct Verse: Decodable, Identifiable, Hashable {
  let id: String
  let chapter: Int
  let verseStart: Int
  let verseEnd: Int
  /// "2.47", or "1.16-18" for a range.
  let label: String
  let sanskrit: [String]
  let transliteration: [String]
  let en: String
  /// Nil when the source has no Hindi translation (shown in English).
  let hi: String?

  /// Same rule as VerseEntry.translation in the app: Hindi when asked for
  /// and present, otherwise English.
  func translation(_ language: String) -> String {
    if language == "hi", let hi, !hi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return hi
    }
    return en
  }

  /// "Chapter 2 · Verse 47" or "Chapter 1 · Verses 16–18".
  var reference: String {
    verseEnd == verseStart
      ? "Chapter \(chapter) · Verse \(verseStart)"
      : "Chapter \(chapter) · Verses \(verseStart)–\(verseEnd)"
  }
}

final class Scripture {
  static let shared = Scripture()

  private struct File: Decodable {
    let isPlaceholder: Bool
    let datasetVersion: String?
    let attribution: String?
    let entries: [Verse]
  }

  /// Every entry in the app's order (the daily verse index uses it).
  let verses: [Verse]
  let attribution: String
  private let byId: [String: Int]

  private init() {
    let file = Bundle.main.url(forResource: "gita_watch", withExtension: "json")
      .flatMap { try? Data(contentsOf: $0) }
      .flatMap { try? JSONDecoder().decode(File.self, from: $0) }
    #if !DEBUG
      // Placeholder text must never ship (CLAUDE.md).
      precondition(file?.isPlaceholder != true, "Placeholder scripture in a release build")
    #endif
    verses = file?.entries ?? []
    attribution = file?.attribution ?? ""
    byId = Dictionary(
      verses.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
  }

  func verse(id: String) -> Verse? {
    byId[id].map { verses[$0] }
  }

  /// The verse of the day for [date] (same as the iPhone app).
  func daily(on date: Date = Date()) -> Verse? {
    guard !verses.isEmpty else { return nil }
    return verses[DailyVerse.entryIndex(for: date, count: verses.count)]
  }

  func random(excluding id: String? = nil) -> Verse? {
    guard verses.count > 1 else { return verses.first }
    while true {
      let v = verses.randomElement()!
      if v.id != id { return v }
    }
  }
}

/// What the phone last sent, kept in the watch's App Group so the
/// complication can read the language too.
enum SharedState {
  static let appGroup = "group.com.onescrollgita.app"
  static let languageKey = "watch_language"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: appGroup) ?? .standard
  }

  static var language: String {
    defaults.string(forKey: languageKey) ?? "en"
  }
}
