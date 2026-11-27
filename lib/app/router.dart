import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_providers.dart';
import '../application/core_providers.dart';
import '../application/quick_actions.dart';
import '../application/ui_providers.dart';
import '../core/design/motion.dart';
import '../core/config/audio_config.dart';
import '../core/design/tokens.dart';
import '../domain/auth.dart';
import '../domain/quick_action.dart';
import '../domain/verse_navigation.dart';
import '../features/account/account_screen.dart';
import '../features/account/sign_up_screen.dart';
import '../features/first_launch/welcome_screen.dart';
import '../features/gita/reader_screen.dart';
import '../domain/premium.dart';
import '../domain/shravan.dart';
import '../features/home/home_screen.dart';
import '../features/listen/chapter_player_screen.dart';
import '../features/listen/listen_library_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/study/journal_screens.dart';
import '../features/study/note_editor_screen.dart';
import '../features/study/notebook_export.dart';
import '../features/study/study_lists.dart';
import '../features/trainer/trainer_home_screen.dart';
import '../features/trainer/trainer_session_screen.dart';
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
    settingsProvider.select((s) => (s.firstLaunchDone, s.accountStepPending)),
    (_, _) => refresh.value++,
  );
  final accounts = ref.read(authGatewayProvider).available;

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final done = settings.firstLaunchDone;
      final atWelcome = state.matchedLocation == '/welcome';
      final atSignUp = state.matchedLocation == '/signup';
      if (!done && !atWelcome) return '/welcome';
      // The one-time sign-up page right after first launch (PRD_v9).
      final signUp = shouldShowSignUp(
        accountsAvailable: accounts,
        stepPending: settings.accountStepPending,
        signedIn: ref.read(currentUserProvider) != null,
      );
      if (done && signUp) return atSignUp ? null : '/signup';
      // A shared verse opened before first launch finishes opens after it.
      if (done && (atWelcome || atSignUp)) {
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
      // Control Center controls (iOS 18): gitaapp://open/quick?type=<type>.
      // The quick-action handler decides the destination with the app's
      // own data (lib/application/quick_actions.dart); Home meanwhile.
      // Apple's web sign-in on Android returns here
      // (gitaapp://open/login-callback?code=...). supabase_flutter turns the
      // link into a session; this only puts the user back where they were.
      GoRoute(
        path: '/login-callback',
        redirect: (context, state) {
          final s = ref.read(settingsProvider);
          return s.firstLaunchDone && !s.accountStepPending
              ? '/profile/account'
              : '/signup';
        },
      ),
      GoRoute(
        path: '/quick',
        redirect: (context, state) {
          final type = QuickAction.fromType(state.uri.queryParameters['type']);
          if (type != null) {
            ref.read(pendingQuickActionProvider.notifier).request(type.type);
          }
          return ref.read(settingsProvider).firstLaunchDone
              ? '/home'
              : '/welcome';
        },
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _fadePage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _fadePage(state, const SignUpScreen()),
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
                      pageBuilder: (context, state) =>
                          _platformPage(state, LibraryListScreen(kind: kind)),
                    ),
                  GoRoute(
                    path: 'highlights',
                    pageBuilder: (context, state) =>
                        _platformPage(state, const HighlightsScreen()),
                  ),
                  GoRoute(
                    path: 'notes',
                    pageBuilder: (context, state) =>
                        _platformPage(state, const NotesScreen()),
                  ),
                  GoRoute(
                    path: 'reminders',
                    pageBuilder: (context, state) =>
                        _platformPage(state, const RemindersScreen()),
                  ),
                  if (accounts)
                    GoRoute(
                      path: 'account',
                      pageBuilder: (context, state) =>
                          _platformPage(state, const AccountScreen()),
                    ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (context, state) =>
                        _platformPage(state, const AboutScreen()),
                  ),
                  if (kDebugMode)
                    GoRoute(
                      path: 'specimen',
                      pageBuilder: (context, state) =>
                          _platformPage(state, const SpecimenScreen()),
                    ),
                ],
              ),
            ],
          ),
          // Shravan (PRD_v4): the Listen pill's branch.
          if (AudioConfig.enabled)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/listen',
                  builder: (context, state) => const ListenLibraryScreen(),
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
        path: '/player',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _risePage(state, const ChapterPlayerScreen()),
      ),
      GoRoute(
        path: '/note/:verseId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          NoteEditorScreen(verseId: state.pathParameters['verseId']!),
        ),
      ),
      GoRoute(
        path: '/trainer',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _risePage(state, const TrainerHomeScreen()),
      ),
      GoRoute(
        path: '/trainer-learn/:verseId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          TrainerLearnScreen(verseId: state.pathParameters['verseId']!),
        ),
      ),
      GoRoute(
        path: '/trainer-review',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _risePage(state, const TrainerReviewScreen()),
      ),
      GoRoute(
        path: '/journal',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _risePage(state, const JournalScreen()),
      ),
      GoRoute(
        path: '/journal-edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          JournalEditorScreen(
            id: int.tryParse(state.uri.queryParameters['id'] ?? ''),
            verseId: state.uri.queryParameters['verse'],
          ),
        ),
      ),
      GoRoute(
        path: '/notebook',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _risePage(state, const NotebookExportScreen()),
      ),
      GoRoute(
        path: '/shravan',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          PaywallScreen(
            offer: PaywallOffer.shravan,
            reasonText: ListenFeature.values
                .where((f) => f.name == state.uri.queryParameters['reason'])
                .firstOrNull
                ?.reason,
          ),
        ),
      ),
      GoRoute(
        path: '/sadhak',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _risePage(
          state,
          PaywallScreen(
            reason: PremiumFeature.values
                .where((f) => f.name == state.uri.queryParameters['reason'])
                .firstOrNull,
          ),
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

/// Sub-pages inside a tab (Profile > Bookmarks, Reminders, About...). A
/// plain `builder` gets go_router's no-transition page here, which has no
/// iOS back swipe; this gives the native page on each platform instead.
Page<void> _platformPage(GoRouterState state, Widget child) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? CupertinoPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

/// Pushed pages. iOS: the native page route, so a swipe from the left edge
/// goes back with the page following the finger (PRD_v6 section 4).
/// Elsewhere: fade with a 16 px rise (fade only under reduced motion).
Page<void> _risePage(GoRouterState state, Widget child) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? CupertinoPage<void>(key: state.pageKey, child: child)
    : _riseTransitionPage(state, child);

Page<void> _riseTransitionPage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
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
