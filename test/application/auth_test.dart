import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/application/auth_providers.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/data/purchases/purchase_gateway.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/auth.dart';
import 'package:versescroll/domain/premium.dart';

import '../fakes/fake_auth_gateway.dart';
import '../fakes/fake_purchase_gateway.dart';

const _user = AppUser(
  id: '00000000-0000-4000-8000-000000000009',
  email: 'a@example.com',
  method: SignInMethod.apple,
);

Future<
  (ProviderContainer, FakeAuthGateway, FakePurchaseGateway, SettingsRepository)
>
setup({AppUser? user, FakePurchaseGateway? store}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = SettingsRepository(await SharedPreferences.getInstance());
  final auth = FakeAuthGateway(user: user);
  final g = store ?? FakePurchaseGateway();
  final c = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
      purchaseGatewayProvider.overrideWithValue(g),
      authGatewayProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(c.dispose);
  return (c, auth, g, repo);
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('domain', () {
    test('sign-up shows once, only with accounts and nobody signed in', () {
      expect(
        shouldShowSignUp(
          accountsAvailable: true,
          stepPending: true,
          signedIn: false,
        ),
        isTrue,
      );
      for (final (a, p, s) in [
        (false, true, false),
        (true, false, false),
        (true, true, true),
      ]) {
        expect(
          shouldShowSignUp(accountsAvailable: a, stepPending: p, signedIn: s),
          isFalse,
        );
      }
    });

    test('display name falls back to email, then a plain label', () {
      expect(const AppUser(id: '1', name: ' Ana ').displayName, 'Ana');
      expect(const AppUser(id: '1', email: 'a@b.c').displayName, 'a@b.c');
      expect(const AppUser(id: '1').displayName, 'Signed in');
    });

    test('provider names map to methods', () {
      expect(SignInMethod.byProvider('apple'), SignInMethod.apple);
      expect(SignInMethod.byProvider('google'), SignInMethod.google);
      expect(SignInMethod.byProvider('email'), isNull);
    });
  });

  group('settings', () {
    test(
      'first launch can ask for the account step, which is then answered',
      () async {
        final (c, _, _, repo) = await setup();
        final s = c.read(settingsProvider.notifier);
        await s.completeFirstLaunch('en', askAccount: true);
        expect(c.read(settingsProvider).accountStepPending, isTrue);
        expect(repo.load().accountStepPending, isTrue);
        await s.finishAccountStep();
        expect(c.read(settingsProvider).accountStepPending, isFalse);
        expect(repo.load().accountStepPending, isFalse);
      },
    );

    test('without accounts the step is never pending', () async {
      final (c, _, _, _) = await setup();
      await c.read(settingsProvider.notifier).completeFirstLaunch('en');
      expect(c.read(settingsProvider).accountStepPending, isFalse);
    });
  });

  group('controller', () {
    test('sign-in sets the user; cancel is quiet', () async {
      final (c, auth, _, _) = await setup();
      c.listen(authControllerProvider, (_, _) {});
      final ctrl = c.read(authControllerProvider.notifier);
      auth.signInResult = null;
      expect(await ctrl.signIn(SignInMethod.google), isFalse);
      expect(c.read(currentUserProvider), isNull);
      expect(c.read(authControllerProvider).message, isNull);

      auth.signInResult = _user;
      expect(await ctrl.signIn(SignInMethod.google), isTrue);
      expect(c.read(currentUserProvider), _user);
    });

    test('a failure shows its message', () async {
      final (c, auth, _, _) = await setup();
      c.listen(authControllerProvider, (_, _) {});
      auth.failure = const AuthFailure('No internet');
      expect(
        await c
            .read(authControllerProvider.notifier)
            .signIn(SignInMethod.apple),
        isFalse,
      );
      expect(c.read(authControllerProvider).message, 'No internet');
      expect(c.read(authControllerProvider).working, isFalse);
    });

    test('sign out and delete clear the user', () async {
      final (c, auth, _, _) = await setup(user: _user);
      c.listen(authControllerProvider, (_, _) {});
      expect(c.read(currentUserProvider), _user);
      await c.read(authControllerProvider.notifier).signOut();
      expect(c.read(currentUserProvider), isNull);
      expect(auth.signOuts, 1);

      auth.user = _user;
      c.read(currentUserProvider.notifier).set(_user);
      expect(
        await c.read(authControllerProvider.notifier).deleteAccount(),
        isTrue,
      );
      expect(c.read(currentUserProvider), isNull);
      expect(auth.deletes, 1);
    });

    test('a failed delete keeps the user and explains', () async {
      final (c, auth, _, _) = await setup(user: _user);
      c.listen(authControllerProvider, (_, _) {});
      auth.failure = const AuthFailure('Could not delete');
      expect(
        await c.read(authControllerProvider.notifier).deleteAccount(),
        isFalse,
      );
      expect(c.read(currentUserProvider), _user);
      expect(c.read(authControllerProvider).message, 'Could not delete');
    });
  });

  group('purchases', () {
    test(
      'a signed-in purchase carries the account ID and is recorded',
      () async {
        final (c, auth, g, _) = await setup(
          user: _user,
          store: FakePurchaseGateway(
            buyResult: PurchaseOutcome.purchased,
            purchaseToken: 'play-token',
          ),
        );
        c.listen(entitlementProvider, (_, _) {});
        c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
        await flush();
        await c.read(paywallControllerProvider(Package.sadhak).notifier).buy();
        await flush();
        await flush();
        expect(g.lastAccountId, _user.id);
        expect(c.read(entitlementProvider), Entitlement.premium);
        expect(auth.records.single.productId, SadhakProducts.yearly);
        // The server checks Google Play purchases with this token.
        expect(auth.records.single.purchaseToken, 'play-token');
      },
    );

    test(
      'signed out: no account ID, nothing recorded, still unlocks',
      () async {
        final (c, auth, g, _) = await setup(
          store: FakePurchaseGateway(buyResult: PurchaseOutcome.purchased),
        );
        c.listen(entitlementProvider, (_, _) {});
        c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
        await flush();
        await c.read(paywallControllerProvider(Package.sadhak).notifier).buy();
        await flush();
        await flush();
        expect(g.lastAccountId, isNull);
        expect(auth.records, isEmpty);
        expect(c.read(entitlementProvider), Entitlement.premium);
      },
    );

    test('a restore is not recorded again', () async {
      final (c, auth, g, _) = await setup(user: _user);
      c.listen(entitlementProvider, (_, _) {});
      g.emit(
        const PurchaseUpdate(
          SadhakProducts.yearly,
          PurchaseOutcome.restored,
          raw: 'x',
        ),
      );
      await flush();
      await flush();
      expect(c.read(entitlementProvider), Entitlement.premium);
      expect(auth.records, isEmpty);
    });
  });
}
