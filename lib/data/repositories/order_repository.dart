import '../db/app_database.dart';
import '../models/customer_order.dart';

enum PlaceOrderFailure { emptyCart, unavailable }

class PlaceOrderOutcome {
  const PlaceOrderOutcome.success(this.order) : failure = null;

  const PlaceOrderOutcome.failure(this.failure) : order = null;

  final OrderDetail? order;
  final PlaceOrderFailure? failure;
}

/// Pedidos do cliente (US-006, US-007 e SEC-001).
///
/// A leitura filtra pelo usuário da sessão. Pedido de outra pessoa não
/// devolve itens, totais nem o dono — o mesmo resultado de um id inexistente.
abstract class OrderRepository {
  Future<PlaceOrderOutcome> placeOrder(int userId);

  Future<List<OrderSummary>> listForUser(int userId);

  Future<OrderDetail?> findForUser(int userId, int orderId);
}

class _PlaceOrderAbort implements Exception {
  const _PlaceOrderAbort(this.failure);

  final PlaceOrderFailure failure;
}

class SqliteOrderRepository implements OrderRepository {
  SqliteOrderRepository(this._database);

  /// Evento gravado quando alguém pede um pedido que não é seu.
  static const accessDeniedEvent = 'order_access_denied';
  static const orderResource = 'order';

  final AppDatabase _database;

  @override
  Future<PlaceOrderOutcome> placeOrder(int userId) async {
    try {
      final order = await _database.db.transaction<OrderDetail>((txn) async {
        final rows = await txn.rawQuery(
          '''
          SELECT ci.product_id, ci.quantity, p.name, p.price_cents,
                 p.stock, p.is_active
          FROM cart_items ci
          INNER JOIN products p ON p.id = ci.product_id
          WHERE ci.user_id = ?
          ''',
          [userId],
        );
        if (rows.isEmpty) {
          throw const _PlaceOrderAbort(PlaceOrderFailure.emptyCart);
        }

        final items = <OrderItem>[];
        var total = 0;
        for (final row in rows) {
          final quantity = row['quantity'] as int;
          final stock = row['stock'] as int;
          final active = (row['is_active'] as int) == 1;
          if (!active || quantity > stock) {
            throw const _PlaceOrderAbort(PlaceOrderFailure.unavailable);
          }
          final unitPrice = row['price_cents'] as int;
          total += unitPrice * quantity;
          items.add(
            OrderItem(
              productId: row['product_id'] as int,
              productName: row['name'] as String,
              unitPriceCents: unitPrice,
              quantity: quantity,
            ),
          );
        }

        final createdAt = DateTime.now().toUtc();
        final orderId = await txn.insert('orders', {
          'user_id': userId,
          'status': orderStatusPending,
          'total_cents': total,
          'created_at': createdAt.toIso8601String(),
        });

        for (final item in items) {
          final updated = await txn.rawUpdate(
            '''
            UPDATE products
            SET stock = stock - ?
            WHERE id = ? AND is_active = 1 AND stock >= ?
            ''',
            [item.quantity, item.productId, item.quantity],
          );
          if (updated != 1) {
            throw const _PlaceOrderAbort(PlaceOrderFailure.unavailable);
          }
          await txn.insert('order_items', {
            'order_id': orderId,
            'product_id': item.productId,
            'product_name': item.productName,
            'unit_price_cents': item.unitPriceCents,
            'quantity': item.quantity,
          });
        }

        await txn.delete(
          'cart_items',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        return OrderDetail(
          id: orderId,
          userId: userId,
          createdAt: createdAt,
          status: orderStatusPending,
          totalCents: total,
          items: items,
        );
      });
      return PlaceOrderOutcome.success(order);
    } on _PlaceOrderAbort catch (abort) {
      return PlaceOrderOutcome.failure(abort.failure);
    }
  }

  @override
  Future<List<OrderSummary>> listForUser(int userId) async {
    final rows = await _database.db.query(
      'orders',
      columns: ['id', 'created_at', 'status', 'total_cents'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(OrderSummary.fromRow).toList();
  }

  @override
  Future<OrderDetail?> findForUser(int userId, int orderId) async {
    final rows = await _database.db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final ownerId = rows.single['user_id'] as int;
    if (ownerId != userId) {
      await _recordDeniedAccess(actorUserId: userId, orderId: orderId);
      return null;
    }

    final itemRows = await _database.db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );
    return OrderDetail(
      id: rows.single['id'] as int,
      userId: ownerId,
      createdAt: DateTime.parse(rows.single['created_at'] as String),
      status: rows.single['status'] as String,
      totalCents: rows.single['total_cents'] as int,
      items: itemRows.map(OrderItem.fromRow).toList(),
    );
  }

  Future<void> _recordDeniedAccess({
    required int actorUserId,
    required int orderId,
  }) async {
    try {
      await _database.db.insert('security_events', {
        'event_type': accessDeniedEvent,
        'actor_user_id': actorUserId,
        'resource_type': orderResource,
        'resource_id': orderId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Falha de auditoria não pode liberar o pedido nem mudar a negação.
    }
  }
}
