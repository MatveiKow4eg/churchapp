import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/profile_providers.dart';

/// Toggle to show streak in XP card.
/// Default: hidden.
const bool kShowStreakInProfile = false;

class XpProgressCard extends ConsumerWidget {
  const XpProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpAsync = ref.watch(myXpStatusProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: xpAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Не удалось загрузить прогресс',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(myXpStatusProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
          data: (xp) {
            String levelNameFallback(int level) {
              switch (level) {
                case 1:
                  return 'Новичок';
                case 2:
                  return 'Ученик';
                case 3:
                  return 'Практик';
                case 4:
                  return 'Участник';
                case 5:
                  return 'Служитель';
                case 6:
                  return 'Надёжный';
                case 7:
                  return 'Вдохновитель';
                case 8:
                  return 'Наставник';
                case 9:
                  return 'Лидер';
                case 10:
                  return 'Опора';
                default:
                  return 'Опора+';
              }
            }

            final levelName = xp.levelName.trim().isEmpty
                ? levelNameFallback(xp.level)
                : xp.levelName;

            final cats = xp.categories;
            final values = cats.values.toList();
            final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

            final remainingXp = (xp.nextLevelXp - xp.levelXp);
            final remainingXpSafe = remainingXp < 0 ? 0 : remainingXp;

            final items = <(String key, String title, IconData icon)>[
              ('spiritual', 'Духовное', Icons.auto_awesome_outlined),
              ('service', 'Служение', Icons.volunteer_activism_outlined),
              ('community', 'Сообщество', Icons.groups_outlined),
              ('creativity', 'Творчество', Icons.brush_outlined),
              ('reflection', 'Рассуждение', Icons.psychology_alt_outlined),
              ('other', 'Другое', Icons.more_horiz),
            ];

            Widget catRow({
              required IconData icon,
              required String title,
              required int value,
            }) {
              final v = (max <= 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(title)),
                        Text('$value XP'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: v),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleLarge,
                    children: [
                      const TextSpan(text: 'Уровень '),
                      TextSpan(
                        text: '${xp.level}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: '  $levelName',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: xp.progress.clamp(0.0, 1.0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${xp.levelXp} / ${xp.nextLevelXp}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'До следующего уровня: $remainingXpSafe XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Категории',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                ...items.map(
                  (it) => catRow(
                    icon: it.$3,
                    title: it.$2,
                    value: cats[it.$1] ?? 0,
                  ),
                ),
                if (kShowStreakInProfile) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text('Стрик: ${xp.streakDays} дней'),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
