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

/// Hides the nav pill while scrolling down and shows it on scroll up.
class NavHideOnScroll extends ConsumerWidget {
  const NavHideOnScroll({super.key, required this.child, this.minDepth = 0});

  final Widget child;

  /// Ignore scrolls shallower than this (the reader's own page swipes).
  final int minDepth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allow = Motion.of(context).allowNavHide;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!allow || n.metrics.axis != Axis.vertical || n.depth < minDepth) {
          return false;
        }
        final nav = ref.read(navBarVisibleProvider.notifier);
        // Checked during the drag, so one swipe from the top also hides it.
        if (n is ScrollUpdateNotification &&
            n.dragDetails != null &&
            (n.scrollDelta ?? 0) > 0 &&
            n.metrics.pixels > 24) {
          nav.hide();
        } else if (n is UserScrollNotification &&
            n.direction == ScrollDirection.forward) {
          nav.show();
        }
        return false;
      },
      child: child,
    );
  }
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
