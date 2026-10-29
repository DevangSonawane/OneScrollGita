/// What counts as a "read day" (PRD_v2 section 4). Kept in one place so the
/// rule is easy to change.
abstract final class ReadRule {
  /// Reader or purport page: verse visible, app in the foreground.
  static const readerDwell = Duration(seconds: 5);

  /// Home: the daily verse visible. Tapping Read in Gita, Purport,
  /// Favourite or Bookmark on it qualifies immediately.
  static const homeDwell = Duration(seconds: 10);
}
