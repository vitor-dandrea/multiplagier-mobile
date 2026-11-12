import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/cart_line.dart';
import 'package:multiplagier_mobile/data/repositories/cart_repository.dart';
import 'package:multiplagier_mobile/data/repositories/order_repository.dart';
import 'package:multiplagier_mobile/features/cart/cart_controller.dart';

import '../support/fake_commerce.dart';

class _ThrowingCart implements CartRepository {
  @override
  Future<CartChange> add(int userId, int productId, {int quantity = 1}) =>
      throw StateError('sql secreto');

  @override
  Future<List<CartLine>> listForUser(int userId) async => const [];

  @override
  Future<void> remove(int userId, int productId) =>
      throw StateError('sql secreto');

  @override
  Future<CartChange> setQuantity(int userId, int productId, int quantity) =>
      throw StateError('sql secreto');
}

void main() {
  late FakeCartRepository cart;
  late FakeOrderRepository orders;
  late CartController controller;

  setUp(() {
    cart = FakeCartRepository();
    orders = FakeOrderRepository(cart: cart);
    controller = CartController(
      cartRepository: cart,
      orderRepository: orders,
      userId: 4,
    );
  });

  test('adicionar atualiza quantidade e total', () async {
    await controller.load();
    expect(await controller.add(7), isTrue);

    expect(controller.itemCount, 1);
    expect(controller.totalCents, 1500);
    expect(controller.errorMessage, isNull);
    expect(controller.lines.single.name, 'Produto 7');
  });

  test('quantidade acima do estoque não altera o carrinho', () async {
    await controller.load();
    expect(await controller.add(7, quantity: 9), isFalse);

    expect(controller.itemCount, 0);
    expect(controller.errorMessage, CartController.exceedsStockMessage);
  });

  test('falha inesperada não vaza o erro interno', () async {
    final failing = CartController(
      cartRepository: _ThrowingCart(),
      orderRepository: orders,
      userId: 4,
    );

    expect(await failing.add(1), isFalse);
    expect(failing.errorMessage, CartController.unexpectedMessage);
    expect(failing.errorMessage, isNot(contains('secreto')));
    expect(failing.busy, isFalse);
  });

  test('checkout de carrinho vazio não cria pedido', () async {
    await controller.load();
    expect(await controller.checkout(), isNull);
    expect(controller.errorMessage, CartController.emptyCartMessage);
    expect(orders.placeCalls, 0);
  });

  test('checkout conclui o pedido e esvazia o carrinho', () async {
    await controller.load();
    await controller.add(7, quantity: 2);

    final id = await controller.checkout();

    expect(id, 1);
    expect(controller.itemCount, 0);
    expect(orders.orders.single.totalCents, 3000);
    expect(orders.orders.single.userId, 4);
  });

  test(
    'checkout indisponível mantém os itens e a mensagem genérica de negócio',
    () async {
      await controller.load();
      await controller.add(7);
      orders.failNext = PlaceOrderFailure.unavailable;

      expect(await controller.checkout(), isNull);
      expect(controller.itemCount, 1);
      expect(
        controller.errorMessage,
        CartController.unavailableCheckoutMessage,
      );
    },
  );

  test('checkout com falha interna não vaza detalhes', () async {
    await controller.load();
    await controller.add(7);
    orders.throwOnPlace = true;

    expect(await controller.checkout(), isNull);
    expect(controller.errorMessage, CartController.unexpectedMessage);
    expect(controller.errorMessage, isNot(contains('sensível')));
    expect(controller.itemCount, 1);
  });
}
