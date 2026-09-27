import 'package:flutter/material.dart';

import '../src/rust/api/aera.dart';

// Set by tool/aera.sh, so the phone shows exactly which build is running.
const _version = String.fromEnvironment(
  'AERA_APP_VERSION',
  defaultValue: 'dev',
);
const _renderer = String.fromEnvironment('AERA_RENDERER', defaultValue: 'gl');
const _appVersion = '$_version ($_renderer)';
const _appBuild = String.fromEnvironment(
  'AERA_APP_BUILD',
  defaultValue: 'not packaged',
);

/// What the app can learn about the phone from inside AERA's jail.
class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late Future<DeviceInfo> _info = deviceInfo();

  static String _bytes(BigInt value) =>
      '${(value.toDouble() / (1 << 30)).toStringAsFixed(1)} GB';

  static String _duration(BigInt seconds) {
    final d = Duration(seconds: seconds.toInt());
    return '${d.inHours} h ${d.inMinutes % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final dirs = storageDirs();
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _info = deviceInfo());
        await _info;
      },
      child: FutureBuilder(
        future: _info,
        builder: (context, snapshot) {
          final info = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section('Where', [
                ('Running on', inRecovery() ? 'AERA Recovery' : 'a PC'),
                ('App', _appVersion),
                ('Build', _appBuild),
                ('Language', recoveryLocale()),
              ]),
              if (info != null)
                _Section('Phone', [
                  ('Kernel', info.kernel),
                  ('CPU', '${info.cpuCount} cores, ${info.machine}'),
                  (
                    'Memory',
                    '${_bytes(info.freeRamBytes)} free of ${_bytes(info.totalRamBytes)}',
                  ),
                  ('Up for', _duration(info.uptimeSeconds)),
                ]),
              _Section('Storage', [
                ('Private', dirs.appData),
                ('Downloads', dirs.downloads),
                ('Scratch', dirs.temp),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows);

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
