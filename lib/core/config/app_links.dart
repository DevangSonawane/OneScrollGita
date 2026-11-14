import 'package:flutter/foundation.dart';

/// Shareable verse links.
///
/// On Android a shared link is the app's Google Play page; on iOS it is the
/// App Store page once [appStoreId] is set. Play passes the `referrer`
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

  /// The app's Apple ID in App Store Connect (App Information → Apple ID).
  static const appStoreId = '6834103489';

  static const appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

  /// The link shared with a verse. Android: the Play Store link carrying the
  /// verse as the install referrer. iOS: the App Store page (the App Store
  /// has no install referrer, so a new reader starts at Home).
  static String verseUrl(String verseId) {
    if (defaultTargetPlatform == TargetPlatform.iOS && appStoreId.isNotEmpty) {
      return appStoreUrl;
    }
    return '$playStoreUrl&referrer=${Uri.encodeQueryComponent('verse=$verseId')}';
  }

  /// The verse id inside an install referrer string, if any.
  static String? verseFromReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    final params = Uri.splitQueryString(referrer);
    return params['verse'];
  }

  /// Store link appended to the streak share caption. Empty for now; set it
  /// before release (docs/review-needed.md). Omitted while empty.
  static const shareLink = '';

  /// Apple's standard licence agreement (owner decision, 2026-11-13).
  static const appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Terms of use (EULA) and privacy policy, shown on the Sadhak paywall.
  /// The App Store requires both for subscriptions. iOS uses Apple's
  /// standard EULA; Android has no terms page yet, so the link is hidden there.
  static String get termsUrl =>
      defaultTargetPlatform == TargetPlatform.iOS ? appleStandardEulaUrl : '';

  static const privacyUrl = 'https://onescrollgita.asynk.in/privacy';
}
