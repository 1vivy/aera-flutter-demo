import 'package:aera_flutter/aera_flutter.dart';
import 'package:flutter/material.dart';

import 'aera/runtime.dart';
import 'pages/device_page.dart';
import 'pages/fractal_page.dart';
import 'pages/motion_page.dart';
import 'pages/notes_page.dart';
import 'pages/sound_page.dart';
import 'pages/system_page.dart';

Future<void> main() async {
  await initAera();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      // Routes AERA's back gesture to this app's navigator.
      builder: (context, child) => AeraScope(child: child!),
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
    (Icons.settings_system_daydream, 'System', SystemPage()),
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    // Back returns to the first tab before it leaves the app, as on Android.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
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
      ),
    );
  }
}
