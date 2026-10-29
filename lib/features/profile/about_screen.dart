import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../application/scripture_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../common/common_widgets.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

/// About, Credits and Sources.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final index = ref.watch(chaptersIndexProvider).value;
    final info = ref.watch(_packageInfoProvider).value;
    final source = index?.source;

    Widget para(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        0,
        Space.readingSide,
        Space.s12,
      ),
      child: Text(text, style: ui.body(color: color ?? c.textPrimary)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('About and credits'),
        leading: LucideBackButton(onPressed: () => context.go('/profile')),
      ),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.only(bottom: navBarInset(context)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.readingSide,
                Space.s16,
                Space.readingSide,
                Space.s4,
              ),
              child: Text('One Scroll Gita', style: ui.title),
            ),
            para(
              info == null
                  ? ''
                  : 'Version ${info.version} (${info.buildNumber})',
              color: c.textSecondary,
            ),
            const SectionHeader('SOURCE'),
            if (index?.isPlaceholder ?? false)
              para(
                'This build contains placeholder text for development. It is '
                'not scripture.',
                color: c.danger,
              ),
            if (source != null) ...[
              para(source.edition),
              para('Source: ${source.name}', color: c.textSecondary),
              para('Rights: ${source.rightsHolder}', color: c.textSecondary),
              para(source.attribution),
              para('Dataset ${source.datasetVersion}', color: c.textSecondary),
            ],
            const SectionHeader('PRIVACY'),
            para(
              'Works offline. No account. Your reading, streak, searches and '
              'reminder settings stay on this device.',
            ),
            para(
              'Reminders are scheduled on this phone. Nothing is sent from a '
              'server, and the app makes no network calls. Sharing only hands '
              'a picture to your phone\'s share sheet.',
            ),
            const SectionHeader('WRITTEN CONTENT'),
            para(
              'Reminder messages, chapter summaries and search themes are '
              "written for this app. They are not part of Srila Prabhupada's "
              'text.',
            ),
            const SectionHeader('FONTS'),
            for (final f in const [
              'Literata',
              'Noto Serif Devanagari',
              'Inter',
              'Tiro Devanagari Sanskrit',
            ])
              para('$f — SIL Open Font License 1.1', color: c.textSecondary),
            SettingsRow(
              title: 'Font and software licences',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'One Scroll Gita',
                applicationVersion: info?.version,
                useRootNavigator: true,
              ),
              divider: false,
            ),
          ],
        ),
      ),
    );
  }
}
