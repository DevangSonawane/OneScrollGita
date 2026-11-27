import 'package:flutter_test/flutter_test.dart';
import 'package:versescroll/data/auth/auth_gateway.dart';
import 'package:versescroll/domain/auth.dart';

void main() {
  group('sign-in buttons per platform', () {
    test('iPhone shows Apple then Google', () {
      expect(signInMethodsFor(iOS: true, appleOnAndroid: false), [
        SignInMethod.apple,
        SignInMethod.google,
      ]);
    });

    test('Android shows Google only until Apple web sign-in is on', () {
      expect(signInMethodsFor(iOS: false, appleOnAndroid: false), [
        SignInMethod.google,
      ]);
      expect(signInMethodsFor(iOS: false, appleOnAndroid: true), [
        SignInMethod.apple,
        SignInMethod.google,
      ]);
    });
  });

  group('verify-purchase request', () {
    test('Google Play sends the purchase token', () {
      final body = SupabaseAuthGateway.purchaseBody(
        const PurchaseRecord(
          productId: 'sadhak_yearly',
          platform: 'android',
          transactionId: 'GPA.1',
          purchaseToken: 'tok',
        ),
      );
      expect(body, {
        'productId': 'sadhak_yearly',
        'platform': 'android',
        'transactionId': 'GPA.1',
        'purchaseToken': 'tok',
      });
    });

    test('App Store sends no token and leaves out missing values', () {
      final body = SupabaseAuthGateway.purchaseBody(
        const PurchaseRecord(productId: 'shravan_yearly', platform: 'ios'),
      );
      expect(body, {'productId': 'shravan_yearly', 'platform': 'ios'});
    });
  });
}
