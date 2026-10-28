import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/core_providers.dart';
import '../application/scripture_providers.dart';
import '../application/widget_sync.dart';
import '../core/design/theme.dart';
import '../domain/models/app_settings.dart';
import 'router.dart';

class GitaApp extends ConsumerStatefulWidget {
  const GitaApp({super.key});

  @override
  ConsumerState<GitaApp> createState() => _GitaAppState();
}

class _GitaAppState extends ConsumerState<GitaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Home-screen widgets: start syncing once the first verse is on screen.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(widgetSyncProvider),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The daily verse is re-evaluated on resume.
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
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
    );
  }
}
