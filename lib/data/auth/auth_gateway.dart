import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/auth_config.dart';
import '../../domain/auth.dart';

/// The only code that talks to Supabase (PRD_v9). Everything else goes
/// through this.
abstract class AuthGateway {
  /// False when this build has no Supabase project: no account features.
  bool get available;

  /// The sign-in methods this platform offers, in display order.
  List<SignInMethod> get methods;

  AppUser? get currentUser;

  /// Emits on every sign-in and sign-out.
  Stream<AppUser?> get userChanges;

  /// Returns the user, or null when they cancelled the Apple/Google sheet.
  /// Throws [AuthFailure] for anything worth showing.
  Future<AppUser?> signIn(SignInMethod method);

  Future<void> signOut();

  /// Deletes the account on the server, then signs out. Throws
  /// [AuthFailure] when it could not be deleted.
  Future<void> deleteAccount();

  /// Best effort; never throws (support record only).
  Future<void> recordPurchase(PurchaseRecord record);
}

/// Builds without a Supabase project.
class DisabledAuthGateway implements AuthGateway {
  const DisabledAuthGateway();

  @override
  bool get available => false;

  @override
  List<SignInMethod> get methods => const [];

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get userChanges => const Stream.empty();

  @override
  Future<AppUser?> signIn(SignInMethod method) async =>
      throw const AuthFailure('Accounts are not available in this build.');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> recordPurchase(PurchaseRecord record) async {}
}

/// Supabase Auth with native Apple and Google sheets (ID-token sign-in).
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;
  GoTrueClient get _auth => _client.auth;

  bool _googleReady = false;

  /// Call once in main() before runApp.
  static Future<void> initialize() => Supabase.initialize(
    url: AuthConfig.supabaseUrl,
    publishableKey: AuthConfig.supabaseKey,
  );

  @override
  bool get available => true;

  @override
  List<SignInMethod> get methods => [
    // Apple on Android needs a web redirect flow; not built (PRD_v9).
    if (defaultTargetPlatform == TargetPlatform.iOS) SignInMethod.apple,
    SignInMethod.google,
  ];

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges =>
      _auth.onAuthStateChange.map((s) => _toUser(s.session?.user));

  @override
  Future<AppUser?> signIn(SignInMethod method) async {
    try {
      return switch (method) {
        SignInMethod.apple => await _signInWithApple(),
        SignInMethod.google => await _signInWithGoogle(),
      };
    } on AuthFailure {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw const AuthFailure(
        'Apple sign-in did not finish. Please try again.',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw const AuthFailure(
        'Google sign-in did not finish. Please try again.',
      );
    } on AuthRetryableFetchException {
      throw const AuthFailure(_offline);
    } on AuthException {
      throw const AuthFailure('Sign-in failed. Please try again.');
    } catch (_) {
      throw const AuthFailure(_offline);
    }
  }

  /// A sign-in that hangs (weak network) ends with the offline line
  /// instead of a spinner that never stops.
  static const _networkTimeout = Duration(seconds: 25);

  static const _offline =
      'Could not reach the sign-in service. Check your internet connection.';

  Future<AppUser?> _signInWithApple() async {
    // The hashed nonce goes to Apple, the raw one to Supabase.
    final rawNonce = _auth.generateRawNonce();
    final hashed = sha256.convert(utf8.encode(rawNonce)).toString();
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashed,
    );
    final idToken = cred.identityToken;
    if (idToken == null) {
      throw const AuthFailure(
        'Apple sign-in did not finish. Please try again.',
      );
    }
    final res = await _auth
        .signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        )
        .timeout(_networkTimeout);
    // Apple sends the name on the first sign-in only: keep it.
    final name = [
      cred.givenName,
      cred.familyName,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    if (name.isNotEmpty) {
      try {
        await _auth.updateUser(UserAttributes(data: {'full_name': name}));
      } catch (_) {
        // Signed in anyway; the name is a nicety.
      }
    }
    return _toUser(res.user ?? _auth.currentUser);
  }

  Future<AppUser?> _signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS &&
                AuthConfig.googleIosClientId.isNotEmpty
            ? AuthConfig.googleIosClientId
            : null,
        serverClientId: AuthConfig.googleWebClientId.isEmpty
            ? null
            : AuthConfig.googleWebClientId,
      );
      _googleReady = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure(
        'Google sign-in did not finish. Please try again.',
      );
    }
    final res = await _auth
        .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
        .timeout(_networkTimeout);
    return _toUser(res.user ?? _auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Offline: the local session is cleared anyway.
    }
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc<void>('delete_my_account');
    } on AuthRetryableFetchException {
      throw const AuthFailure(_offline);
    } catch (_) {
      throw const AuthFailure(
        'Your account could not be deleted. Check your internet connection '
        'and try again.',
      );
    }
    await signOut();
  }

  @override
  Future<void> recordPurchase(PurchaseRecord record) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final row = {
        'user_id': user.id,
        'product_id': record.productId,
        'platform': record.platform,
        'transaction_id': record.transactionId,
      };
      final table = _client.from('purchases');
      if (record.transactionId == null) {
        await table.insert(row);
      } else {
        await table.upsert(
          row,
          onConflict: 'user_id,transaction_id',
          ignoreDuplicates: true,
        );
      }
    } catch (_) {
      // Support record only: the purchase itself is already granted.
    }
  }

  static AppUser? _toUser(User? u) {
    if (u == null) return null;
    final meta = u.userMetadata ?? const <String, dynamic>{};
    final name = meta['full_name'] ?? meta['name'];
    return AppUser(
      id: u.id,
      email: u.email,
      name: name is String ? name : null,
      method: SignInMethod.byProvider(u.appMetadata['provider'] as String?),
    );
  }
}
