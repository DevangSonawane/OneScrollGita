import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/core_providers.dart';
import '../../application/library_providers.dart';
import '../../application/scripture_providers.dart';
import '../../application/ui_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models/app_settings.dart';
import '../common/common_widgets.dart';
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
        _scroll.animateTo(0, duration: AppDurations.base, curve: AppCurves.position);
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

  Future<void> _resetAll() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset all saved data?',
      message:
          'This removes your favourites, bookmarks, reading history, '
          'settings and resume position from this phone. It cannot be undone.',
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
                    Space.s24,
                    Space.readingSide,
                    Space.s4,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text('Your library', style: ui.title),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.readingSide,
                  ),
                  child: Text('Saved on this device only', style: ui.body()),
                ),
                const SizedBox(height: Space.s16),
                const ContinueRow(),
                const SizedBox(height: Space.s8),
                for (final (label, path, n) in [
                  ('Favourites', 'favourites', count(ref.watch(favouritesProvider))),
                  ('Bookmarks', 'bookmarks', count(ref.watch(bookmarksProvider))),
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
                const SectionHeader('READING'),
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
                  title: 'Simplified glass',
                  subtitle: 'Solid controls instead of glass',
                  trailing: Switch(
                    value: settings.simplifiedGlass,
                    onChanged: notifier.setSimplifiedGlass,
                  ),
                  onTap: () => notifier.setSimplifiedGlass(
                    !settings.simplifiedGlass,
                  ),
                  showChevron: false,
                  divider: false,
                ),
                const SectionHeader('ABOUT'),
                SettingsRow(
                  title: 'About and credits',
                  onTap: () => context.go('/profile/about'),
                  divider: kDebugMode,
                ),
                if (kDebugMode)
                  SettingsRow(
                    title: 'Typography specimen (debug)',
                    onTap: () => context.go('/profile/specimen'),
                    divider: false,
                  ),
                const SectionHeader('YOUR DATA'),
                SettingsRow(
                  title: 'Clear reading history',
                  onTap: _clearHistory,
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
                    'Your favourites, bookmarks and history are stored only '
                    'on this phone and are not synced. Uninstalling the app '
                    'removes them.',
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
      child: Text(text, style: ui.body(size: size, color: color)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('CREDITS'),
        line(source.edition, color: c.textPrimary, size: 15),
        line('Text from ${source.name}.'),
        line(source.attribution),
        const SizedBox(height: Space.s16),
      ],
    );
  }
}
