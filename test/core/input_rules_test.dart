import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/validation/input_rules.dart';

void main() {
  group('InputRules', () {
    test('aceita nome, e-mail e senha dentro da política', () {
      expect(InputRules.isValidName('Ana Silva'), isTrue);
      expect(InputRules.isValidName("Maria d'Ávila"), isTrue);
      expect(InputRules.isValidEmail('ana@example.com'), isTrue);
      expect(InputRules.isValidPassword('Senha1234'), isTrue);
      expect(InputRules.isValidPassword('Multiplagier@2026'), isTrue);
    });

    test('rejeita entradas fora da política', () {
      expect(InputRules.isValidName('A'), isFalse);
      expect(InputRules.isValidName(''), isFalse);
      expect(InputRules.isValidName('Ana\nSilva'), isFalse);
      expect(InputRules.isValidName('A' * 81), isFalse);
      expect(InputRules.isValidEmail('sem-arroba'), isFalse);
      expect(InputRules.isValidEmail(''), isFalse);
      expect(InputRules.isValidPassword('curta'), isFalse);
      expect(InputRules.isValidPassword('somente'), isFalse);
      expect(InputRules.isValidPassword('12345678'), isFalse);
      expect(InputRules.isValidPassword('a' * 129), isFalse);
    });
  });
}
