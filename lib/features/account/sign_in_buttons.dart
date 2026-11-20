import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../application/auth_providers.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/auth.dart';

/// "Continue with Apple" (iOS) and "Continue with Google", plus the error
/// line (PRD_v9 section 3). [onSignedIn] runs after a successful sign-in.
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

    Future<void> go(SignInMethod m) async {
      final ok = await ref.read(authControllerProvider.notifier).signIn(m);
      if (ok) onSignedIn?.call();
    }

    Widget spinner(Color color) => SizedBox.square(
      dimension: IconSizes.small,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );

    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in methods) ...[
          switch (m) {
            SignInMethod.apple =>
              auth.busy == SignInMethod.apple
                  ? SizedBox(
                      height: Touch.minTarget,
                      child: Center(child: spinner(c.textSecondary)),
                    )
                  // Apple's own button, as its guidelines require.
                  : SignInWithAppleButton(
                      key: appleKey,
                      text: 'Continue with Apple',
                      height: Touch.minTarget,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(Radii.pill),
                      ),
                      style: dark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                      onPressed: () {
                        if (!auth.working) go(SignInMethod.apple);
                      },
                    ),
            SignInMethod.google => OutlinedButton(
              key: googleKey,
              onPressed: auth.working ? null : () => go(SignInMethod.google),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(Touch.minTarget),
                shape: const StadiumBorder(),
                side: BorderSide(color: c.hairline),
                foregroundColor: c.textPrimary,
                textStyle: ui.label(),
              ),
              child: auth.busy == SignInMethod.google
                  ? spinner(c.textSecondary)
                  : const Text('Continue with Google'),
            ),
          },
          const SizedBox(height: Space.s12),
        ],
        if (auth.message != null)
          Semantics(
            liveRegion: true,
            child: Text(
              auth.message!,
              textAlign: TextAlign.center,
              style: ui.body(size: 14, color: c.danger),
            ),
          ),
      ],
    );
  }
}
