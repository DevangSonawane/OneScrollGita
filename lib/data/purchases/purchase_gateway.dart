import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../domain/premium.dart';

enum PurchaseOutcome { pending, purchased, restored, cancelled, error }

/// One store event for a Sadhak product.
class PurchaseUpdate {
  const PurchaseUpdate(this.productId, this.outcome, {this.message, this.raw});

  final String productId;
  final PurchaseOutcome outcome;
  final String? message;

  /// The plugin's own object, needed to complete the purchase.
  final Object? raw;

  bool get grantsPremium =>
      outcome == PurchaseOutcome.purchased ||
      outcome == PurchaseOutcome.restored;
}

/// The only code that talks to a store. Everything else goes through this.
abstract class PurchaseGateway {
  /// Broadcast stream of store events.
  Stream<PurchaseUpdate> get updates;

  /// Plans the store offers, in display order. Empty when unavailable.
  Future<List<SadhakPlan>> loadPlans();

  /// Starts a purchase; the result arrives on [updates].
  Future<bool> buy(SadhakPlan plan);

  /// Asks the store to replay earlier purchases on [updates].
  Future<void> restore();

  /// The Sadhak products the store says this account owns, when the
  /// platform can answer explicitly (Google Play). Null when it cannot
  /// (the App Store replays purchases through [restore] instead) or when the
  /// store could not be reached.
  Future<Set<String>?> ownedProducts();

  /// Tells the store the purchase was delivered.
  Future<void> complete(PurchaseUpdate update);

  void dispose() {}
}

/// Google Play and the App Store through the official `in_app_purchase`.
class StorePurchaseGateway implements PurchaseGateway {
  StorePurchaseGateway({InAppPurchase? iap}) : _iapOverride = iap;

  final InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  final _products = <String, ProductDetails>{};
  final _out = StreamController<PurchaseUpdate>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  void _listen() {
    _sub ??= _iap.purchaseStream.listen((list) {
      for (final p in list) {
        if (!SadhakProducts.all.contains(p.productID)) continue;
        _out.add(
          PurchaseUpdate(
            p.productID,
            switch (p.status) {
              PurchaseStatus.pending => PurchaseOutcome.pending,
              PurchaseStatus.purchased => PurchaseOutcome.purchased,
              PurchaseStatus.restored => PurchaseOutcome.restored,
              PurchaseStatus.canceled => PurchaseOutcome.cancelled,
              PurchaseStatus.error => PurchaseOutcome.error,
            },
            message: p.error?.message,
            raw: p,
          ),
        );
      }
    }, onError: _out.addError);
  }

  @override
  Stream<PurchaseUpdate> get updates {
    _listen();
    return _out.stream;
  }

  @override
  Future<List<SadhakPlan>> loadPlans() async {
    _listen();
    if (!await _iap.isAvailable()) return const [];
    final res = await _iap.queryProductDetails(
      SadhakProducts.forStore(
        appStore: defaultTargetPlatform == TargetPlatform.iOS,
      ),
    );
    final plans = <SadhakPlan>[];
    for (final d in res.productDetails) {
      // Subscriptions can list one entry per offer; keep the first.
      if (_products.containsKey(d.id)) continue;
      _products[d.id] = d;
      plans.add(
        SadhakPlan(
          id: d.id,
          kind: d.id == SadhakProducts.yearly
              ? PlanKind.yearly
              : PlanKind.lifetime,
          price: d.price,
          rawPrice: d.rawPrice,
          currencySymbol: d.currencySymbol,
        ),
      );
    }
    return orderPlans(plans);
  }

  @override
  Future<bool> buy(SadhakPlan plan) async {
    final d = _products[plan.id];
    if (d == null) return false;
    // Subscriptions and lifetime unlocks are both bought as non-consumables.
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: d),
    );
  }

  @override
  Future<void> restore() async {
    _listen();
    await _iap.restorePurchases();
  }

  @override
  Future<Set<String>?> ownedProducts() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    if (!await _iap.isAvailable()) return null;
    final addition = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final res = await addition.queryPastPurchases();
    if (res.error != null) return null; // unknown, keep what we had
    return {
      for (final p in res.pastPurchases)
        if (p.status == PurchaseStatus.purchased &&
            SadhakProducts.all.contains(p.productID))
          p.productID,
    };
  }

  @override
  Future<void> complete(PurchaseUpdate update) async {
    final raw = update.raw;
    if (raw is PurchaseDetails && raw.pendingCompletePurchase) {
      await _iap.completePurchase(raw);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _out.close();
  }
}

/// Debug builds only: preview prices so the paywall can be seen before the
/// store products exist. Buying "succeeds" after a short pause and only
/// switches the debug "Pretend premium" state. Never used in release.
class DemoPurchaseGateway implements PurchaseGateway {
  DemoPurchaseGateway({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;
  final _out = StreamController<PurchaseUpdate>.broadcast();

  static const plans = [
    SadhakPlan(
      id: SadhakProducts.yearly,
      kind: PlanKind.yearly,
      price: '₹699',
      rawPrice: 699,
      currencySymbol: '₹',
      isDemo: true,
    ),
    SadhakPlan(
      id: SadhakProducts.lifetime,
      kind: PlanKind.lifetime,
      price: '₹1,999',
      rawPrice: 1999,
      currencySymbol: '₹',
      isDemo: true,
    ),
  ];

  @override
  Stream<PurchaseUpdate> get updates => _out.stream;

  @override
  Future<List<SadhakPlan>> loadPlans() async => plans;

  @override
  Future<bool> buy(SadhakPlan plan) async {
    Future<void>.delayed(delay, () {
      if (!_out.isClosed) {
        _out.add(PurchaseUpdate(plan.id, PurchaseOutcome.purchased));
      }
    });
    return true;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<Set<String>?> ownedProducts() async => null;

  @override
  Future<void> complete(PurchaseUpdate update) async {}

  @override
  void dispose() => _out.close();
}

/// Debug builds: the real store when it has products, else the demo.
class DebugFallbackGateway implements PurchaseGateway {
  DebugFallbackGateway(this.store, this.demo) {
    _subs = [
      store.updates.listen(_out.add, onError: _out.addError),
      demo.updates.listen(_out.add, onError: _out.addError),
    ];
  }

  final PurchaseGateway store;
  final PurchaseGateway demo;
  final _out = StreamController<PurchaseUpdate>.broadcast();
  late final List<StreamSubscription<PurchaseUpdate>> _subs;

  @override
  Stream<PurchaseUpdate> get updates => _out.stream;

  @override
  Future<List<SadhakPlan>> loadPlans() async {
    try {
      final real = await store.loadPlans();
      if (real.isNotEmpty) return real;
    } catch (_) {}
    return demo.loadPlans();
  }

  @override
  Future<bool> buy(SadhakPlan plan) =>
      plan.isDemo ? demo.buy(plan) : store.buy(plan);

  @override
  Future<void> restore() => store.restore();

  @override
  Future<Set<String>?> ownedProducts() => store.ownedProducts();

  @override
  Future<void> complete(PurchaseUpdate update) =>
      update.raw == null ? demo.complete(update) : store.complete(update);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    store.dispose();
    demo.dispose();
    _out.close();
  }
}
