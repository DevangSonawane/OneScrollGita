import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/app/app.dart';
import 'package:versescroll/application/audio_providers.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/data/audio/audio_catalog.dart';
import 'package:versescroll/data/audio/audio_engine.dart';
import 'package:versescroll/data/audio/manifest_source.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/application/reminder_providers.dart';
import 'package:versescroll/data/notifications/notification_service.dart';
import 'package:versescroll/application/scripture_providers.dart';
import 'package:versescroll/application/streak_providers.dart';
import 'package:versescroll/application/study_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/data/scripture/scripture_repository.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/data/content/content_repository.dart';
import 'package:versescroll/data/user/activity_repository.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/data/user/study_repository.dart';
import 'package:versescroll/domain/local_date.dart';
import 'package:versescroll/data/user/user_data_repository.dart';
import 'package:versescroll/data/purchases/purchase_gateway.dart';

import 'fakes/fake_purchase_gateway.dart';

/// Reads assets straight from disk with synchronous futures, so widget
/// tests under fake time never wait on real I/O.
class DiskAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.sublistView(File(key).readAsBytesSync()));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());
}

class TestApp {
  TestApp(this.container, this.db, this.prefs);

  final ProviderContainer container;
  final AppDatabase db;
  final SharedPreferences prefs;

  UserDataRepository get userData => container.read(userDataRepositoryProvider);
}

/// Pumps the full app with an in-memory database and mock preferences.
Future<TestApp> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {SettingsRepository.kFirstLaunch: true},
  DateTime? now,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool reducedMotion = false,

  /// Off: today's "Good work" popup counts as already shown, so it never
  /// covers buttons a test taps.
  bool streakPopup = false,
  Brightness brightness = Brightness.light,
  GlassMode? glass = GlassMode.solid,
  PurchaseGateway? purchases,

  /// A stand-in for the real manifest (null: the silent preview).
  ManifestSource? audioManifest,

  /// A stand-in for the platform notifications (null: does nothing).
  NotificationService? notifications,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  SharedPreferences.setMockInitialValues({
    if (!streakPopup)
      SettingsRepository.kStreakPopupShownDate: dateKey(now ?? DateTime.now()),
    ...prefs,
  });
  final sp = await tester.runAsync(SharedPreferences.getInstance);
  final db = AppDatabase.memory();
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(sp!)),
      userDataRepositoryProvider.overrideWithValue(UserDataRepository(db)),
      activityRepositoryProvider.overrideWithValue(
        ActivityRepository(db, clock: now == null ? null : () => now),
      ),
      studyRepositoryProvider.overrideWithValue(
        StudyRepository(db, clock: now == null ? null : () => now),
      ),
      contentRepositoryProvider.overrideWithValue(
        ContentRepository(bundle: DiskAssetBundle()),
      ),
      scriptureRepositoryProvider.overrideWithValue(
        ScriptureRepository(bundle: DiskAssetBundle(), parseInIsolate: false),
      ),
      if (glass != null) glassModeOverrideProvider.overrideWithValue(glass),
      if (now != null) clockProvider.overrideWithValue(() => now),
      todayProvider.overrideWith(_TestToday.new),
      // Tests never stream: the silent engine and estimated lengths.
      audioEngineProvider.overrideWith((ref) {
        final e = PretendAudioEngine();
        ref.onDispose(e.dispose);
        return e;
      }),
      audioCatalogProvider.overrideWith(
        (ref) => AudioCatalog(
          ref.watch(scriptureRepositoryProvider),
          manifest: audioManifest,
        ),
      ),
      purchaseGatewayProvider.overrideWithValue(
        purchases ?? FakePurchaseGateway(),
      ),
      if (notifications != null)
        notificationServiceProvider.overrideWithValue(notifications),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(db.close);
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GitaApp()),
  );
  await settle(tester);
  return TestApp(container, db, sp);
}

/// Lets database streams deliver (they complete on real microtasks) and
/// animations finish.
Future<void> settle(WidgetTester tester, [int rounds = 3]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// No midnight timer in tests.
class _TestToday extends TodayNotifier {
  @override
  void scheduleMidnight(DateTime now) {}
}
