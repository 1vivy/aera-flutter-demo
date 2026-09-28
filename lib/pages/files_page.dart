import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// Pick a file, hash it in the Rust core, and save a file where the user
/// finds it.
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String _picked = 'Nothing picked yet';
  String _saved = '';

  Future<void> _pick() async {
    final surface = Surface.instance;
    final file = await surface.files.pick();
    if (file == null) {
      setState(
        () => _picked = surface.info.has(Cap.filesPick)
            ? 'Cancelled'
            : 'No file picker here',
      );
      return;
    }
    final watch = Stopwatch()..start();
    String hash;
    try {
      final encoded = base64Url.encode(file.bytes).replaceAll('=', '');
      final result = surface.core.call('sha256.b64', encoded) as Map;
      hash =
          'SHA-256 in Rust (${watch.elapsedMilliseconds} ms):\n${result['sha256']}';
    } on OpsException catch (error) {
      hash = 'No Rust core: ${error.message}';
    }
    setState(
      () => _picked =
          '${file.name}, ${file.size} bytes'
          '${file.mimeType == null ? '' : ', ${file.mimeType}'}\n$hash',
    );
  }

  Future<void> _save() async {
    final surface = Surface.instance;
    final text =
        'Saved by Surfaces Demo on ${surface.info} at ${DateTime.now()}\n';
    final where = await surface.files.save(
      'surfaces-demo.txt',
      utf8.encode(text),
    );
    setState(
      () => _saved = where == null
          ? 'This host cannot save files'
          : where == 'download'
          ? 'Handed to the browser as a download'
          : 'Saved to $where',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Files',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(capability: Cap.filesPick, fallback: 'No picker'),
              CapabilityRow(
                capability: Cap.filesSave,
                fallback: 'A browser download',
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Pick and hash',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_picked),
              const SizedBox(height: Gap.s),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.upload_file),
                onPressed: _pick,
                label: const Text('Pick a file'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Save',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_saved.isNotEmpty) ...[
                Text(_saved),
                const SizedBox(height: Gap.s),
              ],
              FilledButton.tonalIcon(
                icon: const Icon(Icons.download),
                onPressed: _save,
                label: const Text('Save surfaces-demo.txt'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
