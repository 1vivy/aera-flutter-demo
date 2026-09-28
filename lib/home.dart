import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import 'pages/feedback_page.dart';
import 'pages/files_page.dart';
import 'pages/fractal_page.dart';
import 'pages/host_page.dart';
import 'pages/lifecycle_page.dart';
import 'pages/motion_page.dart';
import 'pages/navigation_page.dart';
import 'pages/ops_page.dart';
import 'pages/packages_page.dart';
import 'pages/shell_page.dart';
import 'pages/sound_page.dart';
import 'pages/storage_page.dart';
import 'pages/theme_page.dart';
import 'pages/window_page.dart';

/// One demo page per surfaces feature, and the capabilities it uses.
class Demo {
  const Demo(this.icon, this.title, this.summary, this.capabilities, this.page);

  final IconData icon;
  final String title;
  final String summary;
  final List<String> capabilities;
  final Widget Function() page;
}

final demos = <Demo>[
  Demo(
    Icons.fact_check_outlined,
    'Host',
    'What this host is and offers',
    const [Cap.coreRust],
    () => const HostPage(),
  ),
  Demo(
    Icons.arrow_back,
    'Back and exit',
    'Host Back, PopScope, closing the app',
    const [Cap.backIntercept, Cap.backHistory, Cap.exit],
    () => const NavigationPage(),
  ),
  Demo(
    Icons.fullscreen,
    'Window',
    'Safe area, keyboard, full screen, bars',
    const [
      Cap.insets,
      Cap.insetsLive,
      Cap.keyboardInset,
      Cap.fullscreen,
      Cap.statusBarStyle,
    ],
    () => const WindowPage(),
  ),
  Demo(
    Icons.timeline,
    'Lifecycle',
    'Pause, resume and Back as they arrive',
    const [Cap.lifecycle],
    () => const LifecyclePage(),
  ),
  Demo(Icons.save_outlined, 'Storage', 'A note that survives restarts', const [
    Cap.storagePersistent,
    Cap.storageRoot,
  ], () => const StoragePage()),
  Demo(
    Icons.folder_open,
    'Files',
    'Pick a file, hash it in Rust, save one',
    const [Cap.filesPick, Cap.filesSave],
    () => const FilesPage(),
  ),
  Demo(
    Icons.campaign_outlined,
    'Toast and share',
    'Host toasts, or in-app ones',
    const [Cap.toastNative, Cap.shareNative],
    () => const FeedbackPage(),
  ),
  Demo(
    Icons.palette_outlined,
    'Theme',
    'The host\'s colours and dark mode',
    const [Cap.themeHostColors],
    () => const ThemePage(),
  ),
  Demo(Icons.apps, 'Apps', 'Installed apps', const [
    Cap.packagesList,
    Cap.packagesInfo,
  ], () => const PackagesPage()),
  Demo(Icons.terminal, 'Shell', 'Commands, and how long the page froze', const [
    Cap.shellExec,
    Cap.shellRoot,
    Cap.shellExecAsync,
  ], () => const ShellPage()),
  Demo(
    Icons.memory,
    'Ops and jobs',
    'Rust as root, with progress and cancel',
    const [Cap.opsCall, Cap.opsJobs],
    () => const OpsPage(),
  ),
  Demo(Icons.blur_on, 'Fractal', 'The Rust core drawing pixels', const [
    Cap.coreRust,
  ], () => const FractalPage()),
  Demo(
    Icons.animation,
    'Motion',
    'A frame-rate meter',
    const [],
    () => const MotionPage(),
  ),
  Demo(
    Icons.piano,
    'Sound',
    'AERA\'s speaker, played by Rust',
    const [],
    () => const SoundPage(),
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final info = Surface.instance.info;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Surfaces Demo')),
      body: PageBody(
        children: [
          const HostBanner(),
          for (final demo in demos)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(demo.icon, color: scheme.primary),
                title: Text(demo.title),
                subtitle: Text(demo.summary),
                trailing: demo.capabilities.isEmpty
                    ? null
                    : _Coverage(
                        have: demo.capabilities.where(info.has).length,
                        of: demo.capabilities.length,
                      ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => demo.page(),
                    settings: RouteSettings(name: demo.title),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// How many of a page's capabilities this host has.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.have, required this.of});

  final int have;
  final int of;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = have == of;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: full ? scheme.primaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        '$have/$of',
        semanticsLabel: '$have of $of native',
        style: TextStyle(
          color: full ? scheme.onPrimaryContainer : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// The frame every demo page shares.
class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      // Results stay selectable as plain Text, which screen readers (and
      // Flutter's web semantics) can read; SelectableText they cannot.
      body: SelectionArea(child: PageBody(children: children)),
    );
  }
}
