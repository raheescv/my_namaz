import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/prayer_enum.dart';
import '../theme/colors.dart';

/// Circular progress ring counting down to the next prayer.
///
/// [progress] is 0.0 (just started counting from previous prayer) → 1.0
/// (arrived at the next prayer). Uses a brand-aligned green→teal→gold
/// gradient and a soft trailing dot at the leading edge.
class PrayerCountdownRing extends StatelessWidget {
  final double progress; // 0..1
  final String timeLeft; // e.g. "1h 23m"
  final String label; // e.g. "left until"
  final String prayerName;
  final String prayerTime;
  final Prayer? prayer;
  final double size;

  const PrayerCountdownRing({
    super.key,
    required this.progress,
    required this.timeLeft,
    required this.label,
    required this.prayerName,
    required this.prayerTime,
    this.prayer,
    this.size = 260,
  });

  IconData _iconFor(Prayer? p) {
    switch (p) {
      case Prayer.fajr:
        return Icons.wb_twilight;
      case Prayer.dhuhr:
        return Icons.wb_sunny_outlined;
      case Prayer.asr:
        return Icons.wb_cloudy_outlined;
      case Prayer.maghrib:
        return Icons.nights_stay_outlined;
      case Prayer.isha:
        return Icons.dark_mode_outlined;
      case null:
        return Icons.mosque_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.35),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(prayer),
                size: size * 0.07,
                color: AppColors.primaryGreen,
              ),
              SizedBox(height: size * 0.02),
              Text(
                timeLeft,
                style: TextStyle(
                  fontSize: size * 0.17,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(height: size * 0.015),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: size * 0.03),
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: size * 0.115,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: size * 0.008),
              Text(
                prayerTime,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  _RingPainter({required this.progress, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.05;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Foreground gradient arc — brand colors (green → teal → gold)
    final sweep = 2 * math.pi * progress;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: const [
        AppColors.primaryGreen,
        Color(0xFF2E86AB),
        AppColors.accentGold,
      ],
      stops: const [0.0, 0.7, 1.0],
      tileMode: TileMode.clamp,
    );
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);

    // Leading dot (soft glow at the end of the arc)
    final endAngle = -math.pi / 2 + sweep;
    final endPoint = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final glowPaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(endPoint, strokeWidth * 0.9, glowPaint);
    final dotPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, strokeWidth * 0.55, dotPaint);
    final dotInnerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, strokeWidth * 0.22, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor;
}
