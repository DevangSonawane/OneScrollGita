import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/core_providers.dart';
import '../application/reminder_providers.dart';
import '../application/scripture_providers.dart';
import '../application/widget_sync.dart';
import '../core/design/theme.dart';
import '../domain/models/app_settings.dart';
import '../features/streak/streak_popup.dart';
import 'router.dart';

class GitaApp extends ConsumerStatefulWidget {
  const GitaApp({super.key});

  @override
  ConsumerState<GitaApp> createState() => _GitaAppState();
}

class _GitaAppState extends ConsumerState<GitaApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Home-screen widgets: start syncing once the first verse is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widgetSyncProvider);
      _startReminders().ignore();
    });
  }

  /// Local reminders: tap handling, then a schedule rebuild (PRD_v2 5).
  Future<void> _startReminders() async {
    final svc = ref.read(notificationServiceProvider);
    try {
      await svc.init();
      _taps = svc.taps.listen(_openFromNotification);
      final launch = await svc.launchPayload();
      if (launch != null) _openFromNotification(launch);
    } catch (_) {
      // Notifications unavailable: the app works without them.
    }
    await ref.read(reminderControllerProvider.notifier).onAppOpened();
  }

  /// '' opens Home; a verse id opens the reader at that verse.
  void _openFromNotification(String payload) {
    if (!mounted || !ref.read(settingsProvider).firstLaunchDone) return;
    final router = ref.read(routerProvider);
    router.go(
      payload.isEmpty
          ? '/home'
          : '/gita?verse=${Uri.encodeQueryComponent(payload)}',
    );
  }

  @override
  void dispose() {
    _taps?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The daily verse is re-evaluated on resume, and reminders rebuilt
    // (catches time-zone and clock changes).
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
      ref.read(reminderControllerProvider.notifier).onAppOpened().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'One Scroll Gita',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      themeAnimationDuration: const Duration(milliseconds: 240),
      routerConfig: router,
      // Above every route, so the popup also shows over the purport page.
      builder: (context, child) =>
          StreakPopupHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
