/// The Sadhak plan: what is free, what is paid, and every free limit in one
/// place (PRD_v3 section 3). Pure Dart.
///
/// Scripture is never gated here: verses, translations, purports, word
/// meanings, search, summaries, streaks and the daily verse are always free,
/// so they have no [PremiumFeature] at all.
library;

enum Entitlement { free, premium }

/// Things the Sadhak plan unlocks. Screens ask [canUse]; they never look at
/// products or prices.
enum PremiumFeature {
  trainerAnyVerse,
  trainerReviews,
  unlimitedNotes,
  journal,
  notebookExport,
}

/// One-line reason shown at the top of the paywall when it opens from a
/// locked feature.
extension PremiumFeatureCopy on PremiumFeature {
  String get reason => switch (this) {
    PremiumFeature.trainerAnyVerse =>
      'Learning every shloka by heart is part of Sadhak',
    PremiumFeature.trainerReviews =>
      'Spaced reviews for every shloka are part of Sadhak',
    PremiumFeature.unlimitedNotes => 'Unlimited notes are part of Sadhak',
    PremiumFeature.journal => 'Your reflection journal is part of Sadhak',
    PremiumFeature.notebookExport => 'Your Gita notebook PDF is part of Sadhak',
  };
}

/// Free limits. Change them here only.
abstract final class FreeLimits {
  /// Verses a free user can learn in the shloka trainer (owner may swap).
  static const trainerVerses = {'bg-02-047', 'bg-04-007', 'bg-18-066'};

  /// Notes a free user can create. Existing notes always stay editable.
  static const maxNotes = 10;
}

/// Whether [feature] may be used now.
///
/// [verseId] is the verse for trainer features; [notesCount] is how many
/// notes the user already has (for creating a new one).
bool canUse(
  PremiumFeature feature,
  Entitlement entitlement, {
  String? verseId,
  int notesCount = 0,
}) {
  if (entitlement == Entitlement.premium) return true;
  return switch (feature) {
    PremiumFeature.trainerAnyVerse ||
    PremiumFeature.trainerReviews => FreeLimits.trainerVerses.contains(verseId),
    PremiumFeature.unlimitedNotes => notesCount < FreeLimits.maxNotes,
    PremiumFeature.journal || PremiumFeature.notebookExport => false,
  };
}

/// The entitlement the app acts on. The debug "Pretend premium" switch only
/// counts in debug builds; release builds always use the cached store state.
Entitlement resolveEntitlement({
  required Entitlement cached,
  required bool pretendPremium,
  required bool debugBuild,
}) => debugBuild && pretendPremium ? Entitlement.premium : cached;

/// Store product ids (PRD_v3 section 2).
abstract final class SadhakProducts {
  static const yearly = 'sadhak_yearly';

  /// Lifetime unlock on Google Play.
  static const lifetime = 'sadhak_lifetime';

  /// Lifetime unlock on the App Store. Apple never frees a deleted product
  /// id, and `sadhak_lifetime` was taken there (2026-11-13). Each store
  /// ignores the other store's id when queried.
  static const lifetimeAppStore = 'sadhak_lifetime_ios';

  static const all = {yearly, lifetime, lifetimeAppStore};

  /// The ids to show on the paywall for one store. The App Store still
  /// returns the old `sadhak_lifetime` product, so asking for [all] there
  /// listed two lifetime plans.
  static Set<String> forStore({required bool appStore}) => {
    yearly,
    appStore ? lifetimeAppStore : lifetime,
  };
}

/// Shravan, the audio package (PRD_v4 section 7): a monthly or yearly
/// subscription that unlocks the whole Listen section (owner, 2026-11-21).
/// Same ids on both stores.
abstract final class ShravanProducts {
  static const monthly = 'shravan_monthly';
  static const yearly = 'shravan_yearly';

  /// The earlier one-time product. No longer sold, but still recognised so a
  /// tester who bought it keeps Shravan.
  static const lifetime = 'shravan_lifetime';
  static const lifetimeAppStore = 'shravan_lifetime_ios';

  static const all = {monthly, yearly, lifetime, lifetimeAppStore};

  static Set<String> forStore({required bool appStore}) => {monthly, yearly};
}

/// The two things a user can buy.
enum Package {
  sadhak,
  shravan;

  Set<String> get products =>
      this == sadhak ? SadhakProducts.all : ShravanProducts.all;

  Set<String> forStore({required bool appStore}) => this == sadhak
      ? SadhakProducts.forStore(appStore: appStore)
      : ShravanProducts.forStore(appStore: appStore);

  bool owns(String productId) => products.contains(productId);
}

/// Every product id the app sells.
final allProductIds = {...SadhakProducts.all, ...ShravanProducts.all};

/// The package a product belongs to (null for unknown ids).
Package? packageOf(String productId) =>
    Package.values.where((p) => p.owns(productId)).firstOrNull;

PlanKind planKindOf(String productId) => productId.endsWith('_yearly')
    ? PlanKind.yearly
    : productId.endsWith('_monthly')
    ? PlanKind.monthly
    : PlanKind.lifetime;

enum PlanKind { yearly, monthly, lifetime }

/// A plan as the store describes it. [price] is the store's localised price
/// string; the app never makes up a price.
class SadhakPlan {
  const SadhakPlan({
    required this.id,
    required this.kind,
    required this.price,
    required this.rawPrice,
    required this.currencySymbol,
    this.isDemo = false,
    this.trial,
  });

  /// The store's introductory free trial for this account, if it offers one
  /// (PRD_v5 section 6). Never invented by the app.
  final FreeTrial? trial;

  final String id;
  final PlanKind kind;
  final String price;
  final double rawPrice;
  final String currencySymbol;

  /// Debug-build preview prices when no store is reachable. Never shipped.
  final bool isDemo;

  /// The yearly price per month, e.g. "₹58", from the store's own numbers.
  /// Null for lifetime or when the store gives no usable number.
  String? get perMonth {
    if (kind != PlanKind.yearly || rawPrice <= 0 || currencySymbol.isEmpty) {
      return null;
    }
    final m = rawPrice / 12;
    return '$currencySymbol${m.toStringAsFixed(m >= 10 ? 0 : 2)}';
  }
}

enum TrialUnit { day, week, month }

/// A free introductory period, as the store describes it.
class FreeTrial {
  const FreeTrial(this.count, this.unit);

  final int count;
  final TrialUnit unit;

  /// "7 days free", "1 month free".
  String get label {
    final word = switch (unit) {
      TrialUnit.day => 'day',
      TrialUnit.week => 'week',
      TrialUnit.month => 'month',
    };
    return '$count $word${count == 1 ? '' : 's'} free';
  }

  @override
  bool operator ==(Object other) =>
      other is FreeTrial && other.count == count && other.unit == unit;

  @override
  int get hashCode => Object.hash(count, unit);
}

/// Parses a Google Play billing period such as "P7D", "P1W" or "P1M".
/// Null for anything else (years, mixed periods).
FreeTrial? parseTrialPeriod(String period) {
  final m = RegExp(r'^P(\d+)([DWM])$').firstMatch(period.trim());
  if (m == null) return null;
  final n = int.parse(m.group(1)!);
  if (n <= 0) return null;
  return FreeTrial(n, switch (m.group(2)) {
    'D' => TrialUnit.day,
    'W' => TrialUnit.week,
    _ => TrialUnit.month,
  });
}

/// Sorts plans in display order: yearly first, then lifetime.
List<SadhakPlan> orderPlans(Iterable<SadhakPlan> plans) =>
    [...plans]..sort((a, b) => a.kind.index.compareTo(b.kind.index));
