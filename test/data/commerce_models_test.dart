import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/cart_line.dart';
import 'package:multiplagier_mobile/data/models/customer_order.dart';

void main() {
  test('CartLine calcula o total e a possibilidade de compra', () {
    final line = CartLine.fromRow({
      'product_id': 2,
      'name': 'Fone',
      'price_cents': 18990,
      'quantity': 2,
      'stock': 2,
      'is_active': 1,
    });

    expect(line.lineTotalCents, 37980);
    expect(line.canCheckout, isTrue);
    expect(line.copyWith(quantity: 3).canCheckout, isFalse);
  });

  test('OrderSummary e OrderItem leem as colunas do pedido', () {
    final summary = OrderSummary.fromRow({
      'id': 4,
      'created_at': '2026-10-23T18:00:00.000Z',
      'status': orderStatusPending,
      'total_cents': 18990,
    });
    final item = OrderItem.fromRow({
      'product_id': 2,
      'product_name': 'Fone',
      'unit_price_cents': 18990,
      'quantity': 1,
    });

    expect(summary.statusLabel, 'Pendente');
    expect(summary.totalCents, 18990);
    expect(item.lineTotalCents, 18990);
    expect(orderStatusLabel('shipped'), 'Em processamento');
  });
}
