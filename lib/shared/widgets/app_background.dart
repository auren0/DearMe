import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A calm layered background used by every top-level screen.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.showGlow = true});

  final Widget child;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DearMePalette>()!;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                palette.heroStart,
                theme.colorScheme.surface,
                palette.heroEnd,
              ],
              stops: const <double>[0, 0.55, 1],
            ),
          ),
        ),
        if (showGlow)
          Positioned(
            top: -160,
            right: -120,
            width: 420,
            height: 420,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      palette.glow.withValues(alpha: 0.16),
                      palette.glow.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GrainPainter(color: palette.grain)),
          ),
        ),
        child,
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    const count = 90;
    for (var i = 0; i < count; i++) {
      final x = (math.sin(i * 12.9898) * 43758.5453).abs() % 1;
      final y = (math.sin((i + 37) * 78.233) * 12345.6789).abs() % 1;
      final radius = i % 7 == 0 ? 1.4 : 0.8;
      canvas.drawCircle(Offset(x * size.width, y * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => oldDelegate.color != color;
}
