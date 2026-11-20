import 'dart:async';

import 'package:versescroll/data/purchases/purchase_gateway.dart';
import 'package:versescroll/domain/premium.dart';

/// A scriptable store for tests.
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    this.plans = const [
      SadhakPlan(
        id: SadhakProducts.yearly,
        kind: PlanKind.yearly,
        price: '₹699.00',
        rawPrice: 699,
        currencySymbol: '₹',
      ),
      SadhakPlan(
        id: SadhakProducts.lifetime,
        kind: PlanKind.lifetime,
        price: '₹1,999.00',
        rawPrice: 1999,
        currencySymbol: '₹',
      ),
    ],
    this.owned,
    this.buyResult,
  });

  List<SadhakPlan> plans;

  /// What [ownedProducts] answers (null: platform cannot say).
  Set<String>? owned;

  /// Emitted after [buy]; null emits nothing (the test drives [emit]).
  PurchaseOutcome? buyResult;

  final bought = <String>[];

  /// The account ID passed with the last [buy].
  String? lastAccountId;
  final completed = <PurchaseUpdate>[];
  int restoreCalls = 0;
  final _out = StreamController<PurchaseUpdate>.broadcast();

  void emit(PurchaseUpdate u) => _out.add(u);

  @override
  Stream<PurchaseUpdate> get updates => _out.stream;

  @override
  Future<List<SadhakPlan>> loadPlans() async => plans;

  @override
  Future<bool> buy(SadhakPlan plan, {String? accountId}) async {
    lastAccountId = accountId;
    bought.add(plan.id);
    final r = buyResult;
    if (r != null) {
      scheduleMicrotask(() => _out.add(PurchaseUpdate(plan.id, r, raw: 'x')));
    }
    return true;
  }

  @override
  Future<void> restore() async => restoreCalls++;

  @override
  Future<Set<String>?> ownedProducts() async => owned;

  @override
  Future<void> complete(PurchaseUpdate update) async => completed.add(update);

  @override
  void dispose() => _out.close();
}
