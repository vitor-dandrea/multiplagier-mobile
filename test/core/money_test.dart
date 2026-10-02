import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/format/money.dart';

void main() {
  group('formatBrl', () {
    test('formata valores com milhar e centavos', () {
      expect(formatBrl(249900), 'R\$ 2.499,00');
      expect(formatBrl(18990), 'R\$ 189,90');
      expect(formatBrl(123456789), 'R\$ 1.234.567,89');
    });

    test('preenche centavos menores que 10', () {
      expect(formatBrl(5), 'R\$ 0,05');
      expect(formatBrl(100), 'R\$ 1,00');
      expect(formatBrl(0), 'R\$ 0,00');
    });

    test('suporta valores negativos', () {
      expect(formatBrl(-1050), '-R\$ 10,50');
    });
  });
}
