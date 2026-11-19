/// What the Shravan package unlocks (PRD_v4 section 7): the whole Listen
/// section, bought once. Pure Dart.
///
/// Reading is always free; only listening to recordings is paid.
library;

import 'premium.dart';

enum ListenFeature {
  /// Shloka recitations: chapters, the player, continue listening.
  recitation,

  /// Saving chapters on the phone.
  download,

  /// The chapter narrations on the summary screen.
  narration,
}

extension ListenFeatureCopy on ListenFeature {
  String get reason => switch (this) {
    ListenFeature.recitation => 'The audio library is part of Shravan',
    ListenFeature.download => 'Downloading chapters is part of Shravan',
    ListenFeature.narration => 'Chapter narrations are part of Shravan',
  };
}

/// Whether [feature] may be used with the Shravan [entitlement]. Every part
/// of Listen needs Shravan.
bool canListen(ListenFeature feature, Entitlement entitlement) =>
    entitlement == Entitlement.premium;
