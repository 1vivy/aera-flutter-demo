import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// The safe area, keyboard, full screen and status bar icons, live.
class WindowPage extends StatefulWidget {
  const WindowPage({super.key});

  @override
  State<WindowPage> createState() => _WindowPageState();
}

class _WindowPageState extends State<WindowPage> {
  bool _overlay = false;

  static String _insets(EdgeInsets e) =>
      'top ${e.top.round()}, bottom ${e.bottom.round()}, left ${e.left.round()}, right ${e.right.round()}';

  @override
  Widget build(BuildContext context) {
    final window = Surface.instance.window;
    final media = MediaQuery.of(context);
    final page = DemoScaffold(
      title: 'Window',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(
                capability: Cap.insets,
                fallback: 'Assumes no bars cover the app',
              ),
              CapabilityRow(capability: Cap.insetsLive, fallback: 'Read once'),
              CapabilityRow(
                capability: Cap.keyboardInset,
                fallback: 'Flutter\'s view insets',
              ),
              CapabilityRow(
                capability: Cap.fullscreen,
                fallback: 'Not offered',
              ),
              CapabilityRow(
                capability: Cap.statusBarStyle,
                fallback: 'Host decides',
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Safe area',
          trailing: Switch(
            value: _overlay,
            onChanged: (value) => setState(() => _overlay = value),
          ),
          child: ValueListenableBuilder(
            valueListenable: window.safeArea,
            builder: (context, safeArea, _) => Text(
              'Host: ${_insets(safeArea)}\n'
              'MediaQuery padding: ${_insets(media.padding)}\n'
              'Screen: ${media.size.width.round()} × ${media.size.height.round()} at ${media.devicePixelRatio}x\n'
              'Switch on to shade what the host covers.',
            ),
          ),
        ),
        SectionCard(
          title: 'Keyboard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Tap to open the keyboard',
                ),
              ),
              const SizedBox(height: Gap.s),
              ValueListenableBuilder(
                valueListenable: window.keyboardHeight,
                builder: (context, height, _) => Text(
                  'Host says ${height.round()} px · Flutter view inset ${media.viewInsets.bottom.round()} px',
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Full screen and bars',
          child: Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            children: [
              ValueListenableBuilder(
                valueListenable: window.fullscreen,
                builder: (context, on, _) => FilledButton.tonal(
                  onPressed: () async {
                    final ok = await window.setFullscreen(!on);
                    if (!ok) {
                      await Surface.instance.feedback.toast(
                        'Full screen is not offered here',
                      );
                    }
                  },
                  child: Text(on ? 'Leave full screen' : 'Full screen'),
                ),
              ),
              OutlinedButton(
                onPressed: () => _bars(true),
                child: const Text('Dark icons'),
              ),
              OutlinedButton(
                onPressed: () => _bars(false),
                child: const Text('Light icons'),
              ),
            ],
          ),
        ),
      ],
    );
    if (!_overlay) return page;
    return Stack(
      children: [
        page,
        IgnorePointer(
          child: ValueListenableBuilder(
            valueListenable: window.safeArea,
            builder: (context, safeArea, _) => CustomPaint(
              size: Size.infinite,
              painter: _InsetsPainter(
                safeArea,
                Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bars(bool dark) async {
    final ok = await Surface.instance.window.setLightStatusBars(dark);
    if (!ok) {
      await Surface.instance.feedback.toast(
        'The host picks its own status bar icons',
      );
    }
  }
}

class _InsetsPainter extends CustomPainter {
  _InsetsPainter(this.insets, this.color);

  final EdgeInsets insets;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, insets.top), paint)
      ..drawRect(
        Rect.fromLTWH(
          0,
          size.height - insets.bottom,
          size.width,
          insets.bottom,
        ),
        paint,
      )
      ..drawRect(Rect.fromLTWH(0, 0, insets.left, size.height), paint)
      ..drawRect(
        Rect.fromLTWH(size.width - insets.right, 0, insets.right, size.height),
        paint,
      );
  }

  @override
  bool shouldRepaint(_InsetsPainter old) =>
      old.insets != insets || old.color != color;
}
