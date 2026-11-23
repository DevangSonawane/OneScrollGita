import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/auth.dart';
import 'brand_logos.dart';

/// "Continue with Apple" (iOS) and "Continue with Google", plus the error
/// line (PRD_v9 section 3). [onSignedIn] runs after a successful sign-in.
///
/// Both buttons follow their brand guidelines (Apple: black or white with
/// the Apple logo; Google: the four-colour G on the light or dark button)
/// and share one size, so the pair reads as one set.
class SignInButtons extends ConsumerWidget {
  const SignInButtons({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  static const appleKey = ValueKey('signInApple');
  static const googleKey = ValueKey('signInGoogle');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final methods = ref.watch(authGatewayProvider).methods;
    final auth = ref.watch(authControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Future<void> go(SignInMethod m) async {
      unawaited(HapticFeedback.lightImpact());
      final ok = await ref.read(authControllerProvider.notifier).signIn(m);
      if (ok) {
        unawaited(HapticFeedback.mediumImpact());
        onSignedIn?.call();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in methods) ...[
          switch (m) {
            SignInMethod.apple => _ProviderButton(
              key: appleKey,
              label: 'Continue with Apple',
              // Apple: white on dark backgrounds, black on light ones.
              fill: dark ? BrandColors.appleWhite : BrandColors.appleBlack,
              text: dark ? BrandColors.appleBlack : BrandColors.appleWhite,
              logo: AppleLogo(
                size: OnboardingMetrics.providerLogo,
                color: dark ? BrandColors.appleBlack : BrandColors.appleWhite,
              ),
              busy: auth.busy == SignInMethod.apple,
              onTap: auth.working ? null : () => go(SignInMethod.apple),
            ),
            SignInMethod.google => _ProviderButton(
              key: googleKey,
              label: 'Continue with Google',
              fill: dark
                  ? BrandColors.googleDarkFill
                  : BrandColors.googleLightFill,
              stroke: dark
                  ? BrandColors.googleDarkStroke
                  : BrandColors.googleLightStroke,
              text: dark
                  ? BrandColors.googleDarkText
                  : BrandColors.googleLightText,
              logo: const GoogleLogo(size: OnboardingMetrics.providerLogo),
              busy: auth.busy == SignInMethod.google,
              onTap: auth.working ? null : () => go(SignInMethod.google),
            ),
          },
          const SizedBox(height: Space.s12),
        ],
        AnimatedSize(
          duration: Motion.of(context).crossFade,
          curve: AppCurves.standard,
          child: auth.message == null
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Space.s12),
                    decoration: BoxDecoration(
                      color: c.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Radii.input),
                      border: Border.all(
                        color: c.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.circle_alert,
                          size: IconSizes.small,
                          color: c.danger,
                        ),
                        const SizedBox(width: Space.s8),
                        Expanded(
                          child: Text(
                            auth.message!,
                            style: ui.body(size: 14, color: c.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// One brand button: logo and label centred together, a spinner in the
/// logo's place while that sheet is open, dimmed while the other one is.
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    super.key,
    required this.label,
    required this.fill,
    required this.text,
    required this.logo,
    required this.busy,
    required this.onTap,
    this.stroke,
  });

  final String label;
  final Color fill;
  final Color text;
  final Color? stroke;
  final Widget logo;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = UiStyles(AppColors.of(context));
    final c = AppColors.of(context);
    return Pressable(
      // While busy the button stays at full strength; the other one dims.
      onTap: busy ? () {} : onTap,
      semanticLabel: busy ? '$label, signing in' : label,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: OnboardingMetrics.providerHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s24,
          vertical: Space.s12,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: stroke == null ? null : Border.all(color: stroke!),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: Space.s16,
              offset: const Offset(0, Space.s4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: OnboardingMetrics.providerLogo,
              child: AnimatedSwitcher(
                duration: Motion.of(context).crossFade,
                child: busy
                    ? CircularProgressIndicator(
                        key: const ValueKey('busy'),
                        strokeWidth: 2,
                        color: text,
                      )
                    : Center(key: const ValueKey('logo'), child: logo),
              ),
            ),
            const SizedBox(width: Space.s12),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: ui
                    .label(color: text, size: 16)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
