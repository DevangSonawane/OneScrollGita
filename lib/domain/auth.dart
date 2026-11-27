/// The optional account (PRD_v9). Pure Dart: no Supabase types here.
library;

/// How the user signed in.
enum SignInMethod {
  apple('Apple'),
  google('Google');

  const SignInMethod(this.label);

  final String label;

  static SignInMethod? byProvider(String? provider) =>
      values.where((m) => m.name == provider).firstOrNull;
}

/// The signed-in user, as much as the app needs to show.
class AppUser {
  const AppUser({required this.id, this.email, this.name, this.method});

  /// Supabase user ID (a UUID). Also sent to the store with purchases.
  final String id;
  final String? email;
  final String? name;
  final SignInMethod? method;

  /// The best line to show for the account.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Signed in';
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.name == name &&
      other.method == method;

  @override
  int get hashCode => Object.hash(id, email, name, method);
}

/// A sign-in, sign-out or delete that failed for a reason worth showing.
/// Cancelling the Apple or Google sheet is not a failure.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// One store purchase to record against the account (support only; the app
/// never unlocks anything from it, PRD_v9 section 4).
class PurchaseRecord {
  const PurchaseRecord({
    required this.productId,
    required this.platform,
    this.transactionId,
    this.purchaseToken,
  });

  final String productId;

  /// `ios` or `android`.
  final String platform;
  final String? transactionId;

  /// Google Play's purchase token (null on the App Store).
  final String? purchaseToken;
}

/// The sign-in buttons a platform shows, in display order. Apple shows on
/// iPhone (the native sheet) and, when this build turns it on, on Android
/// (Apple's web sign-in, owner decision 2026-11-25). Google shows on both.
List<SignInMethod> signInMethodsFor({
  required bool iOS,
  required bool appleOnAndroid,
}) => [if (iOS || appleOnAndroid) SignInMethod.apple, SignInMethod.google];

/// Whether the sign-up page shows after first launch: once, to a new
/// install, when accounts exist in this build and nobody is signed in.
bool shouldShowSignUp({
  required bool accountsAvailable,
  required bool stepPending,
  required bool signedIn,
}) => accountsAvailable && stepPending && !signedIn;
