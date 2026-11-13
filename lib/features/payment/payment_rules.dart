/// Validação local do formulário de pagamento (simulado / offline).
abstract final class PaymentRules {
  static const emptyCardNumberMessage = 'Informe o número do cartão.';
  static const invalidCardNumberMessage = 'Número do cartão inválido.';
  static const emptyCardNameMessage = 'Informe o nome impresso no cartão.';
  static const invalidCardNameMessage = 'Informe um nome válido.';
  static const emptyExpiryMessage = 'Informe a validade.';
  static const invalidExpiryMessage = 'Validade inválida (MM/AA).';
  static const expiredCardMessage = 'Cartão expirado.';
  static const emptyCvvMessage = 'Informe o CVV.';
  static const invalidCvvMessage = 'CVV inválido.';

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static bool isValidCardNumber(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length < 13 || digits.length > 19) return false;
    return _luhnOk(digits);
  }

  static bool isValidCardName(String raw) {
    final name = raw.trim();
    return name.length >= 3 && RegExp(r"[A-Za-zÀ-ÿ\s'.-]{3,}").hasMatch(name);
  }

  /// Aceita `MM/AA` ou `MMAA`.
  static bool isValidExpiryFormat(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length != 4) return false;
    final month = int.tryParse(digits.substring(0, 2));
    return month != null && month >= 1 && month <= 12;
  }

  static bool isExpiryInFuture(String raw, {DateTime? now}) {
    if (!isValidExpiryFormat(raw)) return false;
    final digits = digitsOnly(raw);
    final month = int.parse(digits.substring(0, 2));
    final year = 2000 + int.parse(digits.substring(2, 4));
    final reference = now ?? DateTime.now();
    // Cartão válido até o fim do mês informado.
    final expiresEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    return !expiresEnd.isBefore(reference);
  }

  static bool isValidCvv(String raw) {
    final digits = digitsOnly(raw);
    return digits.length == 3 || digits.length == 4;
  }

  static String? last4FromCardNumber(String raw) {
    final digits = digitsOnly(raw);
    if (digits.length < 4) return null;
    return digits.substring(digits.length - 4);
  }

  static bool _luhnOk(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
