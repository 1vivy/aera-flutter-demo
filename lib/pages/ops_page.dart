import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// The app's Rust ops: a root worker on WebUI, in-process on AERA and
/// desktop. Calls return once; jobs report progress and can be cancelled.
class OpsPage extends StatefulWidget {
  const OpsPage({super.key});

  @override
  State<OpsPage> createState() => _OpsPageState();
}

class _OpsPageState extends State<OpsPage> {
  final _ops = Surface.instance.ops;
  late final _path = TextEditingController(text: _defaultPath());
  String _answer = '';
  Job? _job;
  JobStatus? _status;

  static String _defaultPath() {
    final surface = Surface.instance;
    return surface.info.kind == HostKind.webui
        ? '/data/adb/modules'
        : surface.storage.paths.appData;
  }

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  Future<void> _call(String op, [Object? input]) async {
    setState(() => _answer = 'Running $op');
    final watch = Stopwatch()..start();
    try {
      final result = await _ops.call(op, input);
      setState(
        () => _answer =
            '$op in ${watch.elapsedMilliseconds} ms\n'
            '${const JsonEncoder.withIndent('  ').convert(result)}',
      );
    } on OpsException catch (error) {
      setState(() => _answer = '$op failed (${error.code}): ${error.message}');
    }
  }

  Future<void> _start(String op, [Object? input]) async {
    try {
      final job = await _ops.start(op, input);
      setState(() {
        _job = job;
        _status = job.latest;
      });
      await for (final status in job.updates) {
        if (!mounted) return;
        setState(() => _status = status);
      }
      if (mounted) setState(() => _status = job.latest);
    } on OpsException catch (error) {
      setState(() => _answer = '$op failed: ${error.message}');
    } finally {
      if (mounted) setState(() => _job = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final mono = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace');
    final ready = _ops.available;
    final idle = _job == null && ready;
    return DemoScaffold(
      title: 'Ops and jobs',
      children: [
        SectionCard(
          title: 'On this host',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CapabilityRow(
                capability: Cap.opsCall,
                fallback: 'Ops say why not',
              ),
              const CapabilityRow(
                capability: Cap.opsJobs,
                fallback: 'Jobs run to the end at once',
              ),
              const SizedBox(height: Gap.xs),
              Text(
                ready
                    ? 'Transport: ${_ops.transportName}'
                    : 'Not here: ${_ops.why}',
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Calls',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _path,
                style: mono,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Path',
                ),
              ),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  FilledButton.tonal(
                    onPressed: ready ? () => _call('sys.info') : null,
                    child: const Text('sys.info'),
                  ),
                  FilledButton.tonal(
                    onPressed: ready
                        ? () => _call('fs.list', {
                            'path': _path.text,
                            'limit': 50,
                          })
                        : null,
                    child: const Text('fs.list'),
                  ),
                  FilledButton.tonal(
                    onPressed: ready
                        ? () => _call('fs.stat', {'path': _path.text})
                        : null,
                    child: const Text('fs.stat'),
                  ),
                ],
              ),
              if (_answer.isNotEmpty) ...[
                const SizedBox(height: Gap.s),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Text(_answer, style: mono),
                  ),
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Jobs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status != null) ...[
                LinearProgressIndicator(
                  value: status.finished ? 1 : status.progress,
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  status.finished
                      ? '${status.op} ${status.state.name}: ${status.error?.message ?? jsonEncode(status.result)}'
                      : '${status.op}: ${status.message ?? 'starting'}',
                ),
                const SizedBox(height: Gap.s),
              ],
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  FilledButton(
                    onPressed: idle
                        ? () => _start('sys.wait', {'seconds': 5})
                        : null,
                    child: const Text('Wait 5 s'),
                  ),
                  FilledButton(
                    onPressed: idle
                        ? () => _start('demo.primes', {'below': 5000000})
                        : null,
                    child: const Text('Count primes'),
                  ),
                  FilledButton(
                    onPressed: idle
                        ? () => _start('fs.hash', {'path': _path.text})
                        : null,
                    child: const Text('Hash path'),
                  ),
                  if (_job != null)
                    OutlinedButton(
                      onPressed: _job!.cancel,
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
