import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import 'product_placeholder.dart';

/// Foto de produto offline (asset) com fallback para [ProductPlaceholder].
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.size = ProductPlaceholderSize.tile,
  });

  final Product product;
  final ProductPlaceholderSize size;

  /// Nomes do seed → assets em `assets/products/`.
  static const Map<String, String> assetsByName = {
    'Smart TV 50" 4K': 'assets/products/smart-tv-50.jpg',
    'Fone de Ouvido Bluetooth': 'assets/products/fone-bluetooth.jpg',
    'Tablet 10" 64GB': 'assets/products/tablet-10.jpg',
    'Caixa de Som Portátil': 'assets/products/caixa-som.jpg',
    'Mouse Gamer RGB': 'assets/products/mouse-gamer.jpg',
  };

  static String? assetFor(Product product) => assetsByName[product.name];

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(product);
    final radius = switch (size) {
      ProductPlaceholderSize.hero => 16.0,
      ProductPlaceholderSize.tile => 0.0,
      ProductPlaceholderSize.avatar => 12.0,
    };

    if (asset == null) {
      return ProductPlaceholder(
        category: product.category,
        name: product.name,
        size: size,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => ProductPlaceholder(
          category: product.category,
          name: product.name,
          size: size,
        ),
      ),
    );
  }
}
