import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../../data/repositories/catalog_repository.dart';
import '../auth/auth_controller.dart';
import '../catalog/product_detail_page.dart';
import '../catalog/product_list_page.dart';

/// Área autenticada: catálogo de produtos com acesso ao detalhe e logout.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.authController,
    required this.catalogRepository,
  });

  final User user;
  final AuthController authController;
  final CatalogRepository catalogRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: authController.logout,
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
                'Olá, ${user.name}',
                key: const Key('home_greeting'),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: ProductListPage(
              repository: catalogRepository,
              onProductTap: (product) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(
                      repository: catalogRepository,
                      productId: product.id,
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
