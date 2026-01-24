import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/user_session_provider.dart';
import '../../auth/session_providers.dart';
import '../superadmin_providers.dart';
import '../../avatar/dicebear/dicebear_url.dart';
import '../../avatar/presentation/avatar_thumb_image.dart';
import '../../../core/providers/providers.dart';

// Superadmin users list filter.
// null means "not chosen yet"; we will auto-select current church.
final _selectedChurchIdProvider = StateProvider<String?>((ref) => null);

final _selectedRoleProvider = StateProvider<String?>((ref) => null);

class SuperAdminUsersScreen extends ConsumerStatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  ConsumerState<SuperAdminUsersScreen> createState() =>
      _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends ConsumerState<SuperAdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final role = (ref.watch(userRoleProvider) ?? '').trim().toUpperCase();
    if (role != 'SUPERADMIN') {
      return const Scaffold(
        body: Center(child: Text('Forbidden: SUPERADMIN only')),
      );
    }

    final usersAsync = ref.watch(superadminUsersProvider);
    final churchesAsync = ref.watch(superadminChurchesProvider);
    final currentChurchId = ref.watch(currentUserProvider).valueOrNull?.churchId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperAdmin: пользователи'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(superadminUsersProvider);
              ref.invalidate(superadminChurchesProvider);
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          return churchesAsync.when(
            data: (churches) {
              final churchNameById = {
                for (final c in churches) c.id: '${c.name}${(c.city ?? '').trim().isNotEmpty ? ' (${c.city})' : ''}'
              };

              final allChurches = <AdminChurchDto>[
                AdminChurchDto(
                  id: '__ALL__',
                  name: 'Все церкви',
                  city: null,
                  joinCode: '',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                ...churches,
              ];

              final selectedChurchIdState = ref.watch(_selectedChurchIdProvider);
              final initialSelected = (selectedChurchIdState == null)
                  ? (currentChurchId ?? '__ALL__')
                  : selectedChurchIdState;

              // If we have no current church (unlikely for superadmin), default to ALL.
              final selectedChurchId = initialSelected;

              final roleOptions = const <String>['__ALL__', 'USER', 'ADMIN', 'SUPERADMIN'];
              final selectedRoleState = ref.watch(_selectedRoleProvider);
              final selectedRole = selectedRoleState ?? '__ALL__';

              final filtered = users
                  .where((u) => selectedChurchId == '__ALL__' || u.churchId == selectedChurchId)
                  .where((u) => selectedRole == '__ALL__' || u.role.trim().toUpperCase() == selectedRole)
                  .toList(growable: false);

              // Sort by role priority, then by lastName/firstName for stable grouping.
              final rolePriority = <String, int>{
                'SUPERADMIN': 0,
                'ADMIN': 1,
                'USER': 2,
              };
              filtered.sort((a, b) {
                final pa = rolePriority[a.role.trim().toUpperCase()] ?? 99;
                final pb = rolePriority[b.role.trim().toUpperCase()] ?? 99;
                if (pa != pb) return pa.compareTo(pb);

                final la = a.lastName.trim().toLowerCase();
                final lb = b.lastName.trim().toLowerCase();
                final cmpL = la.compareTo(lb);
                if (cmpL != 0) return cmpL;

                final fa = a.firstName.trim().toLowerCase();
                final fb = b.firstName.trim().toLowerCase();
                final cmpF = fa.compareTo(fb);
                if (cmpF != 0) return cmpF;

                return a.id.compareTo(b.id);
              });

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Церковь:'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedChurchId,
                                items: allChurches
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(
                                          c.id == '__ALL__'
                                              ? c.name
                                              : '${c.name}${(c.city ?? '').trim().isNotEmpty ? ' (${c.city})' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (v) {
                                  if (v == null) return;
                                  ref.read(_selectedChurchIdProvider.notifier).state = v;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Роль:'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedRole,
                                items: roleOptions
                                    .map(
                                      (r) => DropdownMenuItem<String>(
                                        value: r,
                                        child: Text(r == '__ALL__' ? 'Все роли' : r),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (v) {
                                  if (v == null) return;
                                  ref.read(_selectedRoleProvider.notifier).state = v;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  final name = '${u.firstName} ${u.lastName}'.trim();
                  final now = DateTime.now();
                  final isNewUser = now.difference(u.createdAt).inDays < 3;
                  final email = (u.email ?? '').trim();
                  final churchLabel = u.churchId == null
                      ? '—'
                      : (churchNameById[u.churchId] ?? u.churchId!);
                  final status = u.status;

                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : (email.isNotEmpty ? email : u.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNewUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'NEW',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'id: ${u.id}\n'
                      'email: ${email.isEmpty ? '—' : email}\n'
                      'role: ${u.role} • status: $status\n'
                      'church: $churchLabel',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => _EditUserDialog(
                          user: u,
                          churches: churches,
                        ),
                      );
                      if (ok == true) {
                        ref.invalidate(superadminUsersProvider);
                      }
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({
    required this.user,
    required this.churches,
  });

  final AdminUserDto user;
  final List<AdminChurchDto> churches;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;

  late String _role;
  late String _status;
  String? _churchId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);

    _role = widget.user.role;
    _status = widget.user.status;
    _churchId = widget.user.churchId;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final churchItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('— (без церкви)')),
      ...widget.churches.map(
        (c) => DropdownMenuItem(
          value: c.id,
          child: Text('${c.name}${(c.city ?? '').trim().isNotEmpty ? ' (${c.city})' : ''}'),
        ),
      ),
    ];

    return AlertDialog(
      title: const Text('Редактировать пользователя'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          // AlertDialog измеряет content через IntrinsicWidth. LayoutBuilder тут нельзя.
          // Поэтому задаём ограничения напрямую.
          maxWidth: 520,
          // ограничиваем высоту, чтобы кнопки не уходили за экран
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'id: ${widget.user.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              _AvatarReadonlyPreview(user: widget.user),
              const SizedBox(height: 12),
              TextField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  DropdownMenuItem(value: 'SUPERADMIN', child: Text('SUPERADMIN')),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'BANNED', child: Text('BANNED')),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _churchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Церковь',
                  border: OutlineInputBorder(),
                ),
                items: churchItems,
                onChanged: (v) => setState(() => _churchId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Удалить пользователя?'),
                        content: const Text(
                          'Пользователь будет удалён полностью. Действие необратимо.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) return;

                  setState(() => _saving = true);
                  try {
                    await ref.read(superadminApiProvider).deleteUser(id: widget.user.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пользователь удалён')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Удалить'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref.read(superadminApiProvider).updateUser(
                          id: widget.user.id,
                          firstName: _firstNameCtrl.text.trim(),
                          lastName: _lastNameCtrl.text.trim(),
                          role: _role,
                          status: _status,
                          churchId: _churchId,
                        );
                    if (context.mounted) Navigator.of(context).pop(true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: Text(_saving ? 'Сохранение...' : 'Сохранить'),
        ),
      ],
    );
  }
}

class _AvatarReadonlyPreview extends ConsumerWidget {
  const _AvatarReadonlyPreview({required this.user});
  final AdminUserDto user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Uri? avatarUrl;
    final cfg = user.avatarConfig;
    if (cfg is Map) {
      final baseUrl = ref.watch(appConfigProvider).baseUrl;
      final map = Map<String, dynamic>.from(cfg);
      if (map.isNotEmpty) {
        avatarUrl = buildAdventurerPngUrl(baseUrl, map);
      }
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 96,
          height: 96,
          color: Theme.of(context).colorScheme.surfaceVariant,
          alignment: Alignment.center,
          child: avatarUrl != null
              ? AvatarThumbImage(
                  url: avatarUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 128,
                )
              : Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}
