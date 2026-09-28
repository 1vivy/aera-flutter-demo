import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// The host report: what surfaces detected, and every capability with what
/// the app does without it.
class HostPage extends StatelessWidget {
  const HostPage({super.key});

  static const fallbacks = {
    Cap.backIntercept: 'Back walks page history instead',
    Cap.backHistory: 'Back is the app\'s own',
    Cap.exit: 'Stays on the first page',
    Cap.insets: 'Assumes no bars cover the app',
    Cap.insetsLive: 'Insets read once',
    Cap.keyboardInset: 'Flutter\'s own view insets',
    Cap.fullscreen: 'Button stays off',
    Cap.statusBarStyle: 'Host picks the icon colour',
    Cap.lifecycle: 'Flutter\'s lifecycle only',
    Cap.storagePersistent: 'Kept in memory',
    Cap.storageRoot: 'Kept in browser storage',
    Cap.filesPick: 'No picker',
    Cap.filesSave: 'Browser download',
    Cap.toastNative: 'Drawn in the app',
    Cap.shareNative: 'Copied to the clipboard',
    Cap.themeHostColors: 'The app\'s own seed colour',
    Cap.packagesList: 'Empty list',
    Cap.packagesInfo: 'Package names only',
    Cap.shellExec: 'Commands say so',
    Cap.shellExecAsync: 'Page freezes while a command runs',
    Cap.shellRoot: 'Runs as the app user',
    Cap.opsCall: 'Ops say why not',
    Cap.opsJobs: 'Runs to the end at once',
    Cap.coreRust: 'Core calls say why not',
  };

  @override
  Widget build(BuildContext context) {
    final surface = Surface.instance;
    final info = surface.info;
    final text = Theme.of(context).textTheme;
    String core;
    try {
      final greeting = surface.core.call('greet', {'name': info.name});
      final build = surface.core.call('build') as Map;
      core =
          '$greeting\n${build['arch']}, ${build['threads']} thread${build['threads'] == 1 ? '' : 's'}';
    } on OpsException catch (error) {
      core = error.message;
    }
    final have = Cap.all.where(info.has).length;
    return DemoScaffold(
      title: 'Host',
      actions: [
        IconButton(
          tooltip: 'Share the report',
          icon: const Icon(Icons.share),
          onPressed: () => surface.feedback.share(
            const JsonEncoder.withIndent('  ').convert(info.toJson()),
          ),
        ),
      ],
      children: [
        const HostBanner(),
        SectionCard(
          title: 'Detected',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in [
                ('Kind', info.kind.name),
                ('Tier', info.tier),
                if (info.version.isNotEmpty) ('Version', info.version),
                ('Engine', info.engine),
                ('App id', surface.config.appId),
                (
                  'Ops',
                  surface.ops.available
                      ? surface.ops.transportName
                      : 'none (${surface.ops.why})',
                ),
                for (final entry in info.details.entries)
                  (entry.key, entry.value),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(label, style: text.labelLarge),
                      ),
                      Expanded(child: Text(value)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SectionCard(title: 'Rust core', child: Text(core)),
        SectionCard(
          title: 'Capabilities',
          trailing: Text('$have of ${Cap.all.length}', style: text.labelLarge),
          child: Column(
            children: [
              for (final capability in Cap.all)
                CapabilityRow(
                  capability: capability,
                  fallback: fallbacks[capability],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
