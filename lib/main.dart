import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'application/core_providers.dart';
import 'application/library_providers.dart';
import 'application/reminder_providers.dart';
import 'application/streak_providers.dart';
import 'application/ui_providers.dart';
import 'core/config/app_links.dart';
import 'data/settings/settings_repository.dart';
import 'data/notifications/notification_service.dart';
import 'data/user/activity_repository.dart';
import 'data/user/database.dart';
import 'data/user/user_data_repository.dart';
import 'domain/verse_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _registerFontLicences();

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
      userDataRepositoryProvider.overrideWithValue(UserDataRepository(db)),
      activityRepositoryProvider.overrideWithValue(ActivityRepository(db)),
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)
        notificationServiceProvider.overrideWithValue(
          LocalNotificationService(),
        ),
    ],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const GitaApp()),
  );

  // Not awaited: the first readable verse must not wait for these.
  LiquidGlass.precache().ignore();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(libraryControllerProvider.notifier).purgeOrphans().ignore();
    _openSharedVerseAfterInstall(container, prefs).ignore();
  });
}

/// Someone who installed from a shared verse link lands on that verse.
/// Google Play hands the link's `referrer` to the app; read it once.
Future<void> _openSharedVerseAfterInstall(
  ProviderContainer container,
  SharedPreferences prefs,
) async {
  const handledKey = 'installReferrerHandled';
  if (defaultTargetPlatform != TargetPlatform.android) return;
  if (prefs.getBool(handledKey) ?? false) return;
  await prefs.setBool(handledKey, true);
  try {
    final details = await PlayInstallReferrer.installReferrer;
    final id = AppLinks.verseFromReferrer(details.installReferrer);
    if (id == null || parseVerseId(id) == null) return;
    container.read(readerJumpProvider.notifier).request(id);
    // Before first launch completes, Begin goes to the reader instead.
    if (container.read(settingsProvider).firstLaunchDone) {
      container.read(routerProvider).go('/gita');
    }
  } catch (_) {
    // No Play services (sideloaded, emulator): nothing to open.
  }
}

void _registerFontLicences() {
  const fonts = {
    'Literata': 'Literata-OFL.txt',
    'Noto Serif Devanagari': 'NotoSerifDevanagari-OFL.txt',
    'Inter': 'Inter-OFL.txt',
    'Tiro Devanagari Sanskrit': 'TiroDevanagariSanskrit-OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(:key, :value) in fonts.entries) {
      final text = await rootBundle.loadString('assets/fonts/licences/$value');
      yield LicenseEntryWithLineBreaks([key], text);
    }
  });
}
