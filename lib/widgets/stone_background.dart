import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Procedural dungeon-wall: staggered stone blocks with speckle + vignette.
class StoneBackground extends StatelessWidget {
  final Widget child;
  const StoneBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const RepaintBoundary(child: CustomPaint(painter: _StonePainter())),
        child,
      ]);
}

class _StonePainter extends CustomPainter {
  const _StonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    canvas.drawRect(Offset.zero & size, Paint()..color = Pal.stoneDark);
    const rowH = 56.0;
    var y = 0.0, row = 0;
    while (y < size.height) {
      var x = row.isEven ? 0.0 : -40.0;
      while (x < size.width) {
        final w = 80 + rnd.nextDouble() * 70;
        final shade = Color.lerp(Pal.stoneDark, Pal.stoneLight, rnd.nextDouble() * 0.7)!;
        final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 1.5, y + 1.5, w - 3, rowH - 3), const Radius.circular(5));
        canvas.drawRRect(r, Paint()..color = shade);
        // top highlight / bottom shadow
        canvas.drawRRect(
            r.deflate(1),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..shader = const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33FFFFFF), Color(0x55000000)])
                  .createShader(r.outerRect));
        for (var i = 0; i < 14; i++) {
          canvas.drawCircle(
              Offset(x + rnd.nextDouble() * w, y + rnd.nextDouble() * rowH),
              rnd.nextDouble() * 1.2,
              Paint()..color = Colors.black.withValues(alpha: 0.25));
        }
        x += w;
      }
      y += rowH;
      row++;
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            radius: 1.1,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            stops: const [0.45, 1],
          ).createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
