/// Local calendar dates as plain `YYYY-MM-DD` strings (PRD_v2 section 4).
///
/// Arithmetic runs on UTC midnights of the local Y-M-D, so daylight-saving
/// changes never shift a day.
library;

String dateKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// Parses a `YYYY-MM-DD` key, or null when it is not a real date.
DateTime? parseDateKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final date = DateTime.utc(y, mo, d);
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date;
}

/// The key [days] after [key] (negative goes back).
String addDays(String key, int days) {
  final d = parseDateKey(key)!;
  return dateKey(DateTime.utc(d.year, d.month, d.day + days));
}

/// Whole days from [from] to [to] (positive when [to] is later).
int daysBetween(String from, String to) =>
    parseDateKey(to)!.difference(parseDateKey(from)!).inDays;

/// A `HH:mm` time of day.
class TimeOfDayHm {
  const TimeOfDayHm(this.hour, this.minute);

  final int hour;
  final int minute;

  static TimeOfDayHm? tryParse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return TimeOfDayHm(h, min);
  }

  String get hm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  int get minutes => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayHm && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => hm;
}
