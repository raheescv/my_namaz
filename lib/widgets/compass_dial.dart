import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class CompassDial extends StatelessWidget {
  /// Current device heading in degrees (0 = N).
  final double heading;

  /// Qibla bearing (absolute, from north) in degrees.
  final double qiblaBearing;

  final double size;

  const CompassDial({
    super.key,
    required this.heading,
    required this.qiblaBearing,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Rotation of the dial so N points to true north relative to the device.
    final dialAngle = -heading * math.pi / 180;
    // Qibla needle on the dial, then dial rotates as a whole.
    final qiblaAngle = qiblaBearing * math.pi / 180;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 1.5),
            ),
          ),
          Transform.rotate(
            angle: dialAngle,
            child: CustomPaint(
              size: Size(size, size),
              painter: _DialPainter(
                onSurface: theme.colorScheme.onSurface,
                muted: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Qibla arrow rotates with dial
          Transform.rotate(
            angle: dialAngle + qiblaAngle,
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _QiblaArrowPainter(color: AppColors.primaryGreen),
              ),
            ),
          ),
          // Fixed center dot
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
          ),
          // Fixed top pointer triangle
          Positioned(
            top: 4,
            child: Icon(Icons.arrow_drop_down,
                size: 36, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final Color onSurface;
  final Color muted;
  _DialPainter({required this.onSurface, required this.muted});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tickPaint = Paint()..color = muted;
    final majorPaint = Paint()..color = onSurface..strokeWidth = 2;

    for (int deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      final tickLength = isMajor ? 14.0 : 6.0;
      final theta = (deg - 90) * math.pi / 180;
      final p1 = Offset(center.dx + (radius - 4) * math.cos(theta),
          center.dy + (radius - 4) * math.sin(theta));
      final p2 = Offset(
          center.dx + (radius - 4 - tickLength) * math.cos(theta),
          center.dy + (radius - 4 - tickLength) * math.sin(theta));
      canvas.drawLine(p1, p2, isMajor ? majorPaint : tickPaint);
    }

    final cardinals = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    for (final entry in cardinals.entries) {
      final theta = (entry.key - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: entry.key == 0 ? AppColors.primaryGreen : onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(
        center.dx + (radius - 32) * math.cos(theta) - tp.width / 2,
        center.dy + (radius - 32) * math.sin(theta) - tp.height / 2,
      );
      tp.paint(canvas, pos);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => false;
}

class _QiblaArrowPainter extends CustomPainter {
  final Color color;
  _QiblaArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - size.height / 2 + 24)
      ..lineTo(center.dx - 14, center.dy)
      ..lineTo(center.dx, center.dy - 8)
      ..lineTo(center.dx + 14, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
