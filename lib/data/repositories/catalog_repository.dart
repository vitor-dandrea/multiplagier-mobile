import '../db/app_database.dart';
import '../models/product.dart';

/// Contrato do catálogo público (US-003 e US-004 do backlog).
/// Produtos inativos nunca são expostos.
abstract class CatalogRepository {
  Future<List<Product>> listActiveProducts();

  /// `null` se o produto não existir ou estiver inativo.
  Future<Product?> findActiveById(int id);
}

class SqliteCatalogRepository implements CatalogRepository {
  SqliteCatalogRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Product>> listActiveProducts() async {
    final rows = await _database.db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromRow).toList();
  }

  @override
  Future<Product?> findActiveById(int id) async {
    final rows = await _database.db.query(
      'products',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromRow(rows.single);
  }
}
