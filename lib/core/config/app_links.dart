/// Shareable verse links.
///
/// A shared link is the app's Google Play page. Play passes the `referrer`
/// to the app after install, so a new reader lands on the shared verse on
/// first launch (see `handleInstallReferrer`). Someone who already has the
/// app sees "Open" on the Play page.
abstract final class AppLinks {
  /// The Android application id (also the Play Store id).
  static const packageName = 'com.onescrollgita.app';

  /// Custom scheme that opens the installed app at a verse:
  /// `gitaapp://open/verse?id=bg-02-047`.
  static const scheme = 'gitaapp';

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  /// Play Store link carrying the verse as the install referrer.
  static String verseUrl(String verseId) =>
      '$playStoreUrl&referrer=${Uri.encodeQueryComponent('verse=$verseId')}';

  /// The verse id inside an install referrer string, if any.
  static String? verseFromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    final params = Uri.splitQueryString(referrer);
    return params['verse'];
  }

  /// Store link appended to the streak share caption. Empty for now; set it
  /// before release (docs/review-needed.md). Omitted while empty.
  static const shareLink = '';
}
