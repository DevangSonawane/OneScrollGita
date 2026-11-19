import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versescroll/application/core_providers.dart';
import 'package:versescroll/application/premium_providers.dart';
import 'package:versescroll/data/purchases/purchase_gateway.dart';
import 'package:versescroll/data/settings/settings_repository.dart';
import 'package:versescroll/domain/premium.dart';

import '../fakes/fake_purchase_gateway.dart';

Future<(ProviderContainer, FakePurchaseGateway, SettingsRepository)> setup({
  Map<String, Object> prefs = const {},
  FakePurchaseGateway? gateway,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final repo = SettingsRepository(await SharedPreferences.getInstance());
  final g = gateway ?? FakePurchaseGateway();
  final c = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
      purchaseGatewayProvider.overrideWithValue(g),
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 12, 9)),
    ],
  );
  addTearDown(c.dispose);
  return (c, g, repo);
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('entitlement', () {
    test('starts from the cache, so it works offline', () async {
      final (c, _, _) = await setup(
        prefs: {SettingsRepository.kEntitlementCache: 'premium'},
      );
      expect(c.read(entitlementProvider), Entitlement.premium);
    });

    test('a purchase grants premium, is cached and completed', () async {
      final (c, g, repo) = await setup();
      expect(c.read(entitlementProvider), Entitlement.free);
      g.emit(
        const PurchaseUpdate(
          SadhakProducts.yearly,
          PurchaseOutcome.purchased,
          raw: 'x',
        ),
      );
      await flush();
      await flush();
      expect(c.read(entitlementProvider), Entitlement.premium);
      expect(repo.entitlementCache, Entitlement.premium);
      expect(repo.entitlementCheckedAt, DateTime(2026, 11, 12, 9));
      expect(g.completed, hasLength(1));
    });

    test('pending is not completed and grants nothing', () async {
      final (c, g, _) = await setup();
      c.read(entitlementProvider);
      g.emit(
        const PurchaseUpdate(
          SadhakProducts.yearly,
          PurchaseOutcome.pending,
          raw: 'x',
        ),
      );
      await flush();
      expect(c.read(entitlementProvider), Entitlement.free);
      expect(g.completed, isEmpty);
    });

    test('Google Play answering "nothing owned" removes premium', () async {
      final (c, _, repo) = await setup(
        prefs: {SettingsRepository.kEntitlementCache: 'premium'},
        gateway: FakePurchaseGateway(owned: {}),
      );
      await c.read(entitlementProvider.notifier).refresh();
      expect(c.read(entitlementProvider), Entitlement.free);
      expect(repo.entitlementCache, Entitlement.free);
    });

    test('when the platform cannot say, the cache is kept and restore '
        'is asked', () async {
      final (c, g, _) = await setup(
        prefs: {SettingsRepository.kEntitlementCache: 'premium'},
        gateway: FakePurchaseGateway(owned: null),
      );
      await c.read(entitlementProvider.notifier).refresh();
      expect(c.read(entitlementProvider), Entitlement.premium);
      expect(g.restoreCalls, 1);
    });

    test('Pretend premium works in debug test builds and is separate from '
        'the cache', () async {
      final (c, _, repo) = await setup();
      await c.read(entitlementProvider.notifier).setPretendPremium(true);
      expect(c.read(entitlementProvider), Entitlement.premium);
      expect(repo.entitlementCache, Entitlement.free);
    });

    test('reset all saved data keeps the purchase', () async {
      final (_, _, repo) = await setup(
        prefs: {SettingsRepository.kEntitlementCache: 'premium'},
      );
      await repo.clearAll();
      expect(repo.entitlementCache, Entitlement.premium);
    });
  });

  group('paywall controller', () {
    test('loads plans and pre-selects yearly', () async {
      final (c, _, _) = await setup();
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      final s = c.read(paywallControllerProvider(Package.sadhak));
      expect(s.status, PaywallStatus.ready);
      expect(s.selectedId, SadhakProducts.yearly);
    });

    test('no plans means unavailable', () async {
      final (c, _, _) = await setup(gateway: FakePurchaseGateway(plans: []));
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      expect(
        c.read(paywallControllerProvider(Package.sadhak)).status,
        PaywallStatus.unavailable,
      );
    });

    test('buy, then success', () async {
      final (c, g, _) = await setup(
        gateway: FakePurchaseGateway(buyResult: PurchaseOutcome.purchased),
      );
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      c
          .read(paywallControllerProvider(Package.sadhak).notifier)
          .select(SadhakProducts.lifetime);
      await c.read(paywallControllerProvider(Package.sadhak).notifier).buy();
      await flush();
      expect(g.bought, [SadhakProducts.lifetime]);
      expect(c.read(paywallControllerProvider(Package.sadhak)).status, PaywallStatus.success);
    });

    test('cancel goes quietly back to the plans', () async {
      final (c, _, _) = await setup(
        gateway: FakePurchaseGateway(buyResult: PurchaseOutcome.cancelled),
      );
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      await c.read(paywallControllerProvider(Package.sadhak).notifier).buy();
      await flush();
      final s = c.read(paywallControllerProvider(Package.sadhak));
      expect(s.status, PaywallStatus.ready);
      expect(s.message, isNull);
    });

    test('pending explains itself', () async {
      final (c, _, _) = await setup(
        gateway: FakePurchaseGateway(buyResult: PurchaseOutcome.pending),
      );
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      await c.read(paywallControllerProvider(Package.sadhak).notifier).buy();
      await flush();
      final s = c.read(paywallControllerProvider(Package.sadhak));
      expect(s.status, PaywallStatus.pending);
      expect(s.busy, isTrue);
      expect(s.message, contains('being processed'));
    });

    test('restore with nothing owned says so', () async {
      final (c, _, _) = await setup(gateway: FakePurchaseGateway(owned: {}));
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      await c.read(paywallControllerProvider(Package.sadhak).notifier).restore();
      final s = c.read(paywallControllerProvider(Package.sadhak));
      expect(s.status, PaywallStatus.ready);
      expect(s.message, contains('No earlier Sadhak purchase'));
    });

    test('restore that finds the purchase succeeds', () async {
      final (c, _, repo) = await setup(
        gateway: FakePurchaseGateway(owned: {SadhakProducts.lifetime}),
      );
      c.listen(paywallControllerProvider(Package.sadhak), (_, _) {});
      await flush();
      await c.read(paywallControllerProvider(Package.sadhak).notifier).restore();
      expect(c.read(paywallControllerProvider(Package.sadhak)).status, PaywallStatus.success);
      expect(repo.entitlementCache, Entitlement.premium);
    });
  });
}
