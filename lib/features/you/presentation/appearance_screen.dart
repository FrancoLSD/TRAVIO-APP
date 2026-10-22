import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_header.dart';

/// You > Appearance (design/SETTINGS - THEME.png): System, Light o Dark.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _options = [
    (
      ThemeMode.system,
      'System',
      'Matches your iPhone setting and switches automatically.',
    ),
    (ThemeMode.light, 'Light', 'Warm off-white background.'),
    (ThemeMode.dark, 'Dark', 'Deep neutral background for low light.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final current = ref.watch(themeModeProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Appearance'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text('Appearance', style: text.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how TRAVIO looks on your iPhone.',
                    style: text.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  for (final (mode, title, subtitle) in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Option(
                        mode: mode,
                        title: title,
                        subtitle: subtitle,
                        selected: mode == current,
                        onTap: () =>
                            ref.read(themeModeProvider.notifier).set(mode),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 'System', 'Light' o 'Dark', para la fila de You.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

class _Option extends StatelessWidget {
  const _Option({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: colors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ExcludeSemantics(child: _Preview(mode)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                selected
                    ? CircleAvatar(
                        radius: 13,
                        backgroundColor: colors.accent,
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: colors.onAccent,
                        ),
                      )
                    : Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.control, width: 1.5),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura con los colores reales de cada modo; System mitad oscura y mitad clara.
class _Preview extends StatelessWidget {
  const _Preview(this.mode);

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final preview = switch (mode) {
      ThemeMode.light => _half(AppColors.light),
      ThemeMode.dark => _half(AppColors.dark),
      ThemeMode.system => Row(
        children: [
          Expanded(child: _half(AppColors.dark)),
          Expanded(child: _half(AppColors.light)),
        ],
      ),
    };
    return Container(
      width: 72,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: preview,
    );
  }

  static Widget _half(AppColors colors) {
    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 22,
            height: 5,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
