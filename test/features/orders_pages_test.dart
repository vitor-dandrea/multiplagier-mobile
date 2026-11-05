import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/format/date_time_br.dart';
import 'package:multiplagier_mobile/data/models/customer_order.dart';
import 'package:multiplagier_mobile/features/orders/order_detail_page.dart';
import 'package:multiplagier_mobile/features/orders/orders_page.dart';

import '../support/fake_commerce.dart';

OrderDetail _order({
  required int id,
  required int userId,
  required String productName,
  int productId = 2,
  int totalCents = 18990,
}) {
  return OrderDetail(
    id: id,
    userId: userId,
    createdAt: DateTime.utc(2026, 10, 23, 18),
    status: orderStatusPending,
    totalCents: totalCents,
    items: [
      OrderItem(
        productId: productId,
        productName: productName,
        unitPriceCents: totalCents,
        quantity: 1,
      ),
    ],
  );
}

void main() {
  final own = _order(id: 3, userId: 1, productName: 'Fone Bluetooth');
  final secret = _order(
    id: 9,
    userId: 2,
    productName: 'Segredo do outro cliente',
    productId: 8,
    totalCents: 99999,
  );

  testWidgets('lista identificador, data, status e valor só do usuário', (
    tester,
  ) async {
    final repository = FakeOrderRepository(orders: [own, secret]);
    await tester.pumpWidget(
      MaterialApp(home: OrdersPage(repository: repository, userId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order_tile_3')), findsOneWidget);
    expect(find.byKey(const Key('order_tile_9')), findsNothing);
    expect(find.text('Pedido #3'), findsOneWidget);
    expect(find.textContaining('Pendente'), findsOneWidget);
    expect(find.text('R\$ 189,90'), findsOneWidget);
    expect(
      find.textContaining(formatDateTimeBr(own.createdAt)),
      findsOneWidget,
    );
    expect(find.text('Segredo do outro cliente'), findsNothing);
    expect(find.text('R\$ 999,99'), findsNothing);

    await tester.tap(find.byKey(const Key('order_tile_3')));
    await tester.pumpAndSettle();
    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.byKey(const Key('order_total')), findsOneWidget);
  });

  testWidgets('sem pedidos mostra estado vazio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrdersPage(repository: FakeOrderRepository(), userId: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('orders_empty')), findsOneWidget);
    expect(find.text(OrdersPage.emptyMessage), findsOneWidget);
  });

  testWidgets('erro da lista não vaza detalhes e permite tentar de novo', (
    tester,
  ) async {
    final repository = FakeOrderRepository(orders: [own])..throwOnList = true;
    await tester.pumpWidget(
      MaterialApp(home: OrdersPage(repository: repository, userId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('orders_error')), findsOneWidget);
    expect(find.text(OrdersPage.errorMessage), findsOneWidget);
    expect(find.textContaining('sensível'), findsNothing);
    expect(find.text('Fone Bluetooth'), findsNothing);

    repository.throwOnList = false;
    await tester.tap(find.byKey(const Key('orders_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('orders_list')), findsOneWidget);
  });

  testWidgets('detalhe do próprio pedido mostra itens e total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailPage(
          repository: FakeOrderRepository(orders: [own]),
          userId: 1,
          orderId: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order_id')), findsOneWidget);
    expect(find.byKey(const Key('order_status')), findsOneWidget);
    expect(find.byKey(const Key('order_date')), findsOneWidget);
    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.textContaining('R\$ 189,90'), findsWidgets);
  });

  testWidgets('pedido de outra pessoa não exibe dados', (tester) async {
    final repository = FakeOrderRepository(orders: [own, secret]);
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailPage(
          repository: repository,
          userId: 2,
          orderId: own.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order_not_found')), findsOneWidget);
    expect(find.text(OrderDetailPage.notFoundMessage), findsOneWidget);
    expect(find.text('Fone Bluetooth'), findsNothing);
    expect(find.text('R\$ 189,90'), findsNothing);
    expect(repository.deniedOrderIds, [own.id]);
  });

  testWidgets('id inexistente também não é encontrado e não gera negação', (
    tester,
  ) async {
    final repository = FakeOrderRepository(orders: [own]);
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailPage(repository: repository, userId: 1, orderId: 404),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order_not_found')), findsOneWidget);
    expect(repository.deniedOrderIds, isEmpty);
  });

  testWidgets('erro no detalhe não vaza detalhes', (tester) async {
    final repository = FakeOrderRepository(orders: [own])..throwOnFind = true;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailPage(
          repository: repository,
          userId: 1,
          orderId: own.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order_error')), findsOneWidget);
    expect(find.text(OrderDetailPage.errorMessage), findsOneWidget);
    expect(find.textContaining('sensível'), findsNothing);
    expect(find.text('Fone Bluetooth'), findsNothing);
  });
}
