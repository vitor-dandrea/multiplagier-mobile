import 'package:flutter/material.dart';

import '../../core/colors.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.canvas,
            Color.lerp(AppColors.surface, AppColors.primaryContainer, .55)!,
            AppColors.surfaceContainer,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: .35),
                    ),
                  ),
                  child: Icon(
                    Icons.devices_other,
                    size: 28,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Multiplagier',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Eletrônicos e acessórios',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
