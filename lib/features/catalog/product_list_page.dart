import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format/money.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';
import 'catalog_filter.dart';
import 'product_image.dart';
import 'product_placeholder.dart';

/// Lista de produtos ativos (US-003) com busca e filtro por categoria (US-009).
class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.repository,
    required this.onProductTap,
  });

  static const errorMessage = 'Não foi possível carregar o catálogo.';
  static const emptyMessage = 'Nenhum produto disponível no momento.';
  static const noMatchMessage =
      'Nenhum produto encontrado para esta busca.';

  final CatalogRepository repository;
  final ValueChanged<Product> onProductTap;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _future = _load();
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  // `async` garante que qualquer falha vire erro do Future (e não do build).
  Future<List<Product>> _load() async => widget.repository.listActiveProducts();

  void _reload() {
    setState(() {
      _future = _load();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

        final categories = catalogCategories(products);
        final visible = filterCatalog(
          products,
          query: _query,
          category: _category,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('catalog_search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar produtos',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('catalog_search_clear'),
                          tooltip: 'Limpar busca',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (categories.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  key: const Key('catalog_categories'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: const Key('catalog_category_all'),
                        label: const Text('Todas'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          key: Key('catalog_category_$category'),
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) => setState(() {
                            _category = _category == category ? null : category;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: visible.isEmpty
                  ? const _MessageState(
                      key: Key('catalog_no_match'),
                      icon: Icons.search_off,
                      message: ProductListPage.noMatchMessage,
                    )
                  : RefreshIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      onRefresh: _refresh,
                      child: GridView.builder(
                        key: const Key('catalog_list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) => _ProductTile(
                          product: visible[index],
                          onTap: () => widget.onProductTap(visible[index]),
                        ),
                      ),
                    ),
            ),
          ],
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
    final scheme = theme.colorScheme;
    final status = AppStatusColors.of(context);
    final available = product.isAvailable;

    return Material(
      key: Key('product_tile_${product.id}'),
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ProductImage(
                product: product,
                size: ProductPlaceholderSize.tile,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available ? 'Em estoque' : 'Indisponível',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: available ? status.success : scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      formatBrl(product.priceCents),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
