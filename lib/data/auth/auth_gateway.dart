import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
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

  /// The raw nonce for this app session's Google sign-ins. Its SHA-256 goes
  /// to Google (the package takes a nonce only at initialize), the raw one
  /// to Supabase, so a Google ID token taken from elsewhere cannot be
  /// replayed against the project.
  String? _googleNonce;

  /// Call once in main() before runApp.
  static Future<void> initialize() => Supabase.initialize(
    url: AuthConfig.supabaseUrl,
    publishableKey: AuthConfig.supabaseKey,
  );

  @override
  bool get available => true;

  @override
  List<SignInMethod> get methods => signInMethodsFor(
    iOS: defaultTargetPlatform == TargetPlatform.iOS,
    appleOnAndroid: AuthConfig.appleOnAndroid,
  );

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges =>
      _auth.onAuthStateChange.map((s) => _toUser(s.session?.user));

  @override
  Future<AppUser?> signIn(SignInMethod method) async {
    try {
      return switch (method) {
        SignInMethod.apple =>
          defaultTargetPlatform == TargetPlatform.iOS
              ? await _signInWithApple()
              : await _signInWithAppleWeb(),
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
    // Keep Apple's refresh token on the server so deleting the account can
    // revoke it (Apple requires that). Best effort, never awaited.
    final code = cred.authorizationCode;
    if (code.isNotEmpty) {
      unawaited(_storeAppleToken({'client': 'ios', 'code': code}));
    }
    return _toUser(res.user ?? _auth.currentUser);
  }

  /// How long to wait for Apple's web page to hand the session back once
  /// the user is back in the app. Longer than this: they closed it.
  static const _webReturnWait = Duration(seconds: 8);

  /// Sign in with Apple on Android: Apple's web page in the browser, which
  /// returns to [AuthConfig.authRedirect]; supabase_flutter picks up the
  /// session from that link.
  Future<AppUser?> _signInWithAppleWeb() async {
    final done = Completer<Session?>();
    Timer? giveUp;
    final sub = _auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedIn && !done.isCompleted) {
        done.complete(s.session);
      }
    }, onError: (_) {});
    final lifecycle = AppLifecycleListener(
      onResume: () {
        giveUp?.cancel();
        giveUp = Timer(_webReturnWait, () {
          if (!done.isCompleted) done.complete(null);
        });
      },
    );
    try {
      final opened = await _auth
          .signInWithOAuth(
            OAuthProvider.apple,
            redirectTo: AuthConfig.authRedirect,
            authScreenLaunchMode: LaunchMode.externalApplication,
          )
          .timeout(_networkTimeout);
      if (!opened) {
        throw const AuthFailure(
          'Apple sign-in did not finish. Please try again.',
        );
      }
      final session = await done.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => null,
      );
      if (session == null) return null; // closed the page
      final refresh = session.providerRefreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        unawaited(_storeAppleToken({'client': 'web', 'refreshToken': refresh}));
      }
      return _toUser(session.user);
    } finally {
      giveUp?.cancel();
      lifecycle.dispose();
      await sub.cancel();
    }
  }

  Future<void> _storeAppleToken(Map<String, String> body) async {
    try {
      await _client.functions
          .invoke('apple-token', body: body)
          .timeout(_networkTimeout);
    } catch (_) {
      // The account works without it; only the revoke on delete is missed.
    }
  }

  Future<AppUser?> _signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      final rawNonce = _auth.generateRawNonce();
      await google.initialize(
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS &&
                AuthConfig.googleIosClientId.isNotEmpty
            ? AuthConfig.googleIosClientId
            : null,
        serverClientId: AuthConfig.googleWebClientId.isEmpty
            ? null
            : AuthConfig.googleWebClientId,
      );
      _googleNonce = rawNonce;
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
        .signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          nonce: _googleNonce,
        )
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
      // Revokes the Apple token first, then deletes (delete-account
      // function). If the function is unreachable for any reason other
      // than the network, the database function still deletes the account.
      try {
        await _client.functions
            .invoke('delete-account')
            .timeout(_networkTimeout);
      } on FunctionException {
        await _client.rpc<void>('delete_my_account');
      }
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
      // The verify-purchase function checks it with the store and keeps
      // the record; the app no longer writes the table itself.
      await _client.functions
          .invoke('verify-purchase', body: purchaseBody(record))
          .timeout(_networkTimeout);
    } catch (_) {
      // Support record only: the purchase itself is already granted.
    }
  }

  /// What the app sends to the verify-purchase function.
  @visibleForTesting
  static Map<String, String> purchaseBody(PurchaseRecord r) => {
    'productId': r.productId,
    'platform': r.platform,
    'transactionId': ?r.transactionId,
    'purchaseToken': ?r.purchaseToken,
  };

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
