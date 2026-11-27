// Verse of the day: a line-for-line port of lib/domain/daily_verse.dart, so
// the watch and its complication show the same verse as the iPhone on the
// same day without asking the phone. tool/check_watch_daily_parity.sh
// compares the two over thousands of days. Change both together.

import Foundation

enum DailyVerse {
  private static let mask: UInt64 = 0xFFFF_FFFF

  /// Whole days since 2024-01-01 for the local calendar day of [date],
  /// counted on the Y-M-D so daylight-saving changes never shift it.
  static func dayNumber(_ date: Date, calendar: Calendar = .current) -> Int {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    let day = utc.date(from: DateComponents(year: c.year, month: c.month, day: c.day))!
    let epoch = utc.date(from: DateComponents(year: 2024, month: 1, day: 1))!
    return utc.dateComponents([.day], from: epoch, to: day).day!
  }

  /// Index (0..<n) of the day's entry in the flattened list of all entries.
  static func entryIndex(day: Int, count n: Int) -> Int {
    precondition(n > 0)
    let cycle = floorDiv(day, n)
    let position = day - cycle * n
    return cyclePermutation(cycle, n)[position]
  }

  static func entryIndex(for date: Date, count n: Int, calendar: Calendar = .current) -> Int {
    entryIndex(day: dayNumber(date, calendar: calendar), count: n)
  }

  static func cyclePermutation(_ cycle: Int, _ n: Int) -> [Int] {
    var perm = shuffled(cycle, n)
    if n > 1 {
      let previousLast = shuffled(cycle - 1, n)[n - 1]
      if perm[0] == previousLast { perm.swapAt(0, 1) }
    }
    return perm
  }

  private static func shuffled(_ cycle: Int, _ n: Int) -> [Int] {
    // Dart: Mulberry32(cycle * 0x9E3779B1 + 0x5BD1E995), 64-bit ints.
    let seed = Int64(cycle) &* 0x9E37_79B1 &+ 0x5BD1_E995
    var rng = Mulberry32(seed: UInt64(bitPattern: seed))
    var list = Array(0..<n)
    var i = n - 1
    while i > 0 {
      let j = Int(rng.next() % UInt64(i + 1))
      list.swapAt(i, j)
      i -= 1
    }
    return list
  }

  private static func floorDiv(_ a: Int, _ b: Int) -> Int {
    let q = a / b
    return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
  }

  struct Mulberry32 {
    private var state: UInt64

    init(seed: UInt64) { state = seed & mask }

    mutating func next() -> UInt64 {
      state = (state &+ 0x6D2B_79F5) & mask
      var t = state
      t = imul(t ^ (t >> 15), t | 1)
      t ^= (t &+ imul(t ^ (t >> 7), t | 61)) & mask
      return (t ^ (t >> 14)) & mask
    }

    private func imul(_ a: UInt64, _ b: UInt64) -> UInt64 { (a &* b) & mask }
  }
}
