import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// Host Back as a route pop: it closes dialogs, pops pages, honours
/// PopScope, and leaves the app from the first page.
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  bool _guard = false;
  int _blocked = 0;

  String get _how {
    final info = Surface.instance.info;
    if (info.has(Cap.backIntercept)) {
      return 'This host hands Back to the app. Each press pops one page, and '
          'from the first page the app ${info.has(Cap.exit) ? 'closes itself' : 'stays open'}.';
    }
    if (info.has(Cap.backHistory)) {
      return 'This host walks the page history on Back. Each page is a history '
          'entry, so Back pops pages; with no entries left the host closes the WebUI.';
    }
    return 'The browser\'s Back button walks the page history: each page here is an entry.';
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this page?'),
        content: const Text(
          'Back was caught by PopScope. Press Back again to close this dialog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _guard = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Surface.instance;
    return PopScope(
      canPop: !_guard,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _blocked++);
        _confirmLeave();
      },
      child: DemoScaffold(
        title: 'Back and exit',
        children: [
          const SectionCard(
            title: 'On this host',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CapabilityRow(
                  capability: Cap.backIntercept,
                  fallback: 'Back walks page history',
                ),
                CapabilityRow(capability: Cap.backHistory),
                CapabilityRow(
                  capability: Cap.exit,
                  fallback: 'Stays on the first page',
                ),
              ],
            ),
          ),
          Text(_how),
          SectionCard(
            title: 'Catch Back on this page',
            trailing: Switch(
              value: _guard,
              onChanged: (value) => setState(() => _guard = value),
            ),
            child: Text(
              _guard ? 'Back now asks first ($_blocked caught so far).' : 'Turn on to wrap this page in a PopScope that asks before leaving.',
            ),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.layers_outlined),
            label: const Text('Open a nested page'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _Nested(depth: 1)),
            ),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.close),
            label: const Text('Close the app'),
            onPressed: () async {
              final closed = await surface.navigation.exit();
              if (!closed) {
                await surface.feedback.toast(
                  'This host has no way to close the app',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Nested extends StatelessWidget {
  const _Nested({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Nested page $depth',
      children: [
        Text(
          'Press Back on the host to return. This is $depth page${depth == 1 ? '' : 's'} deep.',
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _Nested(depth: depth + 1)),
          ),
          child: const Text('Go deeper'),
        ),
      ],
    );
  }
}
