import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Parchment scroll card with slightly ragged edges and a stained vignette.
class ParchmentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const ParchmentCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(12), this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _ParchmentPainter(),
          child: Padding(padding: padding, child: child),
        ),
      );
}

class _ParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(size.width.toInt() ^ size.height.toInt());
    final path = Path();
    const step = 14.0;
    double j() => rnd.nextDouble() * 2.5;
    path.moveTo(j(), j());
    for (var x = step; x < size.width; x += step) {
      path.lineTo(x, j());
    }
    for (var y = step; y < size.height; y += step) {
      path.lineTo(size.width - j(), y);
    }
    for (var x = size.width - step; x > 0; x -= step) {
      path.lineTo(x, size.height - j());
    }
    for (var y = size.height - step; y > 0; y -= step) {
      path.lineTo(j(), y);
    }
    path.close();
    final rect = Offset.zero & size;
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            radius: 1.0,
            colors: const [Pal.parchment, Pal.parchment, Pal.parchmentDark],
            stops: const [0, 0.65, 1],
          ).createShader(rect));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Pal.goldDark.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
