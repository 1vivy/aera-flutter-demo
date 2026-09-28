import 'dart:async';

import 'package:aera_flutter/aera_flutter.dart';
import 'package:flutter/material.dart';

/// AERA's own system features: the back gesture, the top bar and the
/// keyboard, through the aera_flutter package.
class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  final _system = AeraSystem.instance;
  final _events = <String>[];
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _forward = false;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _system.onForward.listen((_) => _log('Forward')),
      _system.onReload.listen((_) => _log('Reload')),
      _system.onStop.listen((_) => _log('Stop')),
      _system.onOpen.listen((url) => _log('Open $url')),
      _system.onZoom.listen((zoom) => _log('Pinch zoom $zoom%')),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _log(String event) {
    setState(() {
      _events.insert(0, event);
      if (_events.length > 6) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Back', style: text.titleMedium),
        const Text(
          'Swipe in from the edge or press the top bar\'s back arrow. '
          'It closes the page below, then returns to the Device tab, then '
          'leaves the app.',
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const _SecondPage())),
          child: const Text('Open a page'),
        ),
        const Divider(height: 32),
        Text('Keyboard', style: text.titleMedium),
        ValueListenableBuilder(
          valueListenable: _system.keyboardVisible,
          builder: (context, visible, _) =>
              Text(visible ? 'AERA keyboard is up' : 'AERA keyboard is down'),
        ),
        const TextField(
          decoration: InputDecoration(labelText: 'Type with AERA\'s keyboard'),
        ),
        const Divider(height: 32),
        Text('Top bar', style: text.titleMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable the Forward button'),
          value: _forward,
          onChanged: (value) {
            setState(() => _forward = value);
            _system.setNavigationState(canGoForward: value);
          },
        ),
        const Text(
          'Forward, Reload, Home, an address typed in the top bar and pinch '
          'zoom show up here:',
        ),
        const SizedBox(height: 8),
        if (_events.isEmpty) const Text('Nothing yet'),
        for (final event in _events) Text('• $event'),
      ],
    );
  }
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A page')),
      body: const Center(child: Text('Use AERA\'s back gesture to close me')),
    );
  }
}
