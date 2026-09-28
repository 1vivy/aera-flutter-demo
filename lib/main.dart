import 'package:aera_flutter/aera_flutter.dart';
import 'package:flutter/material.dart';

import 'aera/runtime.dart';
import 'pages/device_page.dart';
import 'pages/fractal_page.dart';
import 'pages/motion_page.dart';
import 'pages/notes_page.dart';
import 'pages/recovery_page.dart';
import 'pages/sound_page.dart';

Future<void> main() async {
  await initAera();
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  // AERA's accent colour; light or dark follows AERA through MediaQuery.
  Color _accent = Colors.teal;

  @override
  void initState() {
    super.initState();
    AeraRecovery.theme()
        .then((theme) => setState(() => _accent = theme.accent))
        .catchError((_) {}); // Not on AERA's generic host.
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _pages = [
    (Icons.memory, 'Device', DevicePage()),
    (Icons.edit_note, 'Notes', NotesPage()),
    (Icons.piano, 'Sound', SoundPage()),
    (Icons.blur_on, 'Fractal', FractalPage()),
    (Icons.animation, 'Motion', MotionPage()),
    (Icons.settings_applications, 'Recovery', RecoveryPage()),
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return Scaffold(
      appBar: AppBar(title: Text(page.$2)),
      body: page.$3,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final (icon, label, _) in _pages)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
