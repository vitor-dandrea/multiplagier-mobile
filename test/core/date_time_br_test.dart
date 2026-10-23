import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/format/date_time_br.dart';

void main() {
  test('formata data local como dd/MM/yyyy HH:mm', () {
    expect(formatDateTimeBr(DateTime(2026, 1, 5, 9, 7)), '05/01/2026 09:07');
  });
}
