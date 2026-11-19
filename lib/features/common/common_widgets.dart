import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';

/// Opens the reader at [verseId] (PRD 5.0: every saved-verse tap does this).
void openInReader(BuildContext context, String verseId) =>
    context.go('/gita?verse=${Uri.encodeQueryComponent(verseId)}');

void openPurport(BuildContext context, String verseId) =>
    context.push('/purport/${Uri.encodeComponent(verseId)}');

void openSearch(BuildContext context, {String? query}) => context.push(
  query == null ? '/search' : '/search?q=${Uri.encodeQueryComponent(query)}',
);

/// EN | हि toggle.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.onSurface = false});

  final bool onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return SegmentedChoice<String>(
      compact: true,
      onSurface: onSurface,
      value: lang,
      choices: const [
        Choice('en', 'EN', semanticLabel: 'English translation'),
        Choice('hi', 'हि', semanticLabel: 'Hindi translation'),
      ],
      // Avoid restarting the visual transition when the selected segment is
      // tapped again.
      onChanged: (v) {
        if (v != lang) {
          ref.read(settingsProvider.notifier).setLanguage(v);
        }
      },
    );
  }
}

/// "Continue: Chapter 3, 3.12 >". Hidden when there is no saved position.
class ContinueRow extends ConsumerWidget {
  const ContinueRow({super.key, this.padding});

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(settingsProvider.select((s) => s.lastVerseId));
    if (id == null) return const SizedBox.shrink();
    final entry = ref.watch(entryProvider(id)).value;
    if (entry == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return InkWell(
      onTap: () => openInReader(context, id),
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: Space.readingSide,
              vertical: Space.s12,
            ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Touch.minTarget - 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Continue: Chapter ${entry.chapter}, ${entry.label}',
                  style: UiStyles(c).label(color: c.textTertiary, size: 15),
                ),
              ),
              Icon(LucideIcons.chevron_right, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hides the nav pill while scrolling down and shows it again on any upward
/// move (PRD_v5 section 3.2).
class NavHideOnScroll extends ConsumerWidget {
  const NavHideOnScroll({super.key, required this.child, this.minDepth = 0});

  final Widget child;

  /// Downward scrolls shallower than this do not hide the pill (the reader's
  /// own page swipes). Upward moves at any depth always show it.
  final int minDepth;

  /// Upward drag distance, in one update, that counts as intent to go back.
  static const _showSlop = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allow = Motion.of(context).allowNavHide;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!allow || n.metrics.axis != Axis.vertical) return false;
        final nav = ref.read(navBarVisibleProvider.notifier);
        if (navIntent(n, minDepth: minDepth, showSlop: _showSlop)
            case final show?) {
          show ? nav.show() : nav.hide();
        }
        return false;
      },
      child: child,
    );
  }
}

/// What a scroll notification means for the nav pill: true to show it,
/// false to hide it, null to leave it.
@visibleForTesting
bool? navIntent(
  ScrollNotification n, {
  required int minDepth,
  double showSlop = 2.0,
}) {
  final delta = switch (n) {
    ScrollUpdateNotification(dragDetails: _?, :final scrollDelta?) =>
      scrollDelta,
    _ => null,
  };
  // Dragging back up, at any depth (verse body or page swipe).
  if (delta != null && delta < -showSlop) return true;
  // Pulling down at the top edge of a verse.
  if (n is OverscrollNotification &&
      n.dragDetails != null &&
      n.overscroll < 0) {
    return true;
  }
  if (n is UserScrollNotification && n.direction == ScrollDirection.forward) {
    return true;
  }
  // Checked during the drag, so one swipe from the top also hides it.
  if (delta != null &&
      delta > 0 &&
      n.depth >= minDepth &&
      n.metrics.pixels > 24) {
    return false;
  }
  return null;
}

/// Calm load error with Retry (details only in debug).
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    var details = '';
    assert(() {
      details = error?.toString() ?? '';
      return true;
    }());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This page could not be opened.',
              style: ui.emptyTitle,
              textAlign: TextAlign.center,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: Space.s8),
              Text(details, style: ui.body(size: 12)),
            ],
            const SizedBox(height: Space.s16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Centres content at max 600 px (tablets).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Space.contentMaxWidth),
      child: child,
    ),
  );
}
