import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decorative background used across auth and splash surfaces.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topColor = isDark ? AppColors.darkBackground : AppColors.background;
    final midColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final bottomColor =
        isDark ? AppColors.darkBackground : AppColors.shellBackground;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, midColor, bottomColor],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(
              size: 260,
              color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.12),
            ),
          ),
          Positioned(
            top: 120,
            right: -70,
            child: _GlowBlob(
              size: 220,
              color: AppColors.accent.withOpacity(isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned(
            bottom: -100,
            right: 20,
            child: _GlowBlob(
              size: 280,
              color: AppColors.primaryLight.withOpacity(isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.02)],
        ),
      ),
    );
  }
}
