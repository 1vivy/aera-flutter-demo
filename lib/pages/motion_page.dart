import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A continuous animation with a frame-rate meter, to see how smoothly the
/// GPU keeps up.
class MotionPage extends StatefulWidget {
  const MotionPage({super.key});

  @override
  State<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<MotionPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  final _frames = <Duration>[];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed);
      _frames.add(elapsed);
      while (_frames.isNotEmpty &&
          elapsed - _frames.first > const Duration(seconds: 1)) {
        _frames.removeAt(0);
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
            painter: _Orbits(_elapsed.inMicroseconds / 1e6,
                Theme.of(context).colorScheme)),
        Positioned(
          left: 12,
          top: 12,
          child: Chip(label: Text('${_frames.length} fps')),
        ),
      ],
    );
  }
}

class _Orbits extends CustomPainter {
  _Orbits(this.time, this.colors);

  final double time;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var ring = 0; ring < 8; ring++) {
      final radius = 30.0 + ring * 18;
      final count = 6 + ring * 3;
      final speed = (ring.isEven ? 1 : -1) * (0.6 + ring * 0.1);
      paint.color = Color.lerp(colors.primary, colors.tertiary, ring / 7)!
          .withValues(alpha: 0.85);
      for (var i = 0; i < count; i++) {
        final angle = time * speed + i * 2 * pi / count;
        final wobble = 1 + 0.08 * sin(time * 3 + i);
        final position =
            center + Offset(cos(angle), sin(angle)) * radius * wobble;
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle * 2);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(-5, -5, 10, 10), const Radius.circular(3)),
            paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_Orbits old) => old.time != time;
}
