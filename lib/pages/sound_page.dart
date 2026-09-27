import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import '../src/rust/api/demo.dart';

/// A one-octave keyboard played through the phone's speaker by Rust.
class SoundPage extends StatefulWidget {
  const SoundPage({super.key});

  @override
  State<SoundPage> createState() => _SoundPageState();
}

class _SoundPageState extends State<SoundPage> {
  static const _names = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];
  static const _semitones = [0, 2, 4, 5, 7, 9, 11, 12];
  String _status = 'Tap a key';

  static double _frequency(int semitone) =>
      261.63 * pow(2, semitone / 12).toDouble();

  Future<void> _play(List<int> semitones, int milliseconds) async {
    try {
      await playNotes(
        frequenciesHz: [for (final s in semitones) _frequency(s)],
        noteMilliseconds: milliseconds,
        volume: 0.4,
      );
      setState(() => _status = 'Playing');
    } catch (error) {
      setState(() => _status =
          'No speaker here: ${error is AnyhowException ? error.message : error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Row(
              children: [
                for (var i = 0; i < _names.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: colors.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                        child: InkWell(
                          onTap: () => _play([_semitones[i]], 300),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_names[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _play([0, 4, 7, 12, 7, 4, 0], 180),
            icon: const Icon(Icons.music_note),
            label: const Text('Play an arpeggio'),
          ),
          const SizedBox(height: 12),
          Text(_status),
        ],
      ),
    );
  }
}
