import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/data/repositories/cart_repository.dart';
import 'package:multiplagier_mobile/data/models/payment_info.dart';
import 'package:multiplagier_mobile/data/repositories/order_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteCartRepository cart;
  late SqliteOrderRepository orders;
  late SqliteAuthRepository auth;
  final hasher = PasswordHasher(iterations: 100);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: hasher,
    );
    cart = SqliteCartRepository(database);
    orders = SqliteOrderRepository(database);
    auth = SqliteAuthRepository(database, hasher);
  });

  tearDown(() => database.close());

  Future<int> demoId() async {
    final rows = await database.db.query(
      'users',
      where: 'email = ?',
      whereArgs: [demoUserEmail],
    );
    return rows.single['id'] as int;
  }

  Future<Map<String, Object?>> productNamed(String name) async {
    final rows = await database.db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.single;
  }

  Future<int> stockOf(int productId) async {
    final rows = await database.db.query(
      'products',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    return rows.single['stock'] as int;
  }

  group('SqliteOrderRepository.placeOrder', () {
    test(
      'persiste itens, total e baixa o estoque só do carrinho da pessoa',
      () async {
        final demo = await demoId();
        final ana = (await auth.register(
          name: 'Ana Silva',
          email: 'ana@example.com',
          password: 'Senha1234',
        )).user!;
        final fone = await productNamed('Fone de Ouvido Bluetooth');
        final mouse = await productNamed('Mouse Gamer RGB');
        final foneId = fone['id'] as int;
        final mouseId = mouse['id'] as int;

        await cart.add(demo, foneId, quantity: 2);
        await cart.add(demo, mouseId);
        await cart.add(ana.id, foneId);

        final outcome = await orders.placeOrder(demo, const PaymentInfo.pix());

        expect(outcome.failure, isNull);
        final order = outcome.order!;
        expect(order.userId, demo);
        expect(order.status, 'pending');
        expect(order.totalCents, 18990 * 2 + 12990);
        expect(
          order.items.fold<int>(0, (sum, item) => sum + item.lineTotalCents),
          order.totalCents,
        );
        expect(await cart.listForUser(demo), isEmpty);
        expect((await cart.listForUser(ana.id)).single.quantity, 1);
        expect(await stockOf(foneId), 38);
        expect(await stockOf(mouseId), 29);

        final listed = await orders.listForUser(demo);
        expect(listed.single.id, order.id);
        expect(listed.single.totalCents, order.totalCents);
        expect(await orders.listForUser(ana.id), isEmpty);
      },
    );

    test('usa o preço do banco na hora da compra e congela o nome', () async {
      final demo = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      final foneId = fone['id'] as int;
      await cart.add(demo, foneId);
      await database.db.update(
        'products',
        {'price_cents': 1000},
        where: 'id = ?',
        whereArgs: [foneId],
      );

      final order = (await orders.placeOrder(demo, const PaymentInfo.pix())).order!;
      expect(order.totalCents, 1000);
      expect(order.items.single.unitPriceCents, 1000);
      expect(order.items.single.productName, 'Fone de Ouvido Bluetooth');

      await database.db.update(
        'products',
        {'name': 'Nome alterado depois'},
        where: 'id = ?',
        whereArgs: [foneId],
      );
      final loaded = await orders.findForUser(demo, order.id);
      expect(loaded!.items.single.productName, 'Fone de Ouvido Bluetooth');
      expect(loaded.totalCents, 1000);
    });

    test('carrinho vazio não cria pedido', () async {
      final outcome = await orders.placeOrder(await demoId(), const PaymentInfo.pix());
      expect(outcome.failure, PlaceOrderFailure.emptyCart);
      expect(await database.db.query('orders'), isEmpty);
    });

    test('item indisponível desfaz a compra inteira', () async {
      final demo = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      final mouse = await productNamed('Mouse Gamer RGB');
      final foneId = fone['id'] as int;
      final mouseId = mouse['id'] as int;
      await cart.add(demo, foneId);
      await cart.add(demo, mouseId);
      await database.db.update(
        'products',
        {'stock': 0},
        where: 'id = ?',
        whereArgs: [mouseId],
      );

      final outcome = await orders.placeOrder(demo, const PaymentInfo.pix());

      expect(outcome.failure, PlaceOrderFailure.unavailable);
      expect(await database.db.query('orders'), isEmpty);
      expect(await database.db.query('order_items'), isEmpty);
      expect(await cart.listForUser(demo), hasLength(2));
      expect(await stockOf(foneId), 40);
      expect(await stockOf(mouseId), 0);
    });

    test('lista o pedido mais recente primeiro', () async {
      final demo = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      final productId = fone['id'] as int;

      await cart.add(demo, productId);
      final first = (await orders.placeOrder(demo, const PaymentInfo.pix())).order!;
      await cart.add(demo, productId);
      final second = (await orders.placeOrder(demo, const PaymentInfo.pix())).order!;

      final listed = await orders.listForUser(demo);
      expect(listed.map((order) => order.id), [second.id, first.id]);
    });

    test('persiste método de pagamento e last4 do cartão', () async {
      final demo = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      await cart.add(demo, fone['id'] as int);

      final order = (await orders.placeOrder(
        demo,
        const PaymentInfo.card(last4: '1111'),
      )).order!;

      expect(order.paymentMethod, PaymentMethod.card);
      expect(order.paymentLast4, '1111');
      expect(order.paymentLabel, 'Cartão •••• 1111');

      final loaded = await orders.findForUser(demo, order.id);
      expect(loaded!.paymentLabel, 'Cartão •••• 1111');
    });

    test('congela endereço de entrega no pedido', () async {
      final demo = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      await cart.add(demo, fone['id'] as int);

      final order =
          (await orders.placeOrder(demo, const PaymentInfo.pix())).order!;
      expect(order.shippingAddress, isNotNull);
      expect(order.shippingAddress!.street, 'Rua das Flores');
      expect(order.shippingAddress!.zip, '09310000');

      final loaded = await orders.findForUser(demo, order.id);
      expect(loaded!.shippingAddress!.city, 'Mauá');
      expect(loaded.shippingAddress!.singleLine, contains('Rua das Flores'));
    });

    test('recusa checkout sem endereço completo', () async {
      final ana = (await auth.register(
        name: 'Ana Silva',
        email: 'ana.sem.endereco@example.com',
        password: 'Senha1234',
      )).user!;
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      await cart.add(ana.id, fone['id'] as int);

      final outcome = await orders.placeOrder(ana.id, const PaymentInfo.pix());
      expect(outcome.failure, PlaceOrderFailure.missingAddress);
      expect(outcome.order, isNull);
    });
  });

  group('SEC-001 acesso ao pedido', () {
    test('o dono lê o pedido e outra pessoa recebe o mesmo vazio de um id inexistente', () async {
      final demo = await demoId();
      final ana = (await auth.register(
        name: 'Ana Silva',
        email: 'ana@example.com',
        password: 'Senha1234',
      )).user!;
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      await cart.add(demo, fone['id'] as int);
      final order = (await orders.placeOrder(demo, const PaymentInfo.pix())).order!;

      final own = await orders.findForUser(demo, order.id);
      expect(own?.items.single.productName, 'Fone de Ouvido Bluetooth');
      expect(await database.db.query('security_events'), isEmpty);

      expect(await orders.findForUser(demo, 9999), isNull);
      expect(await database.db.query('security_events'), isEmpty);

      final denied = await orders.findForUser(ana.id, order.id);
      expect(denied, isNull);

      final events = await database.db.query('security_events');
      expect(events, hasLength(1));
      expect(
        events.single['event_type'],
        SqliteOrderRepository.accessDeniedEvent,
      );
      expect(events.single['actor_user_id'], ana.id);
      expect(
        events.single['resource_type'],
        SqliteOrderRepository.orderResource,
      );
      expect(events.single['resource_id'], order.id);
      final audit = events.single.values.join(' ');
      expect(audit, isNot(contains('Fone')));
      expect(audit, isNot(contains(demoUserPassword)));
      expect(audit, isNot(contains('Senha1234')));

      expect(await orders.listForUser(ana.id), isEmpty);
      expect((await orders.listForUser(demo)).single.id, order.id);
    });
  });
}
