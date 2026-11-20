import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_providers.dart';
import '../../core/design/components.dart';
import '../../core/design/glass_nav_bar.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../common/common_widgets.dart';
import 'sign_in_buttons.dart';

/// Profile > Account (PRD_v9 section 3): sign in, or see the account, sign
/// out and delete it. Nothing on the phone is touched either way.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'Everything on this phone stays as it is.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete your account?',
      message:
          'Your account and its purchase record are deleted from our server. '
          'It cannot be undone. Your reading, notes and streak stay on this '
          'phone. Deleting the account does not cancel a subscription: '
          'cancel it in your App Store or Google Play settings.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final deleted = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account was deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final ui = UiStyles(c);
    final user = ref.watch(currentUserProvider);
    final auth = ref.watch(authControllerProvider);

    Widget para(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.readingSide,
        0,
        Space.readingSide,
        Space.s16,
      ),
      child: Text(text, style: ui.body()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: LucideBackButton(onPressed: () => context.go('/profile')),
      ),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.only(
            top: Space.s16,
            bottom: navBarInset(context),
          ),
          children: [
            if (user == null) ...[
              para(
                'Sign in to link Sadhak and Shravan to your account. It is '
                'optional: everything else works without it.',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Space.readingSide),
                child: SignInButtons(),
              ),
            ] else ...[
              SettingsRow(
                title: user.displayName,
                subtitle: [
                  if (user.email != null && user.email != user.displayName)
                    user.email!,
                  if (user.method != null)
                    'Signed in with ${user.method!.label}',
                ].join('\n'),
              ),
              SettingsRow(
                title: 'Sign out',
                onTap: auth.working ? null : () => _signOut(context, ref),
                showChevron: false,
              ),
              SettingsRow(
                title: auth.deleting ? 'Deleting...' : 'Delete account',
                destructive: true,
                onTap: auth.working ? null : () => _delete(context, ref),
                divider: false,
              ),
              if (auth.message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.readingSide,
                    Space.s8,
                    Space.readingSide,
                    0,
                  ),
                  child: Text(
                    auth.message!,
                    style: ui.body(size: 14, color: c.danger),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.readingSide,
                Space.s24,
                Space.readingSide,
                Space.s24,
              ),
              child: Text(
                'Your reading, notes, highlights and streak are stored only '
                'on this phone and are not synced to your account. '
                'Purchases always come back with "Restore purchase", with or '
                'without an account.',
                style: ui.body(size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
