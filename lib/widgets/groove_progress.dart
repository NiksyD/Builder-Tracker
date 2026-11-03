import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carved groove progress bar. value 0..1.
class GrooveProgress extends StatelessWidget {
  final double value;
  final Color color;
  const GrooveProgress({super.key, required this.value, this.color = Pal.green});

  @override
  Widget build(BuildContext context) => Container(
        height: 18,
        decoration: BoxDecoration(
          color: Pal.woodDark,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Pal.ink, width: 1.5),
        ),
        padding: const EdgeInsets.all(1.5),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(color, Colors.white, .35)!, color, Color.lerp(color, Colors.black, .3)!],
              ),
            ),
          ),
        ),
      );
}
