import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:surfaces/surfaces.dart';

/// A continuous animation with a frame-rate meter, to see how smoothly the
/// host keeps up. Under AERA it also shows the embedder's own per-frame
/// timings and the GPU clock, read through the ops.
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
  Timer? _statsTimer;
  String _stats = '';

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
    })..start();
    _statsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _readStats(),
    );
  }

  /// The embedder rewrites this file every 120 frames.
  static const _statsFile = '/tmp/aera-flutter-stats';

  Future<void> _readStats() async {
    final surface = Surface.instance;
    if (surface.info.kind != HostKind.aera || _reading) return;
    _reading = true;
    try {
      final result = await surface.shell.exec(
        'cat $_statsFile 2>/dev/null; cat /sys/class/kgsl/kgsl-3d0/gpuclk 2>/dev/null',
      );
      final text = result.stdout.trim();
      if (text != _stats && mounted) setState(() => _stats = text);
    } finally {
      _reading = false;
    }
  }

  bool _reading = false;

  @override
  void dispose() {
    _statsTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motion')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _Orbits(
            _elapsed.inMicroseconds / 1e6,
            Theme.of(context).colorScheme,
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text('${_frames.length} fps')),
              if (_stats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _stats,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
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
      paint.color = Color.lerp(
        colors.primary,
        colors.tertiary,
        ring / 7,
      )!.withValues(alpha: 0.85);
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
            const Rect.fromLTWH(-5, -5, 10, 10),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_Orbits old) => old.time != time;
}
