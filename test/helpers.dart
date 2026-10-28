import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/app/app.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/ui_providers.dart';
import 'package:versescroll/data/scripture/scripture_repository.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/data/user/database.dart';
import 'package:versescroll/data/user/user_data_repository.dart';

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
  Brightness brightness = Brightness.light,
  GlassMode? glass = GlassMode.solid,
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

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await tester.runAsync(SharedPreferences.getInstance);
  final db = AppDatabase.memory();
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(sp!)),
      userDataRepositoryProvider.overrideWithValue(UserDataRepository(db)),
      scriptureRepositoryProvider.overrideWithValue(
        ScriptureRepository(bundle: DiskAssetBundle(), parseInIsolate: false),
      ),
      if (glass != null) glassModeOverrideProvider.overrideWithValue(glass),
      if (now != null) clockProvider.overrideWithValue(() => now),
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
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}
