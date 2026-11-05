import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/cart_line.dart';
import 'package:multiplagier_mobile/data/repositories/order_repository.dart';
import 'package:multiplagier_mobile/features/cart/cart_controller.dart';
import 'package:multiplagier_mobile/features/cart/cart_page.dart';

import '../support/fake_commerce.dart';

const _line = CartLine(
  productId: 2,
  name: 'Fone Bluetooth',
  unitPriceCents: 18990,
  quantity: 1,
  stock: 1,
  isActive: true,
);

void main() {
  late FakeCartRepository cart;
  late FakeOrderRepository orders;
  late CartController controller;
  var ordersPlaced = 0;

  Future<void> pumpCart(WidgetTester tester) async {
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(
          controller: controller,
          orderRepository: orders,
          onOrderPlaced: () => ordersPlaced++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    ordersPlaced = 0;
    cart = FakeCartRepository(lines: const [_line]);
    orders = FakeOrderRepository(cart: cart);
    controller = CartController(
      cartRepository: cart,
      orderRepository: orders,
      userId: 4,
    );
  });

  testWidgets('carrinho vazio explica o estado e não oferece checkout', (
    tester,
  ) async {
    cart.lines.clear();
    await pumpCart(tester);

    expect(find.byKey(const Key('cart_empty')), findsOneWidget);
    expect(find.text(CartController.emptyCartMessage), findsOneWidget);
    expect(find.byKey(const Key('cart_checkout')), findsNothing);
  });

  testWidgets('erro ao carregar não vaza detalhes e permite tentar de novo', (
    tester,
  ) async {
    cart.failListTimes = 1;
    await pumpCart(tester);

    expect(find.byKey(const Key('cart_error')), findsOneWidget);
    expect(find.text(CartController.loadErrorMessage), findsOneWidget);
    expect(find.textContaining('sensível'), findsNothing);
    expect(find.text('Fone Bluetooth'), findsNothing);

    await tester.tap(find.byKey(const Key('cart_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.byKey(const Key('cart_list')), findsOneWidget);
  });

  testWidgets('aumentar acima do estoque falha e remover esvazia', (
    tester,
  ) async {
    await pumpCart(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('cart_total'))).data,
      'Total: R\$ 189,90',
    );

    await tester.tap(find.byKey(const Key('cart_inc_2')));
    await tester.pumpAndSettle();
    expect(find.text(CartController.exceedsStockMessage), findsOneWidget);
    expect(find.byKey(const Key('cart_qty_2')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('cart_qty_2'))).data, '1');

    await tester.tap(find.byKey(const Key('cart_dec_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cart_empty')), findsOneWidget);
  });

  testWidgets('cancelar a confirmação não cria pedido', (tester) async {
    await pumpCart(tester);

    await tester.tap(find.byKey(const Key('cart_checkout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_order_cancel')));
    await tester.pumpAndSettle();

    expect(orders.placeCalls, 0);
    expect(ordersPlaced, 0);
    expect(find.byKey(const Key('cart_list')), findsOneWidget);
  });

  testWidgets('confirmar a compra abre o pedido', (tester) async {
    await pumpCart(tester);

    await tester.tap(find.byKey(const Key('cart_checkout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_order')));
    await tester.pumpAndSettle();

    expect(ordersPlaced, 1);
    expect(find.byKey(const Key('order_status')), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.text('Pedido #1'), findsOneWidget);
  });

  testWidgets('compra recusada permanece no carrinho com mensagem clara', (
    tester,
  ) async {
    orders.failNext = PlaceOrderFailure.unavailable;
    await pumpCart(tester);

    await tester.tap(find.byKey(const Key('cart_checkout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_order')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart_list')), findsOneWidget);
    expect(
      find.text(CartController.unavailableCheckoutMessage),
      findsOneWidget,
    );
    expect(ordersPlaced, 0);
  });
}
