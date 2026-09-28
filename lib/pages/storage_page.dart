import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// A note kept with `storage`: root-owned files on WebUI, localStorage in a
/// browser, the app data folder on AERA and desktop.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  static const _name = 'note.txt';
  final _controller = TextEditingController();
  String _status = 'Loading';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final text = await Surface.instance.storage.readText(_name);
    if (!mounted) return;
    setState(() {
      _controller.text = text ?? '';
      _status = text == null ? 'No note yet' : 'Loaded';
    });
  }

  Future<void> _save() async {
    try {
      await Surface.instance.storage.writeText(_name, _controller.text);
      setState(() => _status = 'Saved at ${TimeOfDay.now().format(context)}');
    } catch (error) {
      setState(() => _status = 'Not saved: $error');
    }
  }

  Future<void> _delete() async {
    await Surface.instance.storage.delete(_name);
    _controller.clear();
    setState(() => _status = 'Deleted');
  }

  @override
  Widget build(BuildContext context) {
    final paths = Surface.instance.storage.paths;
    return DemoScaffold(
      title: 'Storage',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(
                capability: Cap.storagePersistent,
                fallback: 'Kept in memory until the app closes',
              ),
              CapabilityRow(
                capability: Cap.storageRoot,
                fallback: 'Kept by the browser',
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Note',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'Write something, save, then close and reopen the app',
                ),
              ),
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  FilledButton(onPressed: _save, child: const Text('Save')),
                  const SizedBox(width: Gap.s),
                  OutlinedButton(
                    onPressed: _delete,
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(child: Text(_status)),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Where files go',
          child: Text(
            'App data: ${paths.appData.isEmpty ? 'none (browser storage)' : paths.appData}\n'
            'Downloads: ${paths.downloads.isEmpty ? 'browser downloads' : paths.downloads}\n'
            'Temp: ${paths.temp.isEmpty ? 'none' : paths.temp}',
          ),
        ),
      ],
    );
  }
}
