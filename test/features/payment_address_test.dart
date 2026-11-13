import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/cart_line.dart';
import 'package:multiplagier_mobile/data/models/shipping_address.dart';
import 'package:multiplagier_mobile/data/models/user.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:multiplagier_mobile/features/cart/cart_controller.dart';
import 'package:multiplagier_mobile/features/payment/payment_page.dart';

import '../support/fake_commerce.dart';
import '../support/fakes.dart';

const _line = CartLine(
  productId: 2,
  name: 'Fone Bluetooth',
  unitPriceCents: 18990,
  quantity: 1,
  stock: 1,
  isActive: true,
);

void main() {
  testWidgets('bloqueia pagamento sem endereço completo', (tester) async {
    final cart = FakeCartRepository(lines: const [_line]);
    final orders = FakeOrderRepository(cart: cart, shippingAddress: null);
    final controller = CartController(
      cartRepository: cart,
      orderRepository: orders,
      userId: 1,
    );
    await controller.load();

    final auth = AuthController(
      repository: FakeAuthRepository(
        address: const ShippingAddress(
          street: '',
          number: '',
          district: '',
          city: '',
          state: '',
          zip: '',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    // Login ainda devolve o usuário do fake; força perfil incompleto.
    await auth.login('cliente@multiplagier.local', 'Multiplagier@2026');
    // FakeAuthRepository constructor with empty address still sets incomplete.
    expect(auth.user?.hasCompleteAddress, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          controller: controller,
          orderRepository: orders,
          authController: auth,
          onOrderPlaced: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payment_shipping_missing')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('payment_submit')),
    );
    expect(button.onPressed, isNull);
    expect(orders.placeCalls, 0);
  });

  testWidgets('exibe endereço quando o perfil está completo', (tester) async {
    final cart = FakeCartRepository(lines: const [_line]);
    final orders = FakeOrderRepository(cart: cart);
    final controller = CartController(
      cartRepository: cart,
      orderRepository: orders,
      userId: 1,
    );
    await controller.load();

    final auth = AuthController(
      repository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
    await auth.login('cliente@multiplagier.local', 'Multiplagier@2026');
    expect(auth.user, isA<User>());
    expect(auth.user!.hasCompleteAddress, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          controller: controller,
          orderRepository: orders,
          authController: auth,
          onOrderPlaced: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payment_shipping_missing')), findsNothing);
    expect(find.textContaining('Rua das Flores'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('payment_submit')),
    );
    expect(button.onPressed, isNotNull);
  });
}
