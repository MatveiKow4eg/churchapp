import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/user_session_provider.dart';
import '../superadmin_providers.dart';

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

              if (users.isEmpty) {
                return const Center(child: Text('Пользователи не найдены'));
              }

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = users[index];
                  final name = '${u.firstName} ${u.lastName}'.trim();
                  final email = (u.email ?? '').trim();
                  final churchLabel = u.churchId == null
                      ? '—'
                      : (churchNameById[u.churchId] ?? u.churchId!);
                  final status = u.status;

                  return ListTile(
                    title: Text(name.isNotEmpty ? name : (email.isNotEmpty ? email : u.id)),
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
      content: LayoutBuilder(
        builder: (context, constraints) {
          // Ограничиваем ширину и высоту контента, добавляем скролл
          final maxWidth = constraints.maxWidth.clamp(0.0, 520.0);
          final maxHeight = MediaQuery.of(context).size.height * 0.7;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              // ограничиваем высоту, чтобы кнопки не уходили за экран
              maxHeight: maxHeight,
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
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
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
