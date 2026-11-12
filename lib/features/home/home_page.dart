import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_page.dart';
import '../catalog/product_detail_page.dart';
import '../catalog/product_list_page.dart';
import '../orders/orders_page.dart';

/// Área autenticada: catálogo, carrinho e pedidos do cliente logado.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.authController,
    required this.catalogRepository,
    required this.cartRepository,
    required this.orderRepository,
  });

  final User user;
  final AuthController authController;
  final CatalogRepository catalogRepository;
  final CartRepository cartRepository;
  final OrderRepository orderRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CartController _cart;
  var _catalogRevision = 0;

  @override
  void initState() {
    super.initState();
    _cart = CartController(
      cartRepository: widget.cartRepository,
      orderRepository: widget.orderRepository,
      userId: widget.user.id,
    );
    unawaited(_cart.load());
  }

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  Future<String?> _addProduct(int productId) async {
    final ok = await _cart.add(productId);
    if (!mounted) return CartController.unexpectedMessage;
    if (ok) return null;
    return _cart.errorMessage;
  }

  Future<void> _openCart() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartPage(
          controller: _cart,
          orderRepository: widget.orderRepository,
          onOrderPlaced: () {
            if (mounted) setState(() => _catalogRevision++);
          },
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrdersPage(
          repository: widget.orderRepository,
          userId: widget.user.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            key: const Key('orders_button'),
            tooltip: 'Pedidos',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: _openOrders,
          ),
          ListenableBuilder(
            listenable: _cart,
            builder: (context, _) {
              final count = _cart.itemCount;
              return IconButton(
                key: const Key('cart_button'),
                tooltip: 'Carrinho',
                onPressed: _openCart,
                icon: count == 0
                    ? const Icon(Icons.shopping_cart_outlined)
                    : Badge(
                        key: const Key('cart_badge'),
                        label: Text('$count'),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
              );
            },
          ),
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: widget.authController.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Olá, ${widget.user.name}',
                key: const Key('home_greeting'),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: ProductListPage(
              key: ValueKey(_catalogRevision),
              repository: widget.catalogRepository,
              onProductTap: (product) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(
                      repository: widget.catalogRepository,
                      productId: product.id,
                      onAddToCart: () => _addProduct(product.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
