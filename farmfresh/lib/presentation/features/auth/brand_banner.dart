import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Premium auth banner: a gold leaf sprig in a glowing ring over a deep-green
/// gradient, with the serif wordmark, a gold rule, and an uppercase tagline.
/// Shared by the sign-in and verify-code screens.
class BrandAuthBanner extends StatelessWidget {
  const BrandAuthBanner({
    super.key,
    this.title = 'Green Epicure',
    this.tagline = 'Fine everyday provisions',
    this.compact = false,
    this.onBack,
  });

  final String title;
  final String tagline;
  final bool compact;
  final VoidCallback? onBack;

  static const cream = Color(0xFFF4ECD8);
  static const gold = Color(0xFFD8B46A);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final ring = compact ? 78.0 : 104.0;
    final sprig = compact ? 40.0 : 52.0;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
              top: top + (compact ? 36 : 50),
              bottom: compact ? 34 : 46,
              left: 26,
              right: 26),
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.7),
              radius: 1.25,
              colors: [
                Color(0xFF2E6B47),
                Color(0xFF1F4632),
                Color(0xFF123020),
                Color(0xFF0A1F14),
              ],
              stops: [0.0, 0.4, 0.72, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ring,
                height: ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                        color: gold.withValues(alpha: 0.16),
                        blurRadius: 40,
                        spreadRadius: 3),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: sprig,
                    height: sprig * 1.19,
                    child: const CustomPaint(painter: _SprigPainter(gold)),
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: compact ? 22 : 32,
                      fontWeight: FontWeight.w600,
                      color: cream,
                      letterSpacing: 0.3)),
              const SizedBox(height: 12),
              Container(width: 36, height: 2, color: gold.withValues(alpha: 0.85)),
              const SizedBox(height: 12),
              Text(tagline.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 3,
                      color: Color(0xFFC3B790),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onBack != null)
          Positioned(
            top: top + 4,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(color: gold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.chevron_left, color: gold, size: 22),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SprigPainter extends CustomPainter {
  const _SprigPainter(this.color);
  final Color color;

  // base x, base y, rotation°, scale — leaves fanning from the stem.
  static const _leaves = <List<double>>[
    [50, 98, -54, 1.0],
    [50, 82, 56, 1.0],
    [50, 66, -50, 0.9],
    [50, 52, 52, 0.8],
    [50, 40, 0, 0.72],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 120);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stem = Path()
      ..moveTo(50, 116)
      ..cubicTo(46, 92, 54, 68, 50, 42)
      ..cubicTo(48, 32, 50, 24, 50, 14);
    canvas.drawPath(stem, p);

    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(8, -11, 8, -28, 0, -40)
      ..cubicTo(-8, -28, -8, -11, 0, 0)
      ..close();
    final mid = Path()
      ..moveTo(0, -6)
      ..lineTo(0, -34);

    for (final l in _leaves) {
      canvas.save();
      canvas.translate(l[0], l[1]);
      canvas.rotate(l[2] * math.pi / 180);
      canvas.scale(l[3]);
      canvas.drawPath(leaf, p);
      canvas.drawPath(mid, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SprigPainter old) => old.color != color;
}
