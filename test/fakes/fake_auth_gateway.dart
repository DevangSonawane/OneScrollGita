import 'dart:async';

import 'package:versescroll/data/auth/auth_gateway.dart';
import 'package:versescroll/domain/auth.dart';

/// A scriptable Supabase stand-in for tests.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.user,
    this.methods = const [SignInMethod.google],
    this.signInResult = const AppUser(
      id: '00000000-0000-4000-8000-000000000001',
      email: 'reader@example.com',
      name: 'Test Reader',
      method: SignInMethod.google,
    ),
  });

  AppUser? user;

  @override
  final List<SignInMethod> methods;

  /// What [signIn] returns (null: the user cancelled the sheet).
  AppUser? signInResult;

  /// When set, [signIn] / [deleteAccount] throw it.
  AuthFailure? failure;

  final signIns = <SignInMethod>[];
  final records = <PurchaseRecord>[];
  int signOuts = 0;
  int deletes = 0;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  bool get available => true;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  @override
  Future<AppUser?> signIn(SignInMethod method) async {
    signIns.add(method);
    if (failure != null) throw failure!;
    user = signInResult;
    _changes.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    if (failure != null) throw failure!;
    deletes++;
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> recordPurchase(PurchaseRecord record) async =>
      records.add(record);
}
