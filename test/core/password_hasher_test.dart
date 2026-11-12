import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';

void main() {
  final hasher = PasswordHasher(iterations: 100);

  group('PasswordHasher', () {
    test('não armazena a senha em texto claro', () {
      final stored = hasher.hash('Segredo@123');
      expect(stored, isNot(contains('Segredo@123')));
      expect(stored, startsWith(r'pbkdf2$100$'));
    });

    test('verifica a senha correta', () {
      final stored = hasher.hash('Segredo@123');
      expect(hasher.verify('Segredo@123', stored), isTrue);
    });

    test('rejeita senha incorreta', () {
      final stored = hasher.hash('Segredo@123');
      expect(hasher.verify('segredo@123', stored), isFalse);
      expect(hasher.verify('', stored), isFalse);
    });

    test('usa salt diferente a cada hash da mesma senha', () {
      expect(hasher.hash('Segredo@123'), isNot(hasher.hash('Segredo@123')));
    });

    test('rejeita hash armazenado malformado sem lançar exceção', () {
      expect(hasher.verify('x', 'texto-qualquer'), isFalse);
      expect(hasher.verify('x', r'pbkdf2$abc$@@@$@@@'), isFalse);
      expect(hasher.verify('x', r'pbkdf2$0$AAAA$AAAA'), isFalse);
    });
  });
}
