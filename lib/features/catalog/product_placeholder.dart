import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Placeholder offline elegante para produto (sem rede / CDN).
class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({
    super.key,
    this.category,
    this.name,
    this.size = ProductPlaceholderSize.tile,
  });

  final String? category;
  final String? name;
  final ProductPlaceholderSize size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = _iconFor(category);
    final initials = _initials(name);

    final isHero = size == ProductPlaceholderSize.hero;
    final radius = isHero ? 16.0 : 12.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            Color.lerp(
              AppColors.surfaceContainerHigh,
              _accentFor(category),
              .28,
            )!,
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
      child: Center(
        child: isHero
            ? Icon(icon, size: 72, color: scheme.primary)
            : Text(
                initials,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: size == ProductPlaceholderSize.avatar ? 14 : 18,
                ),
              ),
      ),
    );
  }

  static IconData _iconFor(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('fone') || c.contains('audio') || c.contains('áudio')) {
      return Icons.headphones;
    }
    if (c.contains('cabo') || c.contains('acess')) {
      return Icons.cable;
    }
    if (c.contains('note') || c.contains('comput') || c.contains('pc')) {
      return Icons.laptop_mac;
    }
    if (c.contains('celular') || c.contains('phone') || c.contains('smart')) {
      return Icons.smartphone;
    }
    return Icons.devices_other;
  }

  static Color _accentFor(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('fone') || c.contains('audio') || c.contains('áudio')) {
      return AppColors.lavender;
    }
    if (c.contains('cabo') || c.contains('acess')) {
      return AppColors.orange;
    }
    if (c.contains('note') || c.contains('comput') || c.contains('pc')) {
      return AppColors.blueJeans;
    }
    if (c.contains('celular') || c.contains('phone') || c.contains('smart')) {
      return AppColors.sussie;
    }
    return AppColors.primary;
  }

  static String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '·';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum ProductPlaceholderSize { avatar, tile, hero }
