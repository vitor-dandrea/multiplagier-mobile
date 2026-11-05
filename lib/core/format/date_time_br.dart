/// Formata data no fuso local, ex.: `05/01/2026 09:07`.
String formatDateTimeBr(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
