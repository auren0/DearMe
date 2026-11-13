import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import '../../../../app/theme/app_theme.dart';

/// Decorative sealed envelope. When [openProgress] animates from 0 to 1 the
/// wax seal fades and the flap opens in 3D.
class EnvelopeArt extends StatelessWidget {
  const EnvelopeArt({
    super.key,
    this.width = 280,
    this.openProgress = 0,
    this.semanticLabel,
  });

  final double width;
  final double openProgress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DearMePalette>()!;
    final scheme = Theme.of(context).colorScheme;
    final height = width * 0.68;
    final progress = openProgress.clamp(0.0, 1.0);

    final envelope = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: width * 0.1,
            right: width * 0.1,
            top: height * 0.18 - progress * 52,
            height: height * 0.78,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.letterPaper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.grain.withValues(alpha: 0.7)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  width * 0.07,
                  height * 0.16,
                  width * 0.07,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 2,
                      width: width * 0.28,
                      color: palette.grain.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 2,
                      width: width * 0.4,
                      color: palette.grain.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _EnvelopeBodyPainter(
                bodyColor: palette.envelope,
                lineColor: palette.grain,
                shadowColor: Colors.black.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: height * 0.16,
            height: height * 0.5,
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(-math.pi * 0.92 * progress),
              child: CustomPaint(
                painter: _EnvelopeFlapPainter(
                  color: palette.envelopeFlap,
                  lineColor: palette.grain,
                ),
              ),
            ),
          ),
          Positioned(
            top: height * 0.42,
            left: width / 2 - width * 0.085,
            child: Opacity(
              opacity: (1 - progress * 1.3).clamp(0.0, 1.0),
              child: Container(
                width: width * 0.17,
                height: width * 0.17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.waxSeal,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: scheme.surface.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  FluentIcons.filled.heart,
                  size: width * 0.075,
                  color: scheme.onError.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return RepaintBoundary(child: envelope);
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: RepaintBoundary(child: envelope)),
    );
  }
}

class _EnvelopeBodyPainter extends CustomPainter {
  const _EnvelopeBodyPainter({
    required this.bodyColor,
    required this.lineColor,
    required this.shadowColor,
  });

  final Color bodyColor;
  final Color lineColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.84),
      const Radius.circular(13),
    );

    canvas.drawRRect(
      rect.shift(const Offset(0, 5)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(rect, Paint()..color = bodyColor);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Colors.white.withValues(alpha: 0.045),
        Colors.black.withValues(alpha: 0.08),
      ],
    );
    canvas.drawRRect(
      rect,
      Paint()..shader = gradient.createShader(rect.outerRect),
    );

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rect, linePaint);

    final fold = Path()
      ..moveTo(rect.left + 2, size.height * 0.34)
      ..lineTo(size.width / 2, size.height * 0.66)
      ..lineTo(rect.right - 2, size.height * 0.34);
    canvas.drawPath(fold, linePaint);
  }

  @override
  bool shouldRepaint(_EnvelopeBodyPainter oldDelegate) {
    return oldDelegate.bodyColor != bodyColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class _EnvelopeFlapPainter extends CustomPainter {
  const _EnvelopeFlapPainter({required this.color, required this.lineColor});

  final Color color;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final flap = Path()
      ..moveTo(2, 0)
      ..lineTo(size.width / 2, size.height * 0.94)
      ..lineTo(size.width - 2, 0)
      ..lineTo(size.width - 2, 2)
      ..lineTo(size.width / 2, size.height * 0.82)
      ..lineTo(2, 2)
      ..close();

    final fill = Path()
      ..moveTo(1, 0)
      ..lineTo(size.width / 2, size.height * 0.94)
      ..lineTo(size.width - 1, 0)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color, Color.lerp(color, Colors.black, 0.09)!],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      flap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = lineColor.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_EnvelopeFlapPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.lineColor != lineColor;
  }
}
