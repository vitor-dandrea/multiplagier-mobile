/// Endereço de entrega BR (um por usuário; congelado no pedido).
class ShippingAddress {
  const ShippingAddress({
    required this.street,
    required this.number,
    this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.zip,
  });

  factory ShippingAddress.fromUserRow(Map<String, Object?> row) {
    return ShippingAddress(
      street: (row['address_street'] as String?)?.trim() ?? '',
      number: (row['address_number'] as String?)?.trim() ?? '',
      complement: _emptyToNull(row['address_complement'] as String?),
      district: (row['address_district'] as String?)?.trim() ?? '',
      city: (row['address_city'] as String?)?.trim() ?? '',
      state: (row['address_state'] as String?)?.trim().toUpperCase() ?? '',
      zip: (row['address_zip'] as String?)?.trim() ?? '',
    );
  }

  factory ShippingAddress.fromOrderRow(Map<String, Object?> row) {
    return ShippingAddress(
      street: (row['shipping_street'] as String?)?.trim() ?? '',
      number: (row['shipping_number'] as String?)?.trim() ?? '',
      complement: _emptyToNull(row['shipping_complement'] as String?),
      district: (row['shipping_district'] as String?)?.trim() ?? '',
      city: (row['shipping_city'] as String?)?.trim() ?? '',
      state: (row['shipping_state'] as String?)?.trim().toUpperCase() ?? '',
      zip: (row['shipping_zip'] as String?)?.trim() ?? '',
    );
  }

  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;
  final String zip;

  bool get isComplete =>
      street.isNotEmpty &&
      number.isNotEmpty &&
      district.isNotEmpty &&
      city.isNotEmpty &&
      state.length == 2 &&
      zip.replaceAll(RegExp(r'\D'), '').length == 8;

  /// Linhas para exibição (sem CEP formatado separado).
  List<String> get formattedLines {
    final line1 = [
      street,
      number,
      if (complement != null && complement!.isNotEmpty) complement!,
    ].join(', ');
    final zipDigits = zip.replaceAll(RegExp(r'\D'), '');
    final zipFmt = zipDigits.length == 8
        ? '${zipDigits.substring(0, 5)}-${zipDigits.substring(5)}'
        : zip;
    return [
      line1,
      '$district — $city/$state',
      'CEP $zipFmt',
    ];
  }

  String get singleLine => formattedLines.join(' · ');

  Map<String, Object?> toUserColumns() => {
    'address_street': street.trim(),
    'address_number': number.trim(),
    'address_complement': complement?.trim(),
    'address_district': district.trim(),
    'address_city': city.trim(),
    'address_state': state.trim().toUpperCase(),
    'address_zip': zip.replaceAll(RegExp(r'\D'), ''),
  };

  Map<String, Object?> toOrderColumns() => {
    'shipping_street': street.trim(),
    'shipping_number': number.trim(),
    'shipping_complement': complement?.trim(),
    'shipping_district': district.trim(),
    'shipping_city': city.trim(),
    'shipping_state': state.trim().toUpperCase(),
    'shipping_zip': zip.replaceAll(RegExp(r'\D'), ''),
  };

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
