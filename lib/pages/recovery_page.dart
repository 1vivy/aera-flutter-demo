import 'package:aera_flutter/aera_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Recovery itself, through aera_flutter's AeraRecovery: what a root
/// recovery module on AERA's generic host can reach.
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  RecoveryInfo? _info;
  BatteryState? _battery;
  WifiState? _wifi;
  double? _brightness;
  bool _flashlight = false;
  bool _hasFlashlight = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await AeraRecovery.info();
      final battery = await AeraRecovery.battery();
      final wifi = await AeraRecovery.wifi();
      final hasFlashlight = await AeraRecovery.hasFlashlight();
      int? brightness;
      try {
        brightness = await AeraRecovery.brightness();
      } on PlatformException {
        brightness = null;
      }
      setState(() {
        _info = info;
        _battery = battery;
        _wifi = wifi;
        _hasFlashlight = hasFlashlight;
        _brightness = brightness?.toDouble();
      });
    } on MissingPluginException {
      setState(() => _error = 'Only on AERA\'s generic plugin host');
    } on PlatformException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _confirmReboot(RebootTarget target) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reboot to ${target.name}?'),
        content: const Text('The phone restarts right away.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reboot'),
          ),
        ],
      ),
    );
    if (go == true) await AeraRecovery.reboot(target);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text(_error!));
    final info = _info;
    final battery = _battery;
    final wifi = _wifi;
    final media = MediaQuery.of(context);
    String row(Object? v) => v == null || v == '' ? '–' : '$v';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (info != null) ...[
            _Fact('AERA', '${row(info.version)} ${info.channel}'),
            _Fact('Phone', row(info.device)),
            _Fact('Active slot', row(info.slot)),
          ],
          if (battery != null)
            _Fact(
              'Battery',
              '${row(battery.level)}% ${row(battery.status)}, '
                  '${row(battery.temperatureC)} °C',
            ),
          if (wifi != null)
            _Fact(
              'Wi-Fi',
              wifi.connected
                  ? '${row(wifi.ssid)} ${row(wifi.ipAddress)}'
                  : 'Not connected',
            ),
          _Fact(
            'AERA theme',
            '${media.platformBrightness.name}, text '
                '${media.textScaler.scale(10) / 10}x, '
                '${media.alwaysUse24HourFormat ? '24' : '12'}-hour',
          ),
          _Fact('Local time', TimeOfDay.now().format(context)),
          const Divider(height: 32),
          if (_brightness != null) ...[
            const Text('Screen brightness'),
            Slider(
              min: 10,
              max: 100,
              value: _brightness!.clamp(10, 100),
              label: '${_brightness!.round()}%',
              onChanged: (v) => setState(() => _brightness = v),
              onChangeEnd: (v) => AeraRecovery.setBrightness(v.round()),
            ),
          ],
          if (_hasFlashlight)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Flashlight'),
              value: _flashlight,
              onChanged: (on) async {
                await AeraRecovery.setFlashlight(on);
                setState(() => _flashlight = on);
              },
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => HapticFeedback.heavyImpact(),
                child: const Text('Vibrate'),
              ),
              OutlinedButton(
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: 'Copied at ${DateTime.now()}'),
                ),
                child: const Text('Copy'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('Reboot'),
          Wrap(
            spacing: 8,
            children: [
              for (final target in RebootTarget.values)
                OutlinedButton(
                  onPressed: () => _confirmReboot(target),
                  child: Text(target.name),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
