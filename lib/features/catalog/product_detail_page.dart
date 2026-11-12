import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format/money.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';
import 'product_placeholder.dart';

/// Detalhe de um produto ativo (US-004). Produto inexistente ou inativo
/// mostra "não encontrado", sem expor detalhes internos.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.repository,
    required this.productId,
    this.onAddToCart,
  });

  static const notFoundMessage = 'Produto não encontrado.';
  static const errorMessage = 'Não foi possível carregar o produto.';
  static const addedMessage = 'Adicionado ao carrinho.';
  static const addErrorMessage = 'Não foi possível adicionar ao carrinho.';

  final CatalogRepository repository;
  final int productId;

  /// `null` quando o item foi adicionado; mensagem quando não foi.
  /// Ausente, o detalhe só exibe o produto (catálogo).
  final Future<String?> Function()? onAddToCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final Future<Product?> _future = _load();
  bool _adding = false;
  String? _feedback;
  bool _feedbackIsError = false;

  // `async` garante que qualquer falha vire erro do Future (e não do build).
  Future<Product?> _load() async =>
      widget.repository.findActiveById(widget.productId);

  Future<void> _add() async {
    final onAddToCart = widget.onAddToCart;
    if (onAddToCart == null || _adding) return;
    setState(() {
      _adding = true;
      _feedback = null;
    });
    try {
      final error = await onAddToCart();
      if (!mounted) return;
      setState(() {
        _feedback = error ?? ProductDetailPage.addedMessage;
        _feedbackIsError = error != null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedback = ProductDetailPage.addErrorMessage;
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

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
          return Column(
            children: [
              Expanded(child: _ProductDetail(product: product)),
              if (widget.onAddToCart != null)
                _AddToCartBar(
                  enabled: product.isAvailable && !_adding,
                  label: product.isAvailable
                      ? 'Adicionar ao carrinho'
                      : 'Indisponível',
                  feedback: _feedback,
                  feedbackIsError: _feedbackIsError,
                  onPressed: _add,
                ),
            ],
          );
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
    final status = AppStatusColors.of(context);
    final available = product.isAvailable;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: 200,
          child: ProductPlaceholder(
            category: product.category,
            name: product.name,
            size: ProductPlaceholderSize.hero,
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
            fontWeight: FontWeight.w700,
            color: available ? status.success : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text('Descrição', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          product.description,
          key: const Key('detail_description'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.enabled,
    required this.label,
    required this.feedback,
    required this.feedbackIsError,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final String? feedback;
  final bool feedbackIsError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);
    return Material(
      color: AppColors.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (feedback != null) ...[
                Text(
                  feedback!,
                  key: const Key('add_to_cart_feedback'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: feedbackIsError
                        ? theme.colorScheme.error
                        : status.success,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                key: const Key('add_to_cart'),
                onPressed: enabled ? onPressed : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(label),
              ),
            ],
          ),
        ),
      ),
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
