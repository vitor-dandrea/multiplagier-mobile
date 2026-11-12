import 'payment_info.dart';
import 'shipping_address.dart';

/// Status inicial de um pedido criado pelo cliente. A troca de status
/// (US-008) fica fora do escopo mobile.
const orderStatusPending = 'pending';

String orderStatusLabel(String status) {
  switch (status) {
    case orderStatusPending:
      return 'Pendente';
    default:
      return 'Em processamento';
  }
}

String? paymentDisplayLabel(PaymentMethod? method, String? last4) {
  if (method == null) return null;
  if (method == PaymentMethod.card && last4 != null && last4.length == 4) {
    return PaymentInfo.card(last4: last4).displayLabel;
  }
  return method.label;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalCents,
    this.paymentMethod,
    this.paymentLast4,
  });

  factory OrderSummary.fromRow(Map<String, Object?> row) {
    return OrderSummary(
      id: row['id'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: row['status'] as String,
      totalCents: row['total_cents'] as int,
      paymentMethod: PaymentMethodStorage.tryParse(
        row['payment_method'] as String?,
      ),
      paymentLast4: row['payment_last4'] as String?,
    );
  }

  final int id;
  final DateTime createdAt;
  final String status;
  final int totalCents;
  final PaymentMethod? paymentMethod;
  final String? paymentLast4;

  String get statusLabel => orderStatusLabel(status);

  String? get paymentLabel =>
      paymentDisplayLabel(paymentMethod, paymentLast4);
}

/// Item congelado no momento da compra (nome e preço não seguem o catálogo).
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPriceCents,
    required this.quantity,
  });

  factory OrderItem.fromRow(Map<String, Object?> row) {
    return OrderItem(
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      unitPriceCents: row['unit_price_cents'] as int,
      quantity: row['quantity'] as int,
    );
  }

  final int productId;
  final String productName;
  final int unitPriceCents;
  final int quantity;

  int get lineTotalCents => unitPriceCents * quantity;
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.status,
    required this.totalCents,
    required this.items,
    this.paymentMethod,
    this.paymentLast4,
    this.shippingAddress,
  });

  final int id;
  final int userId;
  final DateTime createdAt;
  final String status;
  final int totalCents;
  final List<OrderItem> items;
  final PaymentMethod? paymentMethod;
  final String? paymentLast4;
  final ShippingAddress? shippingAddress;

  String get statusLabel => orderStatusLabel(status);

  String? get paymentLabel =>
      paymentDisplayLabel(paymentMethod, paymentLast4);
}
