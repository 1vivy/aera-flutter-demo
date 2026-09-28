import 'package:flutter/widgets.dart';
import 'package:surfaces/surfaces.dart';

/// Everything the host told the app since it started: Back presses, pause
/// and resume, Flutter's own lifecycle. The Lifecycle and Navigation pages
/// show it.
class HostEvents {
  HostEvents._();

  static final log = ValueNotifier<List<(DateTime, String)>>(const []);

  static void add(String event) {
    final next = [(DateTime.now(), event), ...log.value];
    log.value = next.length > 100 ? next.sublist(0, 100) : next;
  }

  static void start(Surface surface) {
    add('Started on ${surface.info}');
    surface.lifecycle.events.listen((event) => add('Host: ${event.name}'));
    surface.navigation.onBack.listen((_) => add('Host: Back'));
    AppLifecycleListener(
      onStateChange: (state) => add('Flutter: ${state.name}'),
    );
  }
}

String clock(DateTime time) => [
  time.hour,
  time.minute,
  time.second,
].map((n) => '$n'.padLeft(2, '0')).join(':');
