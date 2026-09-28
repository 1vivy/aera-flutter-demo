import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../src/rust/api/aera.dart';

/// Notes kept in the app's private storage, which survives reboots. Typing
/// uses AERA's on-screen keyboard.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _controller = TextEditingController();
  final _file = File('${storageDirs().appData}/notes.json');
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    if (_file.existsSync()) {
      _notes = List<String>.from(jsonDecode(_file.readAsStringSync()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => _file.writeAsStringSync(jsonEncode(_notes));

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _notes.insert(0, text));
    _controller.clear();
    _save();
  }

  void _export() {
    final path = '${storageDirs().downloads}/notes.txt';
    File(path).writeAsStringSync('${_notes.join('\n\n')}\n');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Saved $path')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Write a note',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _add,
              ),
            ),
            onSubmitted: (_) => _add(),
          ),
        ),
        Expanded(
          child: _notes.isEmpty
              ? const Center(child: Text('No notes yet'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(_notes[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => _notes.removeAt(index));
                        _save();
                      },
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _notes.isEmpty ? null : _export,
            icon: const Icon(Icons.download),
            label: const Text('Save to Downloads'),
          ),
        ),
      ],
    );
  }
}
