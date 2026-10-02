/// Formata centavos como moeda brasileira, ex.: `249900` -> `R$ 2.499,00`.
String formatBrl(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = (abs ~/ 100).toString();
  final centavos = (abs % 100).toString().padLeft(2, '0');

  final grouped = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) grouped.write('.');
    grouped.write(reais[i]);
  }
  return '${negative ? '-' : ''}R\$ $grouped,$centavos';
}
