import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/purchases/purchase_gateway.dart';
import '../domain/premium.dart';
import 'core_providers.dart';

/// The store connection. Debug builds fall back to demo prices when the
/// store has no products yet. Overridden in tests.
final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  final gateway = kDebugMode
      ? DebugFallbackGateway(StorePurchaseGateway(), DemoPurchaseGateway())
      : StorePurchaseGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// What the user has: free or premium. Works offline from the cache; the
/// store only ever confirms or corrects it.
final entitlementProvider = NotifierProvider<EntitlementNotifier, Entitlement>(
  () => EntitlementNotifier(Package.sadhak),
);

/// The Shravan audio package (PRD_v4 section 7).
final shravanEntitlementProvider =
    NotifierProvider<EntitlementNotifier, Entitlement>(
      () => EntitlementNotifier(Package.shravan),
    );

/// The entitlement of either package.
NotifierProvider<EntitlementNotifier, Entitlement> entitlementOf(Package p) =>
    p == Package.sadhak ? entitlementProvider : shravanEntitlementProvider;

class EntitlementNotifier extends Notifier<Entitlement> {
  EntitlementNotifier(this.package);

  final Package package;
  StreamSubscription<PurchaseUpdate>? _sub;

  @override
  Entitlement build() {
    final gateway = ref.watch(purchaseGatewayProvider);
    _sub?.cancel();
    _sub = gateway.updates.listen(_onUpdate, onError: (_) {});
    ref.onDispose(() => _sub?.cancel());
    return _resolve();
  }

  Entitlement _resolve() {
    final repo = ref.read(settingsRepositoryProvider);
    return resolveEntitlement(
      cached: repo.cacheFor(package),
      pretendPremium: repo.pretendFor(package),
      debugBuild: kDebugMode,
    );
  }

  Future<void> _onUpdate(PurchaseUpdate u) async {
    final gateway = ref.read(purchaseGatewayProvider);
    // Each package listens to its own products only.
    if (!package.owns(u.productId)) return;
    if (u.grantsPremium) {
      // A demo purchase (debug only) flips "Pretend premium", never the
      // real cache.
      if (u.raw == null && kDebugMode) {
        await setPretendPremium(true);
      } else {
        await _save(Entitlement.premium);
      }
    }
    if (u.outcome != PurchaseOutcome.pending) {
      try {
        await gateway.complete(u);
      } catch (_) {
        // The store retries delivery; premium is already granted.
      }
    }
  }

  Future<void> _save(Entitlement e) async {
    await ref
        .read(settingsRepositoryProvider)
        .setCacheFor(package, e, ref.read(clockProvider)());
    state = _resolve();
  }

  /// On launch and resume. Google Play answers explicitly, so premium can
  /// also be removed there; the App Store only replays purchases. Any error
  /// keeps the cached state.
  Future<void> refresh() async {
    final gateway = ref.read(purchaseGatewayProvider);
    try {
      final owned = await gateway.ownedProducts();
      if (owned != null) {
        await _save(
          owned.any(package.owns) ? Entitlement.premium : Entitlement.free,
        );
      } else {
        await gateway.restore();
      }
    } catch (_) {
      // Offline or store error: trust the cache.
    }
  }

  /// Debug builds only.
  Future<void> setPretendPremium(bool v) async {
    if (!kDebugMode) return;
    await ref.read(settingsRepositoryProvider).setPretendFor(package, v);
    state = _resolve();
  }
}

final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(entitlementProvider) == Entitlement.premium,
);

// ---------------------------------------------------------------------------
// Paywall

enum PaywallStatus {
  loading,
  ready,
  unavailable,
  purchasing,
  pending,
  restoring,
  success,
  error,
}

@immutable
class PaywallState {
  const PaywallState({
    this.status = PaywallStatus.loading,
    this.plans = const [],
    this.selectedId,
    this.message,
  });

  final PaywallStatus status;
  final List<SadhakPlan> plans;
  final String? selectedId;
  final String? message;

  SadhakPlan? get selected =>
      plans.where((p) => p.id == selectedId).firstOrNull;

  bool get busy =>
      status == PaywallStatus.purchasing ||
      status == PaywallStatus.restoring ||
      status == PaywallStatus.pending;

  PaywallState copyWith({
    PaywallStatus? status,
    List<SadhakPlan>? plans,
    String? selectedId,
    String? message,
    bool clearMessage = false,
  }) => PaywallState(
    status: status ?? this.status,
    plans: plans ?? this.plans,
    selectedId: selectedId ?? this.selectedId,
    message: clearMessage ? null : (message ?? this.message),
  );
}

/// How long to wait for the App Store to replay a purchase on restore.
const restoreWait = Duration(seconds: 8);

final paywallControllerProvider =
    NotifierProvider.autoDispose.family<PaywallController, PaywallState, Package>(
      PaywallController.new,
    );

class PaywallController extends Notifier<PaywallState> {
  PaywallController(this.package);

  final Package package;
  StreamSubscription<PurchaseUpdate>? _sub;
  Completer<bool>? _restored;

  @override
  PaywallState build() {
    final gateway = ref.watch(purchaseGatewayProvider);
    _sub = gateway.updates.listen(_onUpdate, onError: (_) {});
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(load);
    return const PaywallState();
  }

  Future<void> load() async {
    state = state.copyWith(status: PaywallStatus.loading, clearMessage: true);
    List<SadhakPlan> plans;
    try {
      plans = [
        for (final p in await ref.read(purchaseGatewayProvider).loadPlans())
          if (package.owns(p.id)) p,
      ];
    } catch (_) {
      plans = const [];
    }
    if (!ref.mounted) return;
    if (plans.isEmpty) {
      state = state.copyWith(status: PaywallStatus.unavailable, plans: plans);
      return;
    }
    final yearly = plans.where((p) => p.kind == PlanKind.yearly).firstOrNull;
    state = state.copyWith(
      status: PaywallStatus.ready,
      plans: plans,
      // The recommended plan is pre-selected.
      selectedId: state.selectedId ?? (yearly ?? plans.first).id,
    );
  }

  void select(String id) {
    if (state.busy) return;
    state = state.copyWith(selectedId: id, clearMessage: true);
  }

  Future<void> buy() async {
    final plan = state.selected;
    if (plan == null || state.busy) return;
    state = state.copyWith(
      status: PaywallStatus.purchasing,
      clearMessage: true,
    );
    try {
      final started = await ref.read(purchaseGatewayProvider).buy(plan);
      if (!started && ref.mounted) {
        state = state.copyWith(
          status: PaywallStatus.error,
          message: 'The purchase could not start. Please try again.',
        );
      }
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: PaywallStatus.error,
        message: 'The purchase could not start. Please try again.',
      );
    }
  }

  Future<void> restore() async {
    if (state.busy) return;
    state = state.copyWith(status: PaywallStatus.restoring, clearMessage: true);
    final gateway = ref.read(purchaseGatewayProvider);
    var found = false;
    try {
      final owned = await gateway.ownedProducts();
      if (owned != null) {
        found = owned.any(package.owns);
        if (found) {
          await ref.read(entitlementOf(package).notifier).refresh();
        }
      } else {
        _restored = Completer<bool>();
        await gateway.restore();
        found = await _restored!.future.timeout(
          restoreWait,
          onTimeout: () => false,
        );
      }
    } catch (_) {
      found = false;
    }
    _restored = null;
    if (!ref.mounted) return;
    state = found
        ? state.copyWith(status: PaywallStatus.success)
        : state.copyWith(
            status: state.plans.isEmpty
                ? PaywallStatus.unavailable
                : PaywallStatus.ready,
            message: 'No earlier Sadhak purchase was found on this account.',
          );
  }

  void _onUpdate(PurchaseUpdate u) {
    if (!ref.mounted || !package.owns(u.productId)) return;
    switch (u.outcome) {
      case PurchaseOutcome.purchased:
        state = state.copyWith(status: PaywallStatus.success);
      case PurchaseOutcome.restored:
        if (_restored != null && !_restored!.isCompleted) {
          _restored!.complete(true);
        }
      case PurchaseOutcome.pending:
        state = state.copyWith(
          status: PaywallStatus.pending,
          message:
              'Your payment is being processed. Sadhak unlocks as soon as '
              'it is confirmed.',
        );
      case PurchaseOutcome.cancelled:
        // Silent: back to the plans.
        state = state.copyWith(status: PaywallStatus.ready, clearMessage: true);
      case PurchaseOutcome.error:
        state = state.copyWith(
          status: PaywallStatus.error,
          message: 'The purchase did not go through. Please try again.',
        );
    }
  }
}
