import 'dart:math' as math;
import 'package:flutter/material.dart';

class HourglassLoader extends StatefulWidget {
  final double size;
  final Duration cycle;
  const HourglassLoader({
    super.key,
    this.size = 96,
    this.cycle = const Duration(seconds: 2),
  });

  @override
  State<HourglassLoader> createState() => _HourglassLoaderState();
}

class _HourglassLoaderState extends State<HourglassLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.cycle)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double t = _ctrl.value; // 0..1
        // Sand amount top->bottom over first half, then flip
        final double phase = (t * 2) % 2; // 0..2
        final bool flipped = t >= 0.5;
        final double fillTop = (1 - phase.clamp(0, 1));
        final double fillBottom = phase.clamp(0, 1);
        return Transform.rotate(
          angle: flipped ? math.pi : 0,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _HourglassPainter(
              fillTop: fillTop,
              fillBottom: fillBottom,
            ),
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double fillTop; // 0..1
  final double fillBottom; // 0..1
  _HourglassPainter({required this.fillTop, required this.fillBottom});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint frame = Paint()
      ..color = const Color(0xFFDDC2B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Paint sand = Paint()..color = const Color(0xFFE48D6B);

    final double w = size.width;
    final double h = size.height;
    final Rect rect = Offset.zero & size;
    final RRect bg = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(bg, Paint()..color = const Color(0xFFFBF7F3));

    // Outline hourglass shape
    final Path outline = Path()
      ..moveTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.8, h * 0.15)
      ..lineTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.8, h * 0.85)
      ..lineTo(w * 0.2, h * 0.85)
      ..lineTo(w * 0.45, h * 0.5)
      ..close();
    canvas.drawPath(outline, frame);

    // Top sand polygon (triangle tapering to center)
    if (fillTop > 0) {
      final double topY = h * (0.15 + 0.35 * (1 - fillTop));
      final Path top = Path()
        ..moveTo(w * 0.2, h * 0.15)
        ..lineTo(w * 0.8, h * 0.15)
        ..lineTo(w * 0.5, topY)
        ..close();
      canvas.drawPath(top, sand);
    }

    // Falling sand stream
    canvas.drawLine(
      Offset(w * 0.5, h * 0.5 - 8),
      Offset(w * 0.5, h * 0.5 + 8),
      sand..strokeWidth = 2,
    );

    // Bottom sand polygon (triangle filling up)
    if (fillBottom > 0) {
      final double botY = h * (0.85 - 0.35 * (fillBottom));
      final Path bottom = Path()
        ..moveTo(w * 0.2, h * 0.85)
        ..lineTo(w * 0.8, h * 0.85)
        ..lineTo(w * 0.5, botY)
        ..close();
      canvas.drawPath(bottom, sand);
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) =>
      oldDelegate.fillTop != fillTop || oldDelegate.fillBottom != fillBottom;
}
