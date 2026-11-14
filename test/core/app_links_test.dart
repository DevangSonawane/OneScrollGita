import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/core/config/app_links.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('privacy policy link is set for both stores', () {
    expect(AppLinks.privacyUrl, startsWith('https://'));
  });

  test('iOS paywall links to Apple standard EULA', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AppLinks.termsUrl, AppLinks.appleStandardEulaUrl);
  });

  test('Android shows no terms link yet', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppLinks.termsUrl, isEmpty);
  });

  test('Android shares the Play link with the verse as referrer', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final url = AppLinks.verseUrl('bg-02-047');
    expect(url, startsWith(AppLinks.playStoreUrl));
    expect(
      AppLinks.verseFromReferrer(Uri.parse(url).queryParameters['referrer']),
      'bg-02-047',
    );
  });

  test('iOS shares the App Store link once the Apple ID is set', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final url = AppLinks.verseUrl('bg-02-047');
    expect(
      url,
      AppLinks.appStoreId.isEmpty
          ? startsWith(AppLinks.playStoreUrl)
          : AppLinks.appStoreUrl,
    );
  });
}
