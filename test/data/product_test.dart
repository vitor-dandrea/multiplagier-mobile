import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/product.dart';

void main() {
  test('Product.fromRow converte colunas do SQLite', () {
    final product = Product.fromRow({
      'id': 3,
      'name': 'Mouse',
      'description': 'Mouse óptico',
      'price_cents': 12990,
      'stock': 0,
      'is_active': 1,
    });

    expect(product.id, 3);
    expect(product.priceCents, 12990);
    expect(product.isActive, isTrue);
    expect(product.isAvailable, isFalse);
  });

  test('is_active = 0 resulta em produto inativo', () {
    final product = Product.fromRow({
      'id': 4,
      'name': 'Antigo',
      'description': 'x',
      'price_cents': 1,
      'stock': 2,
      'is_active': 0,
    });

    expect(product.isActive, isFalse);
    expect(product.isAvailable, isTrue);
  });
}
