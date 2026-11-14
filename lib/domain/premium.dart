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
  static Set<String> forStore({required bool appStore}) =>
      {yearly, appStore ? lifetimeAppStore : lifetime};
}

enum PlanKind { yearly, lifetime }

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
  });

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

/// Sorts plans in display order: yearly first, then lifetime.
List<SadhakPlan> orderPlans(Iterable<SadhakPlan> plans) =>
    [...plans]..sort((a, b) => a.kind.index.compareTo(b.kind.index));
