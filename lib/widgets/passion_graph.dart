import 'package:flutter/material.dart';
import '../models/passion_graph.dart';

class PassionGraph extends StatelessWidget {
  final GraphSnapshot snapshot;

  const PassionGraph({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _GraphPainter(
        nodes: snapshot.nodes,
        edges: snapshot.edges,
        isDark: isDark,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<PassionNode> nodes;
  final List<GraphEdge> edges;
  final bool isDark;

  _GraphPainter({required this.nodes, required this.edges, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    // Subtle grid overlay; no background fill so it blends with page/theme
    final Color gridColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFEEEEEE);
    final Paint grid = Paint()..color = gridColor..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Edges
    final Paint edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final e in edges) {
      final a = nodes.firstWhere((n) => n.id == e.sourceId);
      final b = nodes.firstWhere((n) => n.id == e.targetId);
      final p1 = center + Offset(a.x, a.y);
      final p2 = center + Offset(b.x, b.y);
      edgePaint.color = (isDark ? Colors.white : Colors.black).withValues(
        alpha: (isDark ? 0.10 : 0.10) + 0.25 * e.weight,
      );
      edgePaint.strokeWidth = 0.5 + 1.6 * e.weight;
      final mid = Offset(
        (p1.dx + p2.dx) / 2,
        (p1.dy + p2.dy) / 2 + 10 * (1 - e.weight),
      );
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      canvas.drawPath(path, edgePaint);
    }

    // Nodes and labels
    final List<Rect> placed = <Rect>[];
    for (final n in nodes) {
      final Offset p = center + Offset(n.x, n.y);
      final double r = n.radius;
      final Color color = HSLColor.fromAHSL(
        1,
        (n.colorSeed % 360).toDouble(),
        isDark ? 0.55 : 0.45, // a touch more saturated on dark
        isDark ? 0.64 : 0.58, // slightly brighter on dark
      ).toColor();

      // glow
      final Paint glow = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(p, r + 6, glow);

      // node
      final Paint nodePaint = Paint()..color = color;
      canvas.drawCircle(p, r, nodePaint);

      // label
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      // compute pill rect and avoid collisions by shifting down in small steps
      Rect labelRect = Offset(p.dx + r + 6, p.dy - tp.height / 2) & tp.size;
      int safety = 0;
      while (placed.any((other) => other.overlaps(labelRect)) && safety < 8) {
        labelRect = labelRect.translate(0, tp.height + 2);
        safety++;
      }
      placed.add(labelRect.inflate(2));

      // pill background
      final RRect pill = RRect.fromRectAndRadius(
        labelRect.inflate(4),
        const Radius.circular(8),
      );
      final Paint pillPaint = Paint()
        ..color = (isDark
                ? Colors.black.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.9))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0);
      canvas.drawRRect(pill, pillPaint);

      // text
      tp.paint(canvas, labelRect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
