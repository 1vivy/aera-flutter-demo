import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../events.dart';
import '../home.dart';

/// Every event the host sent since the app started.
class LifecyclePage extends StatelessWidget {
  const LifecyclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DemoScaffold(
      title: 'Lifecycle',
      children: [
        const SectionCard(
          title: 'On this host',
          child: CapabilityRow(
            capability: Cap.lifecycle,
            fallback: 'Flutter\'s own lifecycle only',
          ),
        ),
        const Text(
          'Switch to another app and back, or press Back on a nested page: '
          'each event lands here.',
        ),
        SectionCard(
          title: 'Events',
          child: ValueListenableBuilder(
            valueListenable: HostEvents.log,
            builder: (context, log, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (time, event) in log)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${clock(time)}  $event',
                      style: text.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
