import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scripture/scripture_repository.dart';
import '../data/settings/settings_repository.dart';
import '../data/user/user_data_repository.dart';
import '../domain/models/app_settings.dart';

/// Overridden in main() and in tests.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => throw UnimplementedError('settingsRepositoryProvider'),
);
final userDataRepositoryProvider = Provider<UserDataRepository>(
  (_) => throw UnimplementedError('userDataRepositoryProvider'),
);
final scriptureRepositoryProvider = Provider<ScriptureRepository>(
  (_) => ScriptureRepository(),
);

/// Injectable clock for the daily verse and history.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() => _repo.load();

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'hi') return;
    state = state.copyWith(languageCode: code);
    await _repo.setLanguage(code);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.setThemeMode(mode);
  }

  Future<void> setTextScaleStep(int step) async {
    final s = step.clamp(0, readingScaleSteps.length - 1);
    state = state.copyWith(textScaleStep: s);
    await _repo.setTextScaleStep(s);
  }

  Future<void> setSimplifiedGlass(bool v) async {
    state = state.copyWith(simplifiedGlass: v);
    await _repo.setSimplifiedGlass(v);
  }

  Future<void> completeFirstLaunch(String languageCode) async {
    await setLanguage(languageCode);
    state = state.copyWith(firstLaunchDone: true);
    await _repo.setFirstLaunchDone(true);
  }

  Future<void> setLastVerseId(String? id) async {
    if (id == state.lastVerseId) return;
    state = id == null
        ? state.copyWith(clearLastVerseId: true)
        : state.copyWith(lastVerseId: id);
    await _repo.setLastVerseId(id);
  }

  /// Clears every setting, which also returns the app to first launch.
  Future<void> resetAll() async {
    await _repo.clearAll();
    state = _repo.load();
  }
}

final languageProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider.select((s) => s.languageCode)),
);

final readingScaleProvider = Provider<double>(
  (ref) => ref.watch(settingsProvider.select((s) => s.readingScale)),
);
