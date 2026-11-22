import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../data/platform/quick_actions_channel.dart';
import '../core/config/audio_config.dart';
import '../domain/quick_action.dart';
import '../domain/shravan.dart';
import '../domain/verse_navigation.dart';
import 'audio_providers.dart';
import 'core_providers.dart';
import 'premium_providers.dart';
import 'scripture_providers.dart';

/// Overridden in tests.
final quickActionsChannelProvider = Provider<QuickActionsChannel>(
  (_) => QuickActionsChannel(),
);

/// A quick action that arrived as a link (Control Center controls open
/// `gitaapp://open/quick?type=<QuickAction.type>`; the router's `/quick`
/// route puts it here). Handled once, then cleared.
final pendingQuickActionProvider =
    NotifierProvider<PendingQuickAction, String?>(PendingQuickAction.new);

class PendingQuickAction extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String type) => state = type;

  void clear() => state = null;
}

/// The full-screen chapter player.
const playerRoute = '/player';

/// Where a quick action leads, as a route of the existing router. Reuses
/// the persisted reading position, the daily-verse rule, the dataset and
/// the bookmarks screen; nothing is decided here that the app does not
/// already decide elsewhere.
Future<String?> quickActionRoute(Ref ref, QuickAction action) async {
  String reader(String id) => '/gita?verse=${Uri.encodeQueryComponent(id)}';
  switch (action) {
    case QuickAction.continueReading:
      // Nothing read yet: start at the beginning (the reader's own default).
      final last = ref.read(settingsProvider).lastVerseId;
      return reader(last ?? formatVerseId(1, 1));
    case QuickAction.todaysVerse:
      return reader((await ref.read(dailyEntryProvider.future)).id);
    case QuickAction.randomVerse:
      return reader(await randomVerseId(ref));
    case QuickAction.bookmarks:
      // The bookmarks list shows its own empty state when there are none.
      return '/profile/bookmarks';
    case QuickAction.startListening:
      if (!AudioConfig.enabled) return '/home';
      // Without Shravan: the Listen library (nothing plays, no paywall
      // pushed). With it: resume where listening stopped, or chapter 1.
      if (!canListen(
        ListenFeature.recitation,
        ref.read(shravanEntitlementProvider),
      )) {
        return '/listen';
      }
      final audio = ref.read(audioControllerProvider.notifier);
      final place = audio.lastPlace;
      unawaited(
        audio.playChapter(place?.chapter ?? 1, verseId: place?.verseId),
      );
      return playerRoute;
  }
}

/// Listens to quick actions (Home Screen and Control Center) and opens them
/// with the router. Started once
/// the first frame is on screen (GitaApp).
final quickActionsProvider = Provider<void>((ref) {
  final channel = ref.watch(quickActionsChannelProvider);
  Future<void> open(String? type) async {
    final action = QuickAction.fromType(type);
    if (action == null) return;
    // During first launch the welcome flow owns the screen.
    if (!ref.read(settingsProvider).firstLaunchDone) return;
    try {
      final route = await quickActionRoute(ref, action);
      final router = ref.read(routerProvider);
      if (route == playerRoute) {
        // The player opens over the Listen tab, as it does from the app.
        router.go('/listen');
        unawaited(router.push(playerRoute));
      } else if (route != null) {
        router.go(route);
      }
    } catch (_) {
      // Data not available (should not happen offline): stay where we are.
    }
  }

  final sub = channel.actions.listen(open);
  ref.onDispose(sub.cancel);
  unawaited(channel.takeInitialAction().then(open));
  // Control Center controls (iOS 18) arrive as links through the router;
  // fireImmediately covers a link that launched the app.
  ref.listen<String?>(pendingQuickActionProvider, (_, type) {
    if (type == null) return;
    ref.read(pendingQuickActionProvider.notifier).clear();
    unawaited(open(type));
  }, fireImmediately: true);
});
