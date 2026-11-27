// Prints the verse of the day index for many local dates, for
// tool/check_watch_daily_parity.sh (compared with the watch's Swift port).
import 'package:versescroll/domain/daily_verse.dart';

void main() {
  for (final n in [1, 2, 7, 657, 700]) {
    for (var day = -1100; day <= 4000; day++) {
      final date = DateTime(2024, 1, 1 + day, 12);
      // ignore: avoid_print
      print('$n $day ${dailyEntryIndex(date, n)}');
    }
  }
}
