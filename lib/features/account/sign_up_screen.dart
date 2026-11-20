import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../../application/core_providers.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../common/common_widgets.dart';
import 'sign_in_buttons.dart';

/// The one-time, skippable sign-up page after first launch (PRD_v9
/// section 3). Answering it (either way) lets the router move on.
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final working = ref.watch(authControllerProvider.select((s) => s.working));
    void done() => ref.read(settingsProvider.notifier).finishAccountStep();

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.readingSide,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Space.s32),
                    Semantics(
                      header: true,
                      child: Text(
                        'Keep your purchases safe',
                        textAlign: TextAlign.center,
                        style: ui.title,
                      ),
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      'Sign in to link Sadhak and Shravan to your account. '
                      'It is optional: reading, notes and your streak stay '
                      'on this phone and work without it.',
                      textAlign: TextAlign.center,
                      style: ui.body(),
                    ),
                    const SizedBox(height: Space.s32),
                    SignInButtons(onSignedIn: done),
                    const SizedBox(height: Space.s8),
                    TextButton(
                      onPressed: working ? null : done,
                      child: const Text('Not now'),
                    ),
                    const SizedBox(height: Space.s16),
                    Text(
                      'We keep only your name, email and purchase record. '
                      'No tracking. You can delete your account at any time '
                      'in Profile.',
                      textAlign: TextAlign.center,
                      style: ui.body(size: 13, color: c.textTertiary),
                    ),
                    const SizedBox(height: Space.s32),
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
