import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/data/repositories/cart_repository.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';
import 'package:multiplagier_mobile/data/repositories/order_repository.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:multiplagier_mobile/features/catalog/product_detail_page.dart';
import 'package:multiplagier_mobile/features/orders/orders_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fakes.dart';

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget não apareceu a tempo: $finder');
}

/// Espera a transição terminar. `pageBack` exige um único botão de voltar,
/// e a rota de baixo ignora toques enquanto a animação está aberta.
Future<void> popToPrevious(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pageBack();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  sqfliteFfiInit();

  testWidgets('cadastra, mantém o carrinho e isola o pedido por usuário', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final hasher = PasswordHasher(iterations: 100);
    late AppDatabase database;
    late AuthController controller;

    await tester.runAsync(() async {
      database = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
        hasher: hasher,
      );
      controller = AuthController(
        repository: SqliteAuthRepository(database, hasher),
        sessionStore: MemorySessionStore(),
      );
      await controller.restoreSession();
    });

    await tester.pumpWidget(
      MultiplagierApp(
        authController: controller,
        catalogRepository: SqliteCatalogRepository(database),
        cartRepository: SqliteCartRepository(database),
        orderRepository: SqliteOrderRepository(database),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('login_create_account')));
    await pumpUntilFound(tester, find.byKey(const Key('register_name')));
    await tester.enterText(find.byKey(const Key('register_name')), 'Ana Silva');
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'Senha1234',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_confirm')),
      'Senha1234',
    );
    await tester.tap(find.byKey(const Key('register_submit')));
    await pumpUntilFound(tester, find.byKey(const Key('catalog_list')));
    expect(find.text('Olá, Ana Silva'), findsOneWidget);

    await tester.tap(find.byKey(const Key('product_tile_2')));
    await pumpUntilFound(tester, find.byKey(const Key('add_to_cart')));
    await tester.tap(find.byKey(const Key('add_to_cart')));
    await pumpUntilFound(tester, find.byKey(const Key('add_to_cart_feedback')));
    expect(find.text(ProductDetailPage.addedMessage), findsOneWidget);

    await popToPrevious(tester);
    await pumpUntilFound(tester, find.byKey(const Key('cart_badge')));

    await tester.tap(find.byKey(const Key('logout_button')));
    await pumpUntilFound(tester, find.byKey(const Key('login_submit')));
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'Senha1234',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await pumpUntilFound(tester, find.byKey(const Key('cart_badge')));

    await tester.tap(find.byKey(const Key('cart_button')));
    await pumpUntilFound(tester, find.byKey(const Key('cart_list')));
    expect(
      find.descendant(
        of: find.byKey(const Key('cart_list')),
        matching: find.text('Fone de Ouvido Bluetooth'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('cart_checkout')));
    await pumpUntilFound(tester, find.byKey(const Key('payment_submit')));
    await tester.tap(find.byKey(const Key('payment_method_pix')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('payment_submit')));
    await tester.pump(const Duration(milliseconds: 700));
    await pumpUntilFound(tester, find.byKey(const Key('order_status')));
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Pedido #1'), findsOneWidget);

    await popToPrevious(tester);
    await pumpUntilFound(tester, find.byKey(const Key('catalog_list')));
    expect(find.byKey(const Key('cart_badge')), findsNothing);

    await tester.tap(find.byKey(const Key('orders_button')));
    await pumpUntilFound(tester, find.byKey(const Key('order_tile_1')));

    await popToPrevious(tester);
    await pumpUntilFound(tester, find.byKey(const Key('logout_button')));
    await tester.tap(find.byKey(const Key('logout_button')));
    await pumpUntilFound(tester, find.byKey(const Key('login_submit')));

    await tester.enterText(find.byKey(const Key('login_email')), demoUserEmail);
    await tester.enterText(
      find.byKey(const Key('login_password')),
      demoUserPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await pumpUntilFound(tester, find.text('Olá, Cliente Demo'));
    expect(find.byKey(const Key('cart_badge')), findsNothing);

    await tester.tap(find.byKey(const Key('orders_button')));
    await pumpUntilFound(tester, find.byKey(const Key('orders_empty')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(OrdersPage.emptyMessage), findsOneWidget);
    expect(find.text('Fone de Ouvido Bluetooth'), findsNothing);

    await tester.runAsync(() async {
      final orderRows = await database.db.query('orders');
      expect(orderRows, hasLength(1));
      final orderId = orderRows.single['id'] as int;
      final ownerId = orderRows.single['user_id'] as int;
      expect(orderRows.single['total_cents'], 18990);

      final demo = await database.db.query(
        'users',
        where: 'email = ?',
        whereArgs: [demoUserEmail],
      );
      final demoId = demo.single['id'] as int;
      expect(ownerId, isNot(demoId));

      final fone = await database.db.query(
        'products',
        where: 'name = ?',
        whereArgs: ['Fone de Ouvido Bluetooth'],
      );
      expect(fone.single['stock'], 39);

      final orderRepository = SqliteOrderRepository(database);
      final own = await orderRepository.findForUser(ownerId, orderId);
      expect(own?.items.single.productName, 'Fone de Ouvido Bluetooth');

      expect(await orderRepository.findForUser(demoId, orderId), isNull);
      final events = await database.db.query('security_events');
      expect(events, hasLength(1));
      expect(
        events.single['event_type'],
        SqliteOrderRepository.accessDeniedEvent,
      );
      expect(events.single['actor_user_id'], demoId);
      expect(events.single.values.join(' '), isNot(contains('Fone')));

      expect(
        await SqliteCartRepository(database).listForUser(ownerId),
        isEmpty,
      );

      await database.close();
    });
  });
}
