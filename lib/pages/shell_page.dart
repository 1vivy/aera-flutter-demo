import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// Shell commands, and how long the host froze the page to run them.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final _controller = TextEditingController(text: 'id');
  ExecResult? _result;
  bool _running = false;

  static const _presets = [
    'id',
    'uname -a',
    'getprop ro.product.model',
    'ls /data/adb/modules',
    'sleep 1; echo done',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run([String? command]) async {
    if (command != null) _controller.text = command;
    setState(() => _running = true);
    final result = await Surface.instance.shell.exec(_controller.text);
    if (!mounted) return;
    setState(() {
      _result = result;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = Surface.instance.info;
    final result = _result;
    final mono = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace');
    return DemoScaffold(
      title: 'Shell',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(
                capability: Cap.shellExec,
                fallback: 'Commands answer exit 127',
              ),
              CapabilityRow(
                capability: Cap.shellRoot,
                fallback: 'Runs as the app user',
              ),
              CapabilityRow(
                capability: Cap.shellExecAsync,
                fallback: 'The page freezes while a command runs',
              ),
            ],
          ),
        ),
        if (info.has(Cap.shellExec) && !info.has(Cap.shellExecAsync))
          const FallbackNote(
            'This host runs each command inside the JavaScript call, so the page '
            'stops drawing until it ends. Try "sleep 1": the spinner freezes. Long work belongs '
            'in ops jobs, which return at once and are polled.',
          ),
        TextField(
          controller: _controller,
          style: mono,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Command',
            suffixIcon: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _running ? null : _run,
            ),
          ),
          onSubmitted: (_) => _run(),
        ),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final preset in _presets)
              ActionChip(
                label: Text(preset),
                onPressed: _running ? null : () => _run(preset),
              ),
          ],
        ),
        if (_running) const LinearProgressIndicator(),
        if (result != null)
          SectionCard(
            title: 'Exit ${result.code}',
            trailing: Text(
              [
                if (result.elapsed != null)
                  '${result.elapsed!.inMilliseconds} ms',
                if (result.blocked != null && result.blocked! > Duration.zero)
                  'froze ${result.blocked!.inMilliseconds} ms',
              ].join(' · '),
            ),
            child: Text(
              [
                result.stdout,
                if (result.stderr.isNotEmpty) result.stderr,
              ].join('\n').trim(),
              style: mono,
            ),
          ),
      ],
    );
  }
}
