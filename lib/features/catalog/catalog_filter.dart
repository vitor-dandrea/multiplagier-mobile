import '../../data/models/product.dart';

/// Filtra o catálogo por texto (nome/descrição) e categoria (US-009).
List<Product> filterCatalog(
  List<Product> products, {
  String query = '',
  String? category,
}) {
  final normalized = query.trim().toLowerCase();
  return products.where((product) {
    if (category != null &&
        category.isNotEmpty &&
        product.category != category) {
      return false;
    }
    if (normalized.isEmpty) return true;
    return product.name.toLowerCase().contains(normalized) ||
        product.description.toLowerCase().contains(normalized);
  }).toList();
}

/// Categorias distintas dos produtos, em ordem alfabética.
List<String> catalogCategories(List<Product> products) {
  final categories = products.map((p) => p.category).toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return categories;
}
