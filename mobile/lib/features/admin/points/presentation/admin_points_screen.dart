import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/user_session_provider.dart';
import '../../../avatar/dicebear/dicebear_url.dart';
import '../../../avatar/presentation/avatar_thumb_image.dart';
import '../../../../core/providers/providers.dart';
import '../admin_points_providers.dart';
import '../admin_points_repository.dart';

class AdminPointsScreen extends ConsumerStatefulWidget {
  const AdminPointsScreen({super.key});

  @override
  ConsumerState<AdminPointsScreen> createState() => _AdminPointsScreenState();
}

class _AdminPointsScreenState extends ConsumerState<AdminPointsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = (ref.watch(userRoleProvider) ?? '').trim().toUpperCase();
    final canAccess = role == 'ADMIN' || role == 'SUPERADMIN' || role == 'DEVELOPER';

    if (!canAccess) {
      return const Scaffold(
        body: Center(child: Text('Forbidden: ADMIN+ only')),
      );
    }

    final usersAsync = ref.watch(churchUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Очки'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () {
              ref.invalidate(churchUsersProvider);
              ref.invalidate(selectedUserPointsProvider);
              ref.invalidate(selectedUserPointsLedgerProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? users
              : users.where((u) {
                  final full = '${u.firstName} ${u.lastName}'.trim().toLowerCase();
                  return full.contains(query);
                }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по имени и фамилии',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Пользователи не найдены'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final u = filtered[index];
                          return _UserTile(
                            user: u,
                            onTap: () async {
                              ref.read(selectedPointsUserIdProvider.notifier).state = u.id;
                              await showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                builder: (_) => DraggableScrollableSheet(
                                  expand: false,
                                  initialChildSize: 0.85,
                                  minChildSize: 0.25,
                                  maxChildSize: 0.95,
                                  builder: (context, scrollController) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        // background provided by showModalBottomSheet
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SingleChildScrollView(
                                        controller: scrollController,
                                        child: _UserPointsSheet(user: u),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.onTap});

  final ChurchUserShortDto user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(appConfigProvider).baseUrl;

    Uri? avatarUrl;
    final cfg = user.avatarConfig;
    if (cfg != null && cfg.isNotEmpty) {
      avatarUrl = buildAdventurerPngUrl(baseUrl, cfg);
    }

    final name = user.fullName;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: avatarUrl != null
              ? AvatarThumbImage(url: avatarUrl, fit: BoxFit.cover, cacheWidth: 96)
              : Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
      title: Text(name.isNotEmpty ? name : user.id),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _UserPointsSheet extends ConsumerStatefulWidget {
  const _UserPointsSheet({required this.user});

  final ChurchUserShortDto user;

  @override
  ConsumerState<_UserPointsSheet> createState() => _UserPointsSheetState();
}

class _UserPointsSheetState extends ConsumerState<_UserPointsSheet> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(selectedUserPointsProvider);
    final name = widget.user.fullName;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Пользователь',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                pointsAsync.when(
                  data: (dto) {
                    final balance = dto?.balance ?? 0;
                    return Text(
                      'Текущие очки: $balance',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text('Ошибка: $e'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Количество (целое число)',
                    hintText: 'Например: 10',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Причина',
                    hintText: 'Например: вручную / штраф / поощрение',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('Вычесть'),
                        onPressed: _saving
                            ? null
                            : () async {
                                final amount = int.tryParse(_amountCtrl.text.trim());
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Введите положительное целое число')),
                                  );
                                  return;
                                }

                                final reason = _reasonCtrl.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Укажите причину')),
                                  );
                                  return;
                                }

                                await _adjust(context, -amount, reason);
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Начислить'),
                        onPressed: _saving
                            ? null
                            : () async {
                                final amount = int.tryParse(_amountCtrl.text.trim());
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Введите положительное целое число')),
                                  );
                                  return;
                                }

                                final reason = _reasonCtrl.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Укажите причину')),
                                  );
                                  return;
                                }

                                await _adjust(context, amount, reason);
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _LedgerBlock(userId: widget.user.id),
                const SizedBox(height: 18),
                Text(
                  'Примечание: ручные изменения пишутся в ledger как ADMIN_ADJUSTMENT (аудит).',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _adjust(BuildContext context, int amount, String reason) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminPointsRepositoryProvider);
      final newBalance = await repo.adjustPoints(
        userId: widget.user.id,
        amount: amount,
        reason: reason,
      );

      ref.invalidate(selectedUserPointsProvider);
      ref.invalidate(selectedUserPointsLedgerProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Готово. Нов��й баланс: $newBalance')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LedgerBlock extends ConsumerWidget {
  const _LedgerBlock({required this.userId});

  final String userId;

  String _typeLabel(String type) {
    final t = type.trim().toUpperCase();
    switch (t) {
      case 'TASK_REWARD':
        return 'Награда за задание';
      case 'PURCHASE':
        return 'Покупка';
      case 'ADMIN_ADJUSTMENT':
        return 'Ручная корректировка';
      default:
        return t.isEmpty ? 'Операция' : t;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selectedUserPointsLedgerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'История (последние 20)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Обновить историю',
              onPressed: () => ref.invalidate(selectedUserPointsLedgerProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        async.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'Пока нет операций',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final e = items[index];
                  final isMinus = e.amount < 0;
                  final amountText = isMinus ? '${e.amount}' : '+${e.amount}';
                  final amountColor = isMinus
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary;

                  final date = e.createdAt;
                  final dd = date.day.toString().padLeft(2, '0');
                  final mm = date.month.toString().padLeft(2, '0');
                  final hh = date.hour.toString().padLeft(2, '0');
                  final min = date.minute.toString().padLeft(2, '0');

                  final reason = (e.reason ?? '').trim();

                  return ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Text(
                          amountText,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800, color: amountColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _typeLabel(e.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$dd.$mm $hh:$min', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    subtitle: reason.isEmpty
                        ? null
                        : Text(
                            'Причина: $reason',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  );
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('Ошибка истории: $e'),
        ),
      ],
    );
  }
}
