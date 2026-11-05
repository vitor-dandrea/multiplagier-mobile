import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/order_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_page.dart';

class MultiplagierApp extends StatelessWidget {
  const MultiplagierApp({
    super.key,
    required this.authController,
    required this.catalogRepository,
    required this.cartRepository,
    required this.orderRepository,
  });

  final AuthController authController;
  final CatalogRepository catalogRepository;
  final CartRepository cartRepository;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplagier',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthGate(
        controller: authController,
        authenticatedBuilder: (context, user) => HomePage(
          user: user,
          authController: authController,
          catalogRepository: catalogRepository,
          cartRepository: cartRepository,
          orderRepository: orderRepository,
        ),
      ),
    );
  }
}
