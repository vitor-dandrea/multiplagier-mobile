/// Dados de pagamento simulados persistidos no pedido (sem PAN/CVV).
enum PaymentMethod { card, pix }

extension PaymentMethodStorage on PaymentMethod {
  String get storageValue => switch (this) {
    PaymentMethod.card => 'card',
    PaymentMethod.pix => 'pix',
  };

  String get label => switch (this) {
    PaymentMethod.card => 'Cartão',
    PaymentMethod.pix => 'Pix',
  };

  static PaymentMethod? tryParse(String? raw) {
    switch (raw) {
      case 'card':
        return PaymentMethod.card;
      case 'pix':
        return PaymentMethod.pix;
      default:
        return null;
    }
  }
}

class PaymentInfo {
  const PaymentInfo.card({required String last4})
    : assert(last4.length == 4),
      method = PaymentMethod.card,
      last4 = last4;

  const PaymentInfo.pix() : method = PaymentMethod.pix, last4 = null;

  final PaymentMethod method;
  final String? last4;

  String get displayLabel {
    if (method == PaymentMethod.card && last4 != null) {
      return 'Cartão •••• $last4';
    }
    return method.label;
  }
}
