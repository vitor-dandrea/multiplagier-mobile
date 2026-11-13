import 'shipping_address.dart';

/// Usuário autenticado. Nunca carrega o hash da senha.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
  });

  factory User.fromRow(Map<String, Object?> row) {
    final address = ShippingAddress.fromUserRow(row);
    return User(
      id: row['id'] as int,
      name: row['name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
      address: address.isComplete || _hasAnyAddressField(address)
          ? address
          : null,
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
  final ShippingAddress? address;

  bool get hasCompleteAddress => address?.isComplete ?? false;

  User copyWith({
    String? name,
    ShippingAddress? address,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      address: address ?? this.address,
    );
  }

  static bool _hasAnyAddressField(ShippingAddress a) {
    return a.street.isNotEmpty ||
        a.number.isNotEmpty ||
        a.district.isNotEmpty ||
        a.city.isNotEmpty ||
        a.state.isNotEmpty ||
        a.zip.isNotEmpty ||
        (a.complement?.isNotEmpty ?? false);
  }
}
