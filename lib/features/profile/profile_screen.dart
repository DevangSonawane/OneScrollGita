import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/premium_providers.dart';
import '../../application/study_providers.dart';
import '../../application/reminder_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/premium.dart';
import '../../domain/trainer/trainer.dart';
import '../../application/streak_providers.dart';
import '../common/common_widgets.dart';
import '../premium/sadhak_card.dart';
import '../study/journal_screens.dart';
import '../study/notebook_export.dart';
import '../trainer/trainer_entry.dart';
import '../streak/streak_card.dart';
import '../purport/purport_screen.dart' show TextSizeSlider;

/// Profile (PRD 5.7): a quiet local library plus settings. No account.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(tabReselectProvider, (_, next) {
      if (next.tab == 2 && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: AppDurations.base,
          curve: AppCurves.position,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _clearHistory() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear your reading history?',
      message: 'Favourites and bookmarks are kept.',
      confirmLabel: 'Clear',
    );
    if (ok) await ref.read(libraryControllerProvider.notifier).clearHistory();
  }

  Future<void> _clearSearchHistory() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear your search history?',
      message: 'Recent searches are removed from this phone.',
      confirmLabel: 'Clear',
    );
    if (ok) await ref.read(activityRepositoryProvider).clearSearchHistory();
  }

  String _trainerSubtitle(WidgetRef ref) {
    final due = ref.watch(dueReviewsProvider).length;
    final learned = (ref.watch(shlokaProgressProvider).value ?? const [])
        .where((s) => s.status != ShlokaStatus.learning)
        .length;
    if (due > 0) return due == 1 ? '1 review due' : '$due reviews due';
    if (learned > 0) {
      return learned == 1 ? '1 verse learned' : '$learned verses learned';
    }
    return 'Learn verses by heart';
  }

  Widget? _lockIf(bool locked, AppColors c) => locked
      ? Icon(LucideIcons.lock, size: IconSizes.small - 2, color: c.textTertiary)
      : null;

  Future<void> _setPretend(bool v) =>
      ref.read(entitlementProvider.notifier).setPretendPremium(v);

  Future<void> _resetAll() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset all saved data?',
      message:
          'This removes your favourites, bookmarks, reading history, '
          'reading streak, reminders, search history, notes, highlights, '
          'journal, learning progress, settings and resume position from '
          'this phone. It cannot be undone. A Sadhak purchase is kept.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (ok) await ref.read(libraryControllerProvider.notifier).resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    int count(AsyncValue<List<Object>> v) => v.value?.length ?? 0;
    // Rebuilds when the entitlement changes, so the debug switch follows it.
    ref.watch(entitlementProvider);
    final isPremium = ref.watch(isPremiumProvider);
    ref.watch(shravanEntitlementProvider);
    final pretendShravan =
        kDebugMode &&
        ref.read(settingsRepositoryProvider).pretendFor(Package.shravan);
    final pretendPremium =
        kDebugMode && ref.read(settingsRepositoryProvider).pretendPremium;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NavHideOnScroll(
          child: ContentWidth(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.only(bottom: navBarInset(context)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.readingSide,
                    Space.s16,
                    Space.readingSide,
                    0,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Your library',
                      style: ui.title.copyWith(fontSize: 25),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.readingSide,
                  ),
                  child: Text(
                    'Saved on this device only',
                    style: ui.body(size: 14),
                  ),
                ),
                const SizedBox(height: Space.s12),
                const StreakCard(),
                const SizedBox(height: Space.s12),
                const SadhakCard(),
                const SizedBox(height: Space.s8),
                const ContinueRow(),
                const SizedBox(height: Space.s8),
                for (final (label, path, n) in [
                  (
                    'Favourites',
                    'favourites',
                    count(ref.watch(favouritesProvider)),
                  ),
                  (
                    'Bookmarks',
                    'bookmarks',
                    count(ref.watch(bookmarksProvider)),
                  ),
                  ('History', 'history', count(ref.watch(historyProvider))),
                ])
                  SettingsRow(
                    title: label,
                    trailing: Text(
                      '$n',
                      style: ui.label(color: c.textSecondary),
                    ),
                    onTap: () => context.go('/profile/$path'),
                  ),
                const _ProfileSectionHeader('STUDY'),
                SettingsRow(
                  title: 'Shloka trainer',
                  subtitle: _trainerSubtitle(ref),
                  onTap: () => openTrainerHome(context),
                ),
                SettingsRow(
                  title: 'Highlights',
                  trailing: Text(
                    '${count(ref.watch(highlightsProvider))}',
                    style: ui.label(color: c.textSecondary),
                  ),
                  onTap: () => context.go('/profile/highlights'),
                ),
                SettingsRow(
                  title: 'My notes',
                  trailing: Text(
                    '${count(ref.watch(notesProvider))}',
                    style: ui.label(color: c.textSecondary),
                  ),
                  onTap: () => context.go('/profile/notes'),
                ),
                SettingsRow(
                  title: 'Journal',
                  trailing: _lockIf(!isPremium, c),
                  onTap: () => openJournal(context, ref),
                ),
                SettingsRow(
                  title: 'Export my Gita notebook',
                  subtitle: 'Notes, highlights and journal as a PDF',
                  trailing: _lockIf(!isPremium, c),
                  onTap: () => openNotebookExport(context, ref),
                  divider: false,
                ),
                const _ProfileSectionHeader('READING'),
                SettingsRow(
                  title: 'Translation',
                  below: SegmentedChoice<String>(
                    value: settings.languageCode,
                    choices: const [
                      Choice('en', 'English'),
                      Choice('hi', 'हिन्दी', semanticLabel: 'Hindi'),
                    ],
                    onChanged: notifier.setLanguage,
                  ),
                ),
                SettingsRow(
                  title: 'Theme',
                  below: SegmentedChoice<AppThemeMode>(
                    value: settings.themeMode,
                    choices: const [
                      Choice(AppThemeMode.system, 'System'),
                      Choice(AppThemeMode.light, 'Light'),
                      Choice(AppThemeMode.dark, 'Dark'),
                    ],
                    onChanged: notifier.setThemeMode,
                  ),
                ),
                SettingsRow(
                  title: 'Text size',
                  below: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextSizeSlider(
                        step: settings.textScaleStep,
                        onChanged: notifier.setTextScaleStep,
                      ),
                      Text(
                        'Reading text will look like this.',
                        style: ReadingStyles(
                          c,
                          settings.readingScale,
                        ).translation('en'),
                      ),
                    ],
                  ),
                ),
                SettingsRow(
                  title: 'Reminders',
                  subtitle:
                      ref.watch(
                        reminderControllerProvider.select(
                          (r) => r.settings.remindersEnabled,
                        ),
                      )
                      ? 'On'
                      : 'Off',
                  onTap: () => context.go('/profile/reminders'),
                ),
                SettingsRow(
                  title: 'Simplified glass',
                  subtitle: 'Solid controls instead of glass',
                  trailing: Switch(
                    value: settings.simplifiedGlass,
                    onChanged: notifier.setSimplifiedGlass,
                  ),
                  onTap: () =>
                      notifier.setSimplifiedGlass(!settings.simplifiedGlass),
                  showChevron: false,
                  divider: false,
                ),
                const _ProfileSectionHeader('ABOUT'),
                SettingsRow(
                  title: 'About and credits',
                  onTap: () => context.go('/profile/about'),
                  divider: kDebugMode,
                ),
                if (kDebugMode) ...[
                  SettingsRow(
                    title: 'Typography specimen (debug)',
                    onTap: () => context.go('/profile/specimen'),
                  ),
                  SettingsRow(
                    title: 'Pretend Shravan (debug)',
                    subtitle: 'Unlocks Listen in debug builds only.',
                    trailing: Switch(
                      value: pretendShravan,
                      onChanged: (v) => ref
                          .read(shravanEntitlementProvider.notifier)
                          .setPretendPremium(v),
                    ),
                    onTap: () => ref
                        .read(shravanEntitlementProvider.notifier)
                        .setPretendPremium(!pretendShravan),
                    showChevron: false,
                  ),
                  SettingsRow(
                    title: 'Pretend premium (debug)',
                    subtitle: 'Debug builds only. Never in release.',
                    trailing: Switch(
                      value: pretendPremium,
                      onChanged: _setPretend,
                    ),
                    onTap: () => _setPretend(!pretendPremium),
                    showChevron: false,
                    divider: false,
                  ),
                ],
                const _ProfileSectionHeader('YOUR DATA'),
                SettingsRow(
                  title: 'Clear reading history',
                  subtitle: 'Your reading streak is kept',
                  onTap: _clearHistory,
                  showChevron: false,
                ),
                SettingsRow(
                  title: 'Clear search history',
                  onTap: _clearSearchHistory,
                  showChevron: false,
                ),
                SettingsRow(
                  title: 'Reset all saved data',
                  destructive: true,
                  onTap: _resetAll,
                  divider: false,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.readingSide,
                    Space.s8,
                    Space.readingSide,
                    Space.s24,
                  ),
                  child: Text(
                    'Your favourites, bookmarks, history, streak and searches '
                    'are stored only on this phone and are not synced. '
                    'Uninstalling the app removes them.',
                    style: ui.body(size: 13),
                  ),
                ),
                const _Credits(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Credits for the scripture text, from the dataset's source block.
class _Credits extends ConsumerWidget {
  const _Credits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final index = ref.watch(chaptersIndexProvider).value;
    if (index == null) return const SizedBox.shrink();
    final source = index.source;
    Widget line(String text, {Color? color, double size = 13}) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        0,
        Space.readingSide,
        Space.s8,
      ),
      child: Text(
        text,
        style: ui.body(size: size, color: color),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProfileSectionHeader('CREDITS'),
        line(source.edition, color: c.textPrimary, size: 15),
        line('Text from ${source.name}.'),
        line(source.attribution),
        const SizedBox(height: Space.s16),
      ],
    );
  }
}

/// Tighter section rhythm for the settings-heavy Profile screen.
class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionHeader(
    text,
    padding: const EdgeInsets.fromLTRB(
      Space.readingSide,
      Space.s16,
      Space.readingSide,
      Space.s4,
    ),
  );
}
