import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/product.dart';
import 'package:multiplagier_mobile/features/catalog/catalog_filter.dart';

const _products = <Product>[
  Product(
    id: 1,
    name: 'Fone Bluetooth',
    description: 'Headphone sem fio',
    category: 'Áudio',
    priceCents: 100,
    stock: 1,
    isActive: true,
  ),
  Product(
    id: 2,
    name: 'Mouse Gamer',
    description: 'Sensor óptico',
    category: 'Periféricos',
    priceCents: 200,
    stock: 1,
    isActive: true,
  ),
  Product(
    id: 3,
    name: 'Caixa de Som',
    description: 'Bluetooth portátil',
    category: 'Áudio',
    priceCents: 300,
    stock: 1,
    isActive: true,
  ),
];

void main() {
  test('filtra por texto no nome ou na descrição', () {
    final byName = filterCatalog(_products, query: 'mouse');
    expect(byName.map((p) => p.id), [2]);

    final byDescription = filterCatalog(_products, query: 'portátil');
    expect(byDescription.map((p) => p.id), [3]);
  });

  test('filtra por categoria e combina com a busca', () {
    final audio = filterCatalog(_products, category: 'Áudio');
    expect(audio.map((p) => p.id), [1, 3]);

    final combined = filterCatalog(
      _products,
      query: 'bluetooth',
      category: 'Áudio',
    );
    expect(combined.map((p) => p.id), [1, 3]);
  });

  test('lista categorias ordenadas sem repetir', () {
    expect(catalogCategories(_products), ['Periféricos', 'Áudio']);
  });
}
