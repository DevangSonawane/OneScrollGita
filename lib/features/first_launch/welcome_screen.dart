import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../common/common_widgets.dart';

/// Shown once. Choose English or Hindi, then Begin.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String _lang = 'en';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.readingSide),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: Space.s48),
                    Semantics(
                      header: true,
                      child: Text(
                        'One Scroll Gita',
                        textAlign: TextAlign.center,
                        style: ui.title.copyWith(fontSize: 38),
                      ),
                    ),
                    const SizedBox(height: Space.s16),
                    Text(
                      'Read the Bhagavad-gita As It Is. No account. '
                      'No internet needed.',
                      textAlign: TextAlign.center,
                      style: ui.body(size: 17),
                    ),
                    const SizedBox(height: Space.s48),
                    for (final (code, label, hint) in const [
                      ('en', 'English', 'Translation in English'),
                      ('hi', 'हिन्दी', 'Translation in Hindi'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.s12),
                        child: _LanguageOption(
                          label: label,
                          hint: hint,
                          selected: _lang == code,
                          onTap: () => setState(() => _lang = code),
                        ),
                      ),
                    const SizedBox(height: Space.s32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .completeFirstLaunch(_lang),
                        child: const Text('Begin'),
                      ),
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      'You can change this later in Profile.',
                      style: ui.body(size: 13, color: c.textTertiary),
                    ),
                    const SizedBox(height: Space.s48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: hint,
      radius: Radii.card,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s24,
          vertical: Space.s16,
        ),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: selected ? c.accent : c.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ui.title.copyWith(
                  fontSize: 22,
                  fontFamily: label == 'English' ? Fonts.literata : Fonts.devanagari,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: AppDurations.fast,
              child: Icon(Icons.check_rounded, color: c.accentText),
            ),
          ],
        ),
      ),
    );
  }
}
