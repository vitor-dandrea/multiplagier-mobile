class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.stock,
    required this.isActive,
  });

  factory Product.fromRow(Map<String, Object?> row) {
    return Product(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String,
      priceCents: row['price_cents'] as int,
      stock: row['stock'] as int,
      isActive: (row['is_active'] as int) == 1,
    );
  }

  final int id;
  final String name;
  final String description;
  final int priceCents;
  final int stock;
  final bool isActive;

  bool get isAvailable => stock > 0;
}
