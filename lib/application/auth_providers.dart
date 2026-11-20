import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/auth_config.dart';
import '../data/auth/auth_gateway.dart';
import '../domain/auth.dart';

/// The Supabase connection, or none in builds without a project.
/// Overridden in tests.
final authGatewayProvider = Provider<AuthGateway>(
  (_) =>
      AuthConfig.enabled ? SupabaseAuthGateway() : const DisabledAuthGateway(),
);

/// The signed-in user, or null. Follows sign-in and sign-out.
final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    final gateway = ref.watch(authGatewayProvider);
    final sub = gateway.userChanges.listen((u) {
      if (u != state) state = u;
    }, onError: (_) {});
    ref.onDispose(sub.cancel);
    return gateway.currentUser;
  }

  void set(AppUser? user) => state = user;
}

@immutable
class AuthUiState {
  const AuthUiState({this.busy, this.deleting = false, this.message});

  /// The method being signed in with, if any.
  final SignInMethod? busy;
  final bool deleting;

  /// One plain line to show under the buttons.
  final String? message;

  bool get working => busy != null || deleting;
}

/// Sign-in, sign-out and delete for the Sign up and Account screens.
final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AuthUiState>(
      AuthController.new,
    );

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  AuthGateway get _gateway => ref.read(authGatewayProvider);

  /// True when signed in. Cancelling the sheet returns false quietly.
  Future<bool> signIn(SignInMethod method) async {
    if (state.working) return false;
    state = AuthUiState(busy: method);
    try {
      final user = await _gateway.signIn(method);
      if (!ref.mounted) return user != null;
      if (user != null) {
        ref.read(currentUserProvider.notifier).set(user);
      }
      state = const AuthUiState();
      return user != null;
    } on AuthFailure catch (e) {
      if (ref.mounted) state = AuthUiState(message: e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    if (state.working) return;
    await _gateway.signOut();
    if (!ref.mounted) return;
    ref.read(currentUserProvider.notifier).set(null);
  }

  /// True when the account is gone.
  Future<bool> deleteAccount() async {
    if (state.working) return false;
    state = const AuthUiState(deleting: true);
    try {
      await _gateway.deleteAccount();
      if (!ref.mounted) return true;
      ref.read(currentUserProvider.notifier).set(null);
      state = const AuthUiState();
      return true;
    } on AuthFailure catch (e) {
      if (ref.mounted) state = AuthUiState(message: e.message);
      return false;
    }
  }
}
