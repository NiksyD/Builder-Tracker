import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wooden plank panel with iron rivets in the corners.
class WoodPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const WoodPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _WoodPainter(),
        child: Padding(padding: padding, child: child),
      );
}

class _WoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(rr), Colors.black, 8, true);
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Pal.woodLight, Pal.wood, Pal.woodDark])
              .createShader(rect));
    canvas.save();
    canvas.clipRRect(rr);
    final rnd = Random(size.height.toInt());
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = 6.0; y < size.height; y += 7 + rnd.nextDouble() * 6) {
      grain.color = Colors.black.withValues(alpha: 0.10 + rnd.nextDouble() * 0.12);
      final p = Path()..moveTo(0, y);
      p.cubicTo(size.width * .3, y + rnd.nextDouble() * 4 - 2, size.width * .6,
          y + rnd.nextDouble() * 4 - 2, size.width, y + rnd.nextDouble() * 3);
      canvas.drawPath(p, grain);
    }
    canvas.restore();
    canvas.drawRRect(
        rr.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Pal.woodDark);
    canvas.drawRRect(
        rr.deflate(4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.12));
    for (final o in [
      const Offset(10, 10),
      Offset(size.width - 10, 10),
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
    ]) {
      canvas.drawCircle(o, 3.5, Paint()..color = Pal.iron);
      canvas.drawCircle(o.translate(-1, -1), 1.3, Paint()..color = Colors.white54);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
