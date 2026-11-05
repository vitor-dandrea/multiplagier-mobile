/// Item do carrinho com o preço e o estoque atuais do produto.
/// O total da linha é calculado aqui; o cliente não envia o valor.
class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
    required this.stock,
    required this.isActive,
  });

  factory CartLine.fromRow(Map<String, Object?> row) {
    return CartLine(
      productId: row['product_id'] as int,
      name: row['name'] as String,
      unitPriceCents: row['price_cents'] as int,
      quantity: row['quantity'] as int,
      stock: row['stock'] as int,
      isActive: (row['is_active'] as int) == 1,
    );
  }

  final int productId;
  final String name;
  final int unitPriceCents;
  final int quantity;
  final int stock;
  final bool isActive;

  int get lineTotalCents => unitPriceCents * quantity;

  /// Ainda pode ser comprado na quantidade que está no carrinho.
  bool get canCheckout => isActive && stock >= quantity;

  CartLine copyWith({
    int? quantity,
    int? stock,
    bool? isActive,
    int? unitPriceCents,
  }) {
    return CartLine(
      productId: productId,
      name: name,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }
}
