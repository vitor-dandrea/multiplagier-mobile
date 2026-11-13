import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/features/payment/payment_rules.dart';

void main() {
  group('PaymentRules', () {
    test('aceita número de cartão com Luhn válido', () {
      expect(PaymentRules.isValidCardNumber('4111111111111111'), isTrue);
      expect(PaymentRules.isValidCardNumber('4111 1111 1111 1111'), isTrue);
      expect(PaymentRules.last4FromCardNumber('4111111111111111'), '1111');
    });

    test('rejeita número inválido', () {
      expect(PaymentRules.isValidCardNumber('4111111111111112'), isFalse);
      expect(PaymentRules.isValidCardNumber('1234'), isFalse);
    });

    test('valida nome, CVV e validade futura', () {
      expect(PaymentRules.isValidCardName('ANA SILVA'), isTrue);
      expect(PaymentRules.isValidCardName('ab'), isFalse);
      expect(PaymentRules.isValidCvv('123'), isTrue);
      expect(PaymentRules.isValidCvv('12'), isFalse);
      expect(
        PaymentRules.isExpiryInFuture(
          '12/30',
          now: DateTime(2026, 11, 12),
        ),
        isTrue,
      );
      expect(
        PaymentRules.isExpiryInFuture(
          '01/20',
          now: DateTime(2026, 11, 12),
        ),
        isFalse,
      );
    });
  });
}
