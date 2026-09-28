import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';

/// The Mandelbrot set computed by the Rust core (on every CPU natively,
/// in core.wasm on the web), shown by Flutter. Drag to move, pinch to zoom,
/// tap to zoom in where you tap. The current image follows your fingers at
/// once; Rust redraws when they lift.
class FractalPage extends StatefulWidget {
  const FractalPage({super.key});

  @override
  State<FractalPage> createState() => _FractalPageState();
}

/// A view of the complex plane: its centre and its width.
typedef _View = ({double x, double y, double scale});

class _FractalPageState extends State<FractalPage> {
  static const _home = (x: -0.6, y: 0.0, scale: 3.2);

  /// What the screen should show.
  _View _view = _home;

  /// What `_image` shows.
  _View _imageView = _home;
  ui.Image? _image;
  Size? _size;
  String _timing = '';
  String? _unavailable;
  int _generation = 0;

  _View? _gestureStart;
  Offset _gestureFocal = Offset.zero;

  /// Shows a quarter-resolution preview first, then the full image.
  Future<void> _render() async {
    final size = _size;
    if (size == null) return;
    // core.wasm is single-threaded and runs on the page's only thread, so
    // the web draws at one pixel per logical pixel.
    final ratio = kIsWeb ? 1.0 : MediaQuery.devicePixelRatioOf(context);
    final generation = ++_generation;
    if (_timing.isNotEmpty) setState(() => _timing = '');
    await _renderAt(size, ratio / 4, generation, preview: true);
    // Let the preview reach the screen before the full render blocks.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await _renderAt(size, ratio, generation, preview: false);
  }

  Future<void> _renderAt(
    Size size,
    double ratio,
    int generation, {
    required bool preview,
  }) async {
    if (!mounted || generation != _generation) return;
    final view = _view;
    final width = max(1, (size.width * ratio).round());
    final height = max(1, (size.height * ratio).round());
    final watch = Stopwatch()..start();
    final Uint8List pixels;
    try {
      pixels = Surface.instance.core.bytes('mandelbrot', {
        'width': width,
        'height': height,
        'x': view.x,
        'y': view.y,
        'scale': view.scale,
        'iterations': 400,
      });
    } on OpsException catch (error) {
      if (mounted) setState(() => _unavailable = error.message);
      return;
    }
    final rust = watch.elapsedMilliseconds;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (!mounted || generation != _generation) return;
    setState(() {
      _image = image;
      _imageView = view;
      if (!preview) {
        _timing = 'Rust $rust ms, shown in ${watch.elapsedMilliseconds} ms';
      }
    });
  }

  /// The complex-plane point under a screen position in `view`.
  Offset _point(_View view, Offset position) {
    final size = _size!;
    final step = view.scale / size.width;
    return Offset(
      view.x + (position.dx - size.width / 2) * step,
      view.y + (position.dy - size.height / 2) * step,
    );
  }

  /// The view of width `scale` that puts `point` under `position`.
  _View _viewWith(double scale, Offset point, Offset position) {
    final size = _size!;
    final step = scale / size.width;
    return (
      x: point.dx - (position.dx - size.width / 2) * step,
      y: point.dy - (position.dy - size.height / 2) * step,
      scale: scale,
    );
  }

  void _zoom(Offset position) {
    setState(
      () => _view = (
        x: _point(_view, position).dx,
        y: _point(_view, position).dy,
        scale: _view.scale / 2.5,
      ),
    );
    _render();
  }

  void _reset() {
    setState(() => _view = _home);
    _render();
  }

  void _gestureBegan(ScaleStartDetails details) {
    _generation++; // drop renders still in flight
    _gestureStart = _view;
    _gestureFocal = details.localFocalPoint;
  }

  void _gestureMoved(ScaleUpdateDetails details) {
    final start = _gestureStart;
    if (start == null) return;
    final scale = start.scale / details.scale.clamp(0.05, 50);
    setState(
      () => _view = _viewWith(
        scale,
        _point(start, _gestureFocal),
        details.localFocalPoint,
      ),
    );
  }

  void _gestureEnded(ScaleEndDetails details) {
    if (_gestureStart == null) return;
    _gestureStart = null;
    _render();
  }

  /// Places the last image where its part of the plane is in `_view`, so it
  /// moves with the fingers until the new render arrives.
  Matrix4 _imageTransform() {
    final size = _size!;
    final step = _view.scale / size.width;
    final factor = _imageView.scale / _view.scale;
    // Where the image's top-left corner belongs on screen now.
    final corner = _point(_imageView, Offset.zero);
    final dx = size.width / 2 + (corner.dx - _view.x) / step;
    final dy = size.height / 2 + (corner.dy - _view.y) / step;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(factor, factor, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fractal')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final unavailable = _unavailable;
    if (unavailable != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No Rust core here: $unavailable'),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size) {
          _size = size;
          scheduleMicrotask(_render);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _zoom(details.localPosition),
              onScaleStart: _gestureBegan,
              onScaleUpdate: _gestureMoved,
              onScaleEnd: _gestureEnded,
              child: _image == null
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRect(
                      child: Transform(
                        transform: _imageTransform(),
                        child: RawImage(image: _image, fit: BoxFit.fill),
                      ),
                    ),
            ),
            Positioned(
              left: 12,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: Chip(label: Text(_timing.isEmpty ? 'Rendering' : _timing)),
            ),
            Positioned(
              right: 12,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: FloatingActionButton.small(
                onPressed: _reset,
                child: const Icon(Icons.zoom_out_map),
              ),
            ),
          ],
        );
      },
    );
  }
}
