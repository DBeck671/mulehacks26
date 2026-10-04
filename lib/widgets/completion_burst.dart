import 'dart:math';

import 'package:flutter/material.dart';

import 'common.dart';

class CompletionBurst extends StatelessWidget {
  const CompletionBurst({super.key, required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    width: double.infinity,
    child: CustomPaint(
      painter: _BurstPainter(progress),
      child: Center(
        child: Transform.scale(
          scale: .7 + .3 * Curves.easeOutBack.transform(min(1, progress * 4)),
          child: const Icon(Icons.check_circle_rounded, color: green, size: 64),
        ),
      ),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final p = min(1.0, progress * 2.2);
    if (p >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 20; i++) {
      final angle = i * pi / 10;
      final radius = 32 + p * (35 + i % 4 * 8);
      final position = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(
        position,
        (i % 3 + 2) * (1 - p),
        Paint()
          ..color = (i.isEven ? green : const Color(0xFFFFD590)).withValues(
            alpha: 1 - p,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
