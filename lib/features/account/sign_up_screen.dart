import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/core_providers.dart';
import '../../core/config/app_links.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../common/common_widgets.dart';
import '../first_launch/onboarding_parts.dart';
import '../first_launch/welcome_screen.dart';
import '../premium/sadhak_art.dart';
import 'sign_in_buttons.dart';

/// The last step of first launch: sign in with Apple or Google (PRD_v9
/// section 3). Owner decision (2026-11-22): this step has no "Not now";
/// signing in finishes it and the router moves on.
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    void done() => ref.read(settingsProvider.notifier).finishAccountStep();
    const total = WelcomeScreen.ownSteps + 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OnboardingBackdrop(visible: true),
            ),
            SafeArea(
              child: ContentWidth(
                child: Column(
                  children: [
                    const SizedBox(
                      height: Touch.minTarget,
                      child: Center(
                        child: OnboardingDots(index: total - 1, count: total),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.readingSide,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: StaggeredEntrance(
                                    children: [
                                      const SizedBox(height: Space.s16),
                                      const Center(
                                        child: LotusMark(
                                          size: OnboardingMetrics.lotusSmall,
                                        ),
                                      ),
                                      const SizedBox(height: Space.s16),
                                      Text(
                                        'ONE LAST STEP',
                                        textAlign: TextAlign.center,
                                        style: ui.overline,
                                      ),
                                      const SizedBox(height: Space.s8),
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          'Keep your journey safe',
                                          textAlign: TextAlign.center,
                                          style: ui.title,
                                        ),
                                      ),
                                      const SizedBox(height: Space.s12),
                                      Text(
                                        'Create your free account in one tap.',
                                        textAlign: TextAlign.center,
                                        style: ui.body(size: 16),
                                      ),
                                      const SizedBox(height: Space.s32),
                                      const OnboardingBenefit(
                                        icon: LucideIcons.shield_check,
                                        title: 'Your plans stay with you',
                                        sentence:
                                            'Sadhak and Shravan are linked '
                                            'to your account and restore on '
                                            'a new phone.',
                                      ),
                                      const SizedBox(height: Space.s16),
                                      const OnboardingBenefit(
                                        icon: LucideIcons.book_open,
                                        title: 'Reading stays free',
                                        sentence:
                                            'Every verse, translation and '
                                            'purport, with or without '
                                            'internet.',
                                      ),
                                      const SizedBox(height: Space.s16),
                                      const OnboardingBenefit(
                                        icon: LucideIcons.lock_keyhole,
                                        title: 'Private by design',
                                        sentence:
                                            'Only your name, email and '
                                            'purchase record. No tracking, '
                                            'no ads.',
                                      ),
                                      const SizedBox(height: Space.s24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.readingSide,
                        Space.s12,
                        Space.readingSide,
                        Space.s8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SignInButtons(onSignedIn: done),
                          Text(
                            'You can delete your account at any time in '
                            'Profile.',
                            textAlign: TextAlign.center,
                            style: ui.body(size: 12, color: c.textTertiary),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    launchUrl(Uri.parse(AppLinks.termsUrl)),
                                child: const Text('Terms'),
                              ),
                              Text('·', style: ui.body(color: c.textTertiary)),
                              TextButton(
                                onPressed: () =>
                                    launchUrl(Uri.parse(AppLinks.privacyUrl)),
                                child: const Text('Privacy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
