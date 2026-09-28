import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// Toasts and the share sheet, with the in-app fallbacks.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController(text: 'Hello from Surfaces Demo');
  String _shared = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = Surface.instance.feedback;
    return DemoScaffold(
      title: 'Toast and share',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(
                capability: Cap.toastNative,
                fallback: 'Drawn by the app',
              ),
              CapabilityRow(
                capability: Cap.shareNative,
                fallback: 'Copied to the clipboard',
              ),
            ],
          ),
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Message',
          ),
        ),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => feedback.toast(_controller.text),
              label: const Text('Show a toast'),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final opened = await feedback.share(_controller.text);
                setState(
                  () => _shared = opened
                      ? 'The share sheet opened'
                      : 'Copied instead',
                );
              },
              label: const Text('Share'),
            ),
          ],
        ),
        if (_shared.isNotEmpty) Text(_shared),
      ],
    );
  }
}
