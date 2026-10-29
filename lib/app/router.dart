import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/core_providers.dart';
import '../application/ui_providers.dart';
import '../core/design/motion.dart';
import '../core/design/tokens.dart';
import '../domain/verse_navigation.dart';
import '../features/first_launch/welcome_screen.dart';
import '../features/gita/reader_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/profile/library_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/purport/purport_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/search/search_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/specimen/specimen_screen.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    settingsProvider.select((s) => s.firstLaunchDone),
    (_, _) => refresh.value++,
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(settingsProvider).firstLaunchDone;
      final atWelcome = state.matchedLocation == '/welcome';
      if (!done && !atWelcome) return '/welcome';
      // A shared verse opened before first launch finishes opens after it.
      if (done && atWelcome) {
        return ref.read(readerJumpProvider) == null ? '/home' : '/gita';
      }
      return null;
    },
    routes: [
      // Shared links: https://<domain>/verse?id=bg-02-047 and
      // gitaapp://open/verse?id=bg-02-047 open the reader at that verse.
      GoRoute(
        path: '/verse',
        redirect: (context, state) {
          final id = state.uri.queryParameters['id'];
          if (id != null && parseVerseId(id) != null) {
            ref.read(readerJumpProvider.notifier).request(id);
          }
          return ref.read(settingsProvider).firstLaunchDone
              ? '/gita'
              : '/welcome';
        },
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _fadePage(state, const WelcomeScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fadePage(state, AppShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gita',
                // `?verse=<id>` becomes a jump request so repeated taps on
                // the same verse always jump.
                redirect: (context, state) {
                  final verse = state.uri.queryParameters['verse'];
                  if (verse == null) return null;
                  ref.read(readerJumpProvider.notifier).request(verse);
                  return '/gita';
                },
                builder: (context, state) => const ReaderScreen(),
                routes: [
                  GoRoute(
                    path: 'summary/:chapter',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) {
                      final n = int.tryParse(
                        state.pathParameters['chapter'] ?? '',
                      );
                      return n == null || n < 1 || n > chapterCount
                          ? '/gita'
                          : null;
                    },
                    pageBuilder: (context, state) => _risePage(
                      state,
                      SummaryScreen(
                        chapter: int.parse(state.pathParameters['chapter']!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  for (final kind in LibraryKind.values)
                    GoRoute(
                      path: kind.name,
                      builder: (context, state) =>
                          LibraryListScreen(kind: kind),
                    ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const RemindersScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                  if (kDebugMode)
                    GoRoute(
                      path: 'specimen',
                      builder: (context, state) => const SpecimenScreen(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/purport/:verseId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          PurportScreen(verseId: state.pathParameters['verseId']!),
        ),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          SearchScreen(initialQuery: state.uri.queryParameters['q']),
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Fade with a 16 px rise (fade only under reduced motion).
Page<void> _risePage(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: AppDurations.base,
  reverseTransitionDuration: AppDurations.base,
  child: child,
  transitionsBuilder: (context, animation, secondary, child) {
    final motion = Motion.of(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppCurves.standard,
    );
    final fade = FadeTransition(opacity: curved, child: child);
    if (motion.reduced) return fade;
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - curved.value)),
        child: child,
      ),
      child: fade,
    );
  },
);

Page<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: AppDurations.base,
      child: child,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
