import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bible_reader_settings_providers.dart';

class BibleReaderSettingsSheet extends ConsumerWidget {
  const BibleReaderSettingsSheet({super.key});

  static const double _minFontSize = 14;
  static const double _maxFontSize = 28;

  static const double _minLineHeight = 1.2;
  static const double _maxLineHeight = 1.9;

  static const double _minHorizontalPadding = 8;
  static const double _maxHorizontalPadding = 28;

  double _clamp(double v, double min, double max) => v.clamp(min, max).toDouble();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(bibleReaderSettingsProvider);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: settingsAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Настройки чтения',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  e.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref
                      .read(bibleReaderSettingsProvider.notifier)
                      .resetToDefaults(),
                  child: const Text('Сброс'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Готово'),
                ),
              ],
            ),
          ),
          data: (settings) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Настройки чтения',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Font size
                const Text(
                  'Размер текста',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        final next = _clamp(
                          settings.fontSize - 1,
                          _minFontSize,
                          _maxFontSize,
                        );
                        ref
                            .read(bibleReaderSettingsProvider.notifier)
                            .setFontSize(next);
                      },
                      child: const Text('A−'),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.fontSize,
                        min: _minFontSize,
                        max: _maxFontSize,
                        divisions: (_maxFontSize - _minFontSize).round(),
                        label: settings.fontSize.round().toString(),
                        onChanged: (v) {
                          final snapped = v.roundToDouble();
                          ref
                              .read(bibleReaderSettingsProvider.notifier)
                              .setFontSize(snapped);
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final next = _clamp(
                          settings.fontSize + 1,
                          _minFontSize,
                          _maxFontSize,
                        );
                        ref
                            .read(bibleReaderSettingsProvider.notifier)
                            .setFontSize(next);
                      },
                      child: const Text('A+'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Line height
                const Text(
                  'Межстрочный интервал',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: settings.lineHeight,
                  min: _minLineHeight,
                  max: _maxLineHeight,
                  divisions: ((_maxLineHeight - _minLineHeight) / 0.05).round(),
                  label: settings.lineHeight.toStringAsFixed(2),
                  onChanged: (v) {
                    final snapped = (v / 0.05).round() * 0.05;
                    final next = _clamp(
                      snapped.toDouble(),
                      _minLineHeight,
                      _maxLineHeight,
                    );
                    ref
                        .read(bibleReaderSettingsProvider.notifier)
                        .setLineHeight(next);
                  },
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Показывать номера стихов'),
                  value: settings.showVerseNumbers,
                  onChanged: (v) {
                    ref
                        .read(bibleReaderSettingsProvider.notifier)
                        .setShowVerseNumbers(v);
                  },
                ),

                const SizedBox(height: 4),

                // Horizontal padding
                const Text(
                  'Ширина текста',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: settings.horizontalPadding,
                  min: _minHorizontalPadding,
                  max: _maxHorizontalPadding,
                  divisions:
                      (_maxHorizontalPadding - _minHorizontalPadding).round(),
                  label: settings.horizontalPadding.round().toString(),
                  onChanged: (v) {
                    final snapped = v.roundToDouble();
                    ref
                        .read(bibleReaderSettingsProvider.notifier)
                        .setHorizontalPadding(snapped);
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => ref
                          .read(bibleReaderSettingsProvider.notifier)
                          .resetToDefaults(),
                      child: const Text('Сброс'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Готово'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
