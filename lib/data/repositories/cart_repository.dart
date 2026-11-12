import '../db/app_database.dart';
import '../models/cart_line.dart';

enum CartFailure { unavailable, exceedsStock, invalidQuantity }

class CartChange {
  const CartChange.ok() : failure = null;

  const CartChange.failure(this.failure);

  final CartFailure? failure;

  bool get isOk => failure == null;
}

/// Carrinho local por usuário. Estoque e produto ativo são decididos no banco.
abstract class CartRepository {
  Future<List<CartLine>> listForUser(int userId);

  Future<CartChange> add(int userId, int productId, {int quantity = 1});

  Future<CartChange> setQuantity(int userId, int productId, int quantity);

  Future<void> remove(int userId, int productId);
}

class SqliteCartRepository implements CartRepository {
  SqliteCartRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<CartLine>> listForUser(int userId) async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT ci.product_id, ci.quantity, p.name, p.price_cents, p.stock, p.is_active
      FROM cart_items ci
      INNER JOIN products p ON p.id = ci.product_id
      WHERE ci.user_id = ?
      ORDER BY p.name COLLATE NOCASE ASC
      ''',
      [userId],
    );
    return rows.map(CartLine.fromRow).toList();
  }

  @override
  Future<CartChange> add(int userId, int productId, {int quantity = 1}) {
    if (quantity < 1) {
      return Future.value(
        const CartChange.failure(CartFailure.invalidQuantity),
      );
    }
    return _database.db.transaction((txn) async {
      final products = await txn.query(
        'products',
        where: 'id = ? AND is_active = 1',
        whereArgs: [productId],
        limit: 1,
      );
      if (products.isEmpty) {
        return const CartChange.failure(CartFailure.unavailable);
      }

      final stock = products.single['stock'] as int;
      if (stock <= 0) {
        return const CartChange.failure(CartFailure.unavailable);
      }
      final existing = await txn.query(
        'cart_items',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
        limit: 1,
      );
      final current = existing.isEmpty ? 0 : existing.single['quantity'] as int;
      final next = current + quantity;
      if (next > stock) {
        return const CartChange.failure(CartFailure.exceedsStock);
      }

      if (existing.isEmpty) {
        await txn.insert('cart_items', {
          'user_id': userId,
          'product_id': productId,
          'quantity': next,
        });
      } else {
        await txn.update(
          'cart_items',
          {'quantity': next},
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      }
      return const CartChange.ok();
    });
  }

  @override
  Future<CartChange> setQuantity(int userId, int productId, int quantity) {
    if (quantity < 1) {
      return Future.value(
        const CartChange.failure(CartFailure.invalidQuantity),
      );
    }
    return _database.db.transaction((txn) async {
      final products = await txn.query(
        'products',
        where: 'id = ? AND is_active = 1',
        whereArgs: [productId],
        limit: 1,
      );
      if (products.isEmpty) {
        return const CartChange.failure(CartFailure.unavailable);
      }
      final stock = products.single['stock'] as int;
      if (quantity > stock) {
        return const CartChange.failure(CartFailure.exceedsStock);
      }

      final updated = await txn.update(
        'cart_items',
        {'quantity': quantity},
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
      if (updated == 0) {
        return const CartChange.failure(CartFailure.unavailable);
      }
      return const CartChange.ok();
    });
  }

  @override
  Future<void> remove(int userId, int productId) {
    return _database.db.delete(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }
}
