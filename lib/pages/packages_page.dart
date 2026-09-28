import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// Installed apps, from the host's package list.
class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  late Future<List<AppPackage>> _packages = Surface.instance.packages.list();
  bool _system = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Apps',
      children: [
        const SectionCard(
          title: 'On this host',
          child: Column(
            children: [
              CapabilityRow(
                capability: Cap.packagesList,
                fallback: 'An empty list',
              ),
              CapabilityRow(
                capability: Cap.packagesInfo,
                fallback: 'Package names only',
              ),
            ],
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('System apps'),
          value: _system,
          onChanged: (value) => setState(() {
            _system = value;
            _packages = Surface.instance.packages.list(system: value);
          }),
        ),
        FutureBuilder(
          future: _packages,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');
            final packages = snapshot.data;
            if (packages == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (packages.isEmpty) {
              return const FallbackNote('This host lists no apps.');
            }
            return Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final package in packages.take(200))
                    ListTile(
                      dense: true,
                      title: Text(package.label ?? package.packageName),
                      subtitle: Text(
                        [
                          if (package.label != null) package.packageName,
                          ?package.versionName,
                        ].join(' · '),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
