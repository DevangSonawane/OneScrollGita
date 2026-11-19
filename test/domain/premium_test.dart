import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/domain/premium.dart';
import 'package:versescroll/domain/shravan.dart';

void main() {
  group('canUse', () {
    test('premium can use everything', () {
      for (final f in PremiumFeature.values) {
        expect(
          canUse(f, Entitlement.premium, verseId: 'bg-01-001', notesCount: 99),
          isTrue,
        );
      }
    });

    test('free trainer: only the free verses', () {
      for (final id in FreeLimits.trainerVerses) {
        expect(
          canUse(PremiumFeature.trainerAnyVerse, Entitlement.free, verseId: id),
          isTrue,
        );
        expect(
          canUse(PremiumFeature.trainerReviews, Entitlement.free, verseId: id),
          isTrue,
        );
      }
      expect(
        canUse(
          PremiumFeature.trainerAnyVerse,
          Entitlement.free,
          verseId: 'bg-01-001',
        ),
        isFalse,
      );
      expect(canUse(PremiumFeature.trainerAnyVerse, Entitlement.free), isFalse);
    });

    test('free notes stop at the limit', () {
      expect(
        canUse(
          PremiumFeature.unlimitedNotes,
          Entitlement.free,
          notesCount: FreeLimits.maxNotes - 1,
        ),
        isTrue,
      );
      expect(
        canUse(
          PremiumFeature.unlimitedNotes,
          Entitlement.free,
          notesCount: FreeLimits.maxNotes,
        ),
        isFalse,
      );
    });

    test('journal and export are paid', () {
      expect(canUse(PremiumFeature.journal, Entitlement.free), isFalse);
      expect(canUse(PremiumFeature.notebookExport, Entitlement.free), isFalse);
    });

    test('every feature has a reason line', () {
      for (final f in PremiumFeature.values) {
        expect(f.reason, contains('Sadhak'));
      }
    });
  });

  group('resolveEntitlement', () {
    test('Pretend premium only counts in debug builds', () {
      expect(
        resolveEntitlement(
          cached: Entitlement.free,
          pretendPremium: true,
          debugBuild: false,
        ),
        Entitlement.free,
      );
      expect(
        resolveEntitlement(
          cached: Entitlement.free,
          pretendPremium: true,
          debugBuild: true,
        ),
        Entitlement.premium,
      );
      expect(
        resolveEntitlement(
          cached: Entitlement.premium,
          pretendPremium: false,
          debugBuild: false,
        ),
        Entitlement.premium,
      );
    });
  });

  group('SadhakPlan', () {
    SadhakPlan plan(PlanKind k, double raw, {String sym = '₹'}) => SadhakPlan(
      id: k == PlanKind.yearly
          ? SadhakProducts.yearly
          : SadhakProducts.lifetime,
      kind: k,
      price: 'x',
      rawPrice: raw,
      currencySymbol: sym,
    );

    test('per-month from the store numbers', () {
      expect(plan(PlanKind.yearly, 699).perMonth, '₹58');
      expect(plan(PlanKind.yearly, 59.99, sym: r'$').perMonth, r'$5.00');
      expect(plan(PlanKind.lifetime, 1999).perMonth, isNull);
      expect(plan(PlanKind.yearly, 0).perMonth, isNull);
      expect(plan(PlanKind.yearly, 699, sym: '').perMonth, isNull);
    });

    test('yearly is shown first', () {
      final ordered = orderPlans([
        plan(PlanKind.lifetime, 1999),
        plan(PlanKind.yearly, 699),
      ]);
      expect(ordered.map((p) => p.kind), [PlanKind.yearly, PlanKind.lifetime]);
    });
  });

  test('both stores lifetime ids are queried and recognised', () {
    expect(SadhakProducts.all, {
      'sadhak_yearly',
      'sadhak_lifetime',
      'sadhak_lifetime_ios',
    });
  });

  test('each store asks only for its own lifetime id', () {
    expect(SadhakProducts.forStore(appStore: true), {
      'sadhak_yearly',
      'sadhak_lifetime_ios',
    });
    expect(SadhakProducts.forStore(appStore: false), {
      'sadhak_yearly',
      'sadhak_lifetime',
    });
  });

  group('packages', () {
    test('products belong to one package each', () {
      expect(packageOf(SadhakProducts.yearly), Package.sadhak);
      expect(packageOf(ShravanProducts.lifetimeAppStore), Package.shravan);
      expect(packageOf('other'), isNull);
      expect(ShravanProducts.forStore(appStore: false), {
        ShravanProducts.lifetime,
      });
      expect(planKindOf(SadhakProducts.lifetimeAppStore), PlanKind.lifetime);
    });

    test('every part of Listen needs Shravan', () {
      for (final f in ListenFeature.values) {
        expect(canListen(f, Entitlement.free), isFalse);
        expect(canListen(f, Entitlement.premium), isTrue);
        expect(f.reason, contains('Shravan'));
      }
    });
  });
}
