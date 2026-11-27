#!/bin/sh
# Checks that the watch's verse of the day (ios/GitaWatch/Shared/DailyVerse.swift)
# picks the same entry as the app's (lib/domain/daily_verse.dart) for every
# local day from 2021 to 2034 and several entry counts. Needs macOS with Xcode.
# Run from the repo root: sh tool/check_watch_daily_parity.sh
set -e
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/main.swift" <<'SWIFT'
import Foundation
let cal = Calendar.current
for n in [1, 2, 7, 657, 700] {
  for day in -1100...4000 {
    let date = cal.date(from: DateComponents(year: 2024, month: 1, day: 1 + day, hour: 12))!
    print("\(n) \(day) \(DailyVerse.entryIndex(for: date, count: n))")
  }
}
SWIFT
xcrun swiftc -O ios/GitaWatch/Shared/DailyVerse.swift "$tmp/main.swift" -o "$tmp/parity"
"$tmp/parity" > "$tmp/swift.txt"
dart run tool/watch_daily_parity.dart > "$tmp/dart.txt"
if cmp -s "$tmp/swift.txt" "$tmp/dart.txt"; then
  echo "Daily verse parity OK ($(wc -l < "$tmp/dart.txt" | tr -d ' ') days checked)."
else
  echo "Daily verse MISMATCH between Dart and Swift:"
  diff "$tmp/dart.txt" "$tmp/swift.txt" | head -20
  exit 1
fi
