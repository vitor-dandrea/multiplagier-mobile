import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';

/// Lista de produtos ativos (US-003). Não depende de navegação: quem usa
/// decide o que fazer ao tocar em um produto.
class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.repository,
    required this.onProductTap,
  });

  static const errorMessage = 'Não foi possível carregar o catálogo.';
  static const emptyMessage = 'Nenhum produto disponível no momento.';

  final CatalogRepository repository;
  final ValueChanged<Product> onProductTap;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _future = widget.repository.listActiveProducts();

  void _reload() {
    setState(() {
      _future = widget.repository.listActiveProducts();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // O erro é exibido pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            key: const Key('catalog_error'),
            icon: Icons.error_outline,
            message: ProductListPage.errorMessage,
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }
        final products = snapshot.data!;
        if (products.isEmpty) {
          return const _MessageState(
            key: Key('catalog_empty'),
            icon: Icons.inventory_2_outlined,
            message: ProductListPage.emptyMessage,
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            key: const Key('catalog_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _ProductTile(
              product: products[index],
              onTap: () => widget.onProductTap(products[index]),
            ),
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = product.isAvailable;

    return ListTile(
      key: Key('product_tile_${product.id}'),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.devices_other),
      ),
      title: Text(
        product.name,
        style: theme.textTheme.titleMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        available ? 'Em estoque' : 'Indisponível',
        style: TextStyle(
          color: available ? Colors.green.shade800 : theme.colorScheme.error,
        ),
      ),
      trailing: Text(
        formatBrl(product.priceCents),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('catalog_retry'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
