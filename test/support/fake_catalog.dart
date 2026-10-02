import 'package:multiplagier_mobile/data/models/product.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';

const sampleProducts = <Product>[
  Product(
    id: 1,
    name: 'Fone Bluetooth',
    description: 'Headphone sem fio com 30 horas de bateria.',
    priceCents: 18990,
    stock: 10,
    isActive: true,
  ),
  Product(
    id: 2,
    name: 'Tablet 10"',
    description: 'Tablet com 64GB e Wi-Fi.',
    priceCents: 89900,
    stock: 0,
    isActive: true,
  ),
];

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.products = sampleProducts,
    this.failTimes = 0,
  });

  final List<Product> products;

  /// Quantas chamadas iniciais devem falhar (para testar erro e retry).
  int failTimes;
  int listCalls = 0;

  @override
  Future<List<Product>> listActiveProducts() async {
    listCalls++;
    if (failTimes > 0) {
      failTimes--;
      throw StateError('falha interna com detalhes sensíveis');
    }
    return products.where((p) => p.isActive).toList();
  }

  @override
  Future<Product?> findActiveById(int id) async {
    for (final p in products) {
      if (p.id == id && p.isActive) return p;
    }
    return null;
  }
}
