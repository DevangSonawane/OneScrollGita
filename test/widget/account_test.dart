import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/app/router.dart';
import 'package:versescroll/application/auth_providers.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/auth.dart';
import 'package:versescroll/features/account/account_screen.dart';
import 'package:versescroll/features/account/sign_in_buttons.dart';
import 'package:versescroll/features/account/sign_up_screen.dart';
import 'package:versescroll/features/home/home_screen.dart';

import '../fakes/fake_auth_gateway.dart';
import '../helpers.dart';

const _newInstall = {
  SettingsRepository.kFirstLaunch: true,
  SettingsRepository.kAccountStepPending: true,
};

void main() {
  testWidgets('a new install sees sign-up once; Not now goes Home', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      prefs: _newInstall,
      auth: FakeAuthGateway(),
    );
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Keep your purchases safe'), findsOneWidget);
    expect(find.byKey(SignInButtons.googleKey), findsOneWidget);
    // Apple shows on iOS only.
    expect(find.byKey(SignInButtons.appleKey), findsNothing);

    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.container.read(settingsProvider).accountStepPending, isFalse);
  });

  testWidgets('signing in with Google goes Home signed in', (tester) async {
    final auth = FakeAuthGateway();
    final app = await pumpApp(tester, prefs: _newInstall, auth: auth);
    await tester.tap(find.byKey(SignInButtons.googleKey));
    await settle(tester);
    expect(auth.signIns, [SignInMethod.google]);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.container.read(currentUserProvider)?.name, 'Test Reader');
  });

  testWidgets('cancelling stays quietly; a failure shows one line', (
    tester,
  ) async {
    final auth = FakeAuthGateway()..signInResult = null;
    await pumpApp(tester, prefs: _newInstall, auth: auth);
    await tester.tap(find.byKey(SignInButtons.googleKey));
    await settle(tester);
    expect(find.byType(SignUpScreen), findsOneWidget);

    auth.failure = const AuthFailure('Could not reach the sign-in service.');
    await tester.tap(find.byKey(SignInButtons.googleKey));
    await settle(tester);
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Could not reach the sign-in service.'), findsOneWidget);
  });

  testWidgets('no sign-up page without accounts, or when updating', (
    tester,
  ) async {
    // Build without Supabase keys.
    await pumpApp(tester, prefs: _newInstall);
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('existing users are not interrupted', (tester) async {
    await pumpApp(tester, auth: FakeAuthGateway());
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('sign-up survives text scale 2.0', (tester) async {
    await pumpApp(
      tester,
      prefs: _newInstall,
      auth: FakeAuthGateway(),
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('Account: sign out and delete', (tester) async {
    final auth = FakeAuthGateway(
      user: const AppUser(
        id: 'u1',
        email: 'reader@example.com',
        name: 'Test Reader',
        method: SignInMethod.google,
      ),
    );
    final app = await pumpApp(tester, auth: auth);
    app.container.read(routerProvider).go('/profile/account');
    await settle(tester);
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Test Reader'), findsOneWidget);
    expect(find.textContaining('Signed in with Google'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await settle(tester);
    expect(auth.signOuts, 1);
    expect(find.byKey(SignInButtons.googleKey), findsOneWidget);

    // Sign in again from here, then delete.
    await tester.tap(find.byKey(SignInButtons.googleKey));
    await settle(tester);
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    expect(
      find.textContaining('does not cancel a subscription'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    expect(auth.deletes, 1);
    expect(app.container.read(currentUserProvider), isNull);
  });

  testWidgets('Profile shows the Account row only with accounts', (
    tester,
  ) async {
    final app = await pumpApp(tester, auth: FakeAuthGateway());
    app.container.read(routerProvider).go('/profile');
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Account'), 300);
    expect(find.text('Optional. Link your purchases'), findsOneWidget);
  });
}
