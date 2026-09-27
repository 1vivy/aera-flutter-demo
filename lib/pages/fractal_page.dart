import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../src/rust/api/demo.dart';

/// The Mandelbrot set computed in Rust on every CPU core, shown by Flutter.
/// Tap to zoom in where you tap.
class FractalPage extends StatefulWidget {
  const FractalPage({super.key});

  @override
  State<FractalPage> createState() => _FractalPageState();
}

class _FractalPageState extends State<FractalPage> {
  double _x = -0.6, _y = 0, _scale = 3.2;
  ui.Image? _image;
  Size? _size;
  String _timing = '';
  int _generation = 0;

  Future<void> _render(Size size, double ratio) async {
    final generation = ++_generation;
    final width = (size.width * ratio).round();
    final height = (size.height * ratio).round();
    final watch = Stopwatch()..start();
    final pixels = await mandelbrot(
      width: width,
      height: height,
      centerX: _x,
      centerY: _y,
      scale: _scale,
      maxIterations: 400,
    );
    final rust = watch.elapsedMilliseconds;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;
    if (!mounted || generation != _generation) return;
    setState(() {
      _image = image;
      _timing = '${width}x$height in $rust ms';
    });
  }

  void _zoom(Offset position) {
    final size = _size!;
    final step = _scale / size.width;
    setState(() {
      _x += (position.dx - size.width / 2) * step;
      _y += (position.dy - size.height / 2) * step;
      _scale /= 2.5;
    });
    _render(size, MediaQuery.devicePixelRatioOf(context));
  }

  void _reset() {
    setState(() {
      _x = -0.6;
      _y = 0;
      _scale = 3.2;
    });
    _render(_size!, MediaQuery.devicePixelRatioOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _size) {
        _size = size;
        final ratio = MediaQuery.devicePixelRatioOf(context);
        scheduleMicrotask(() => _render(size, ratio));
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTapUp: (details) => _zoom(details.localPosition),
            child: _image == null
                ? const Center(child: CircularProgressIndicator())
                : RawImage(image: _image, fit: BoxFit.fill),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Chip(label: Text(_timing.isEmpty ? 'Rendering' : _timing)),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              onPressed: _reset,
              child: const Icon(Icons.zoom_out_map),
            ),
          ),
        ],
      );
    });
  }
}
