import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_aera/surfaces_aera.dart';
import 'package:surfaces_ui/surfaces_ui.dart';
import 'package:surfaces_webui/surfaces_webui.dart';

import 'events.dart';
import 'home.dart';
import 'native/native.dart';

Future<void> main() async {
  // The id is the KernelSU module id; keep it equal to surfaces.yaml's.
  final surface = await Surface.init(
    await withNative(
      const SurfaceConfig(appId: 'surfaces_demo', appName: 'Surfaces Demo'),
    ),
    backends: const [WebUiBackend(), AeraBackend()],
  );
  HostEvents.start(surface);
  runApp(
    const SurfacesApp(
      title: 'Surfaces Demo',
      seed: Colors.indigo,
      home: HomePage(),
    ),
  );
}
