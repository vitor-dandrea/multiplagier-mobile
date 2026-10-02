import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';

/// Detalhe de um produto ativo (US-004). Produto inexistente ou inativo
/// mostra "não encontrado", sem expor detalhes internos.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.repository,
    required this.productId,
  });

  static const notFoundMessage = 'Produto não encontrado.';
  static const errorMessage = 'Não foi possível carregar o produto.';

  final CatalogRepository repository;
  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final Future<Product?> _future = _load();

  // `async` garante que qualquer falha vire erro do Future (e não do build).
  Future<Product?> _load() async =>
      widget.repository.findActiveById(widget.productId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _Message(
              key: Key('detail_error'),
              text: ProductDetailPage.errorMessage,
            );
          }
          final product = snapshot.data;
          if (product == null) {
            return const _Message(
              key: Key('detail_not_found'),
              text: ProductDetailPage.notFoundMessage,
            );
          }
          return _ProductDetail(product: product);
        },
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = product.isAvailable;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.devices_other,
            size: 72,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          product.name,
          key: const Key('detail_name'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          formatBrl(product.priceCents),
          key: const Key('detail_price'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          available ? 'Em estoque' : 'Indisponível',
          key: const Key('detail_availability'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: available ? Colors.green.shade800 : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text('Descrição', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          product.description,
          key: const Key('detail_description'),
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
