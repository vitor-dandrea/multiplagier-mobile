/// Validação local de endereço BR (offline, sem ViaCEP).
abstract final class AddressRules {
  static const emptyStreetMessage = 'Informe a rua.';
  static const emptyNumberMessage = 'Informe o número.';
  static const emptyDistrictMessage = 'Informe o bairro.';
  static const emptyCityMessage = 'Informe a cidade.';
  static const emptyStateMessage = 'Informe a UF.';
  static const invalidStateMessage = 'UF inválida (2 letras).';
  static const emptyZipMessage = 'Informe o CEP.';
  static const invalidZipMessage = 'CEP inválido (8 dígitos).';

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static bool isValidZip(String raw) => digitsOnly(raw).length == 8;

  static bool isValidState(String raw) {
    final uf = raw.trim().toUpperCase();
    return RegExp(r'^[A-Z]{2}$').hasMatch(uf);
  }

  static bool isNonEmpty(String? raw) => (raw?.trim().isNotEmpty ?? false);
}
