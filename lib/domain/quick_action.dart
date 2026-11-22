/// App actions launched from iOS: Home Screen Quick Actions (the first four,
/// also declared in ios/Runner/Info.plist), Control Center controls and
/// Shortcuts / Action Button intents (ios/Runner/AppDelegate.swift). The
/// type strings are stable and must stay in sync with those files.
enum QuickAction {
  continueReading('com.onescrollgita.app.quick.continue-reading'),
  todaysVerse('com.onescrollgita.app.quick.todays-verse'),
  randomVerse('com.onescrollgita.app.quick.random-verse'),
  bookmarks('com.onescrollgita.app.quick.bookmarks'),

  /// Shortcuts / Action Button only (not a Home Screen Quick Action).
  startListening('com.onescrollgita.app.quick.start-listening');

  const QuickAction(this.type);

  final String type;

  static QuickAction? fromType(String? type) =>
      values.where((a) => a.type == type).firstOrNull;
}
