import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_ui/surfaces_ui.dart';

import '../home.dart';

/// The host's colours, and the scheme the app built from them.
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Surface.instance.theme;
    final scheme = Theme.of(context).colorScheme;
    final dark = theme.darkMode;
    return DemoScaffold(
      title: 'Theme',
      children: [
        const SectionCard(
          title: 'On this host',
          child: CapabilityRow(
            capability: Cap.themeHostColors,
            fallback: 'Built from the app\'s seed colour',
          ),
        ),
        Text(
          'Dark mode: ${dark == null
              ? 'follows the system'
              : dark
              ? 'on (the host says)'
              : 'off (the host says)'}',
        ),
        SectionCard(
          title: 'Host colours',
          child: ValueListenableBuilder(
            valueListenable: theme.hostColors,
            builder: (context, colors, _) => colors.isEmpty
                ? const Text('The host publishes none')
                : _Swatches({for (final e in colors.entries) e.key: e.value}),
          ),
        ),
        SectionCard(
          title: 'App colour scheme',
          child: _Swatches({
            'primary': scheme.primary,
            'onPrimary': scheme.onPrimary,
            'primaryContainer': scheme.primaryContainer,
            'secondary': scheme.secondary,
            'tertiary': scheme.tertiary,
            'surface': scheme.surface,
            'surfaceContainer': scheme.surfaceContainer,
            'onSurface': scheme.onSurface,
            'outline': scheme.outline,
            'error': scheme.error,
          }),
        ),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.colors);

  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      children: [
        for (final MapEntry(key: name, value: color) in colors.entries)
          SizedBox(
            width: 96,
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(Radii.chip),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
