import 'package:multiplagier_mobile/data/models/cart_line.dart';
import 'package:multiplagier_mobile/data/models/customer_order.dart';
import 'package:multiplagier_mobile/data/models/payment_info.dart';
import 'package:multiplagier_mobile/data/repositories/cart_repository.dart';
import 'package:multiplagier_mobile/data/repositories/order_repository.dart';

class FakeCartRepository implements CartRepository {
  FakeCartRepository({List<CartLine>? lines, this.failListTimes = 0})
    : lines = [...?lines];

  final List<CartLine> lines;
  int failListTimes;
  CartFailure? failNext;

  @override
  Future<List<CartLine>> listForUser(int userId) async {
    if (failListTimes > 0) {
      failListTimes--;
      throw StateError('detalhe interno sensível');
    }
    return List<CartLine>.from(lines);
  }

  @override
  Future<CartChange> add(int userId, int productId, {int quantity = 1}) async {
    final failure = _takeFailure();
    if (failure != null) return CartChange.failure(failure);
    if (quantity < 1) {
      return const CartChange.failure(CartFailure.invalidQuantity);
    }
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index >= 0) {
      final current = lines[index];
      final next = current.quantity + quantity;
      if (!current.isActive || current.stock <= 0) {
        return const CartChange.failure(CartFailure.unavailable);
      }
      if (next > current.stock) {
        return const CartChange.failure(CartFailure.exceedsStock);
      }
      lines[index] = current.copyWith(quantity: next);
    } else {
      const stock = 5;
      if (quantity > stock) {
        return const CartChange.failure(CartFailure.exceedsStock);
      }
      lines.add(
        CartLine(
          productId: productId,
          name: 'Produto $productId',
          unitPriceCents: 1500,
          quantity: quantity,
          stock: stock,
          isActive: true,
        ),
      );
    }
    return const CartChange.ok();
  }

  @override
  Future<CartChange> setQuantity(
    int userId,
    int productId,
    int quantity,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return CartChange.failure(failure);
    if (quantity < 1) {
      return const CartChange.failure(CartFailure.invalidQuantity);
    }
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index < 0) {
      return const CartChange.failure(CartFailure.unavailable);
    }
    final current = lines[index];
    if (!current.isActive) {
      return const CartChange.failure(CartFailure.unavailable);
    }
    if (quantity > current.stock) {
      return const CartChange.failure(CartFailure.exceedsStock);
    }
    lines[index] = current.copyWith(quantity: quantity);
    return const CartChange.ok();
  }

  @override
  Future<void> remove(int userId, int productId) async {
    lines.removeWhere((line) => line.productId == productId);
  }

  CartFailure? _takeFailure() {
    final failure = failNext;
    failNext = null;
    return failure;
  }
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.cart, List<OrderDetail>? orders})
    : orders = orders ?? [];

  final FakeCartRepository? cart;
  final List<OrderDetail> orders;
  bool throwOnPlace = false;
  bool throwOnList = false;
  bool throwOnFind = false;
  PlaceOrderFailure? failNext;
  int placeCalls = 0;
  PaymentInfo? lastPayment;
  final List<int> deniedOrderIds = [];
  int _nextId = 1;

  @override
  Future<PlaceOrderOutcome> placeOrder(int userId, PaymentInfo payment) async {
    placeCalls++;
    lastPayment = payment;
    if (throwOnPlace) throw StateError('falha interna sensível');
    final failure = failNext;
    failNext = null;
    if (failure != null) return PlaceOrderOutcome.failure(failure);

    final source = cart?.lines ?? const <CartLine>[];
    if (source.isEmpty) {
      return const PlaceOrderOutcome.failure(PlaceOrderFailure.emptyCart);
    }
    if (source.any((line) => !line.canCheckout)) {
      return const PlaceOrderOutcome.failure(PlaceOrderFailure.unavailable);
    }

    final items = [
      for (final line in source)
        OrderItem(
          productId: line.productId,
          productName: line.name,
          unitPriceCents: line.unitPriceCents,
          quantity: line.quantity,
        ),
    ];
    final total = items.fold<int>(0, (sum, item) => sum + item.lineTotalCents);
    final order = OrderDetail(
      id: _nextId++,
      userId: userId,
      createdAt: DateTime.utc(2026, 10, 23, 18),
      status: orderStatusPending,
      totalCents: total,
      items: items,
      paymentMethod: payment.method,
      paymentLast4: payment.last4,
    );
    orders.add(order);
    cart?.lines.clear();
    return PlaceOrderOutcome.success(order);
  }

  @override
  Future<List<OrderSummary>> listForUser(int userId) async {
    if (throwOnList) throw StateError('detalhe interno sensível');
    return [
      for (final order in orders.reversed)
        if (order.userId == userId)
          OrderSummary(
            id: order.id,
            createdAt: order.createdAt,
            status: order.status,
            totalCents: order.totalCents,
            paymentMethod: order.paymentMethod,
            paymentLast4: order.paymentLast4,
          ),
    ];
  }

  @override
  Future<OrderDetail?> findForUser(int userId, int orderId) async {
    if (throwOnFind) throw StateError('detalhe interno sensível');
    for (final order in orders) {
      if (order.id != orderId) continue;
      if (order.userId != userId) {
        deniedOrderIds.add(orderId);
        return null;
      }
      return order;
    }
    return null;
  }
}
