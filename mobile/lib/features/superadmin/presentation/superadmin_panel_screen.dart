import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session_providers.dart';
import '../../auth/user_session_provider.dart';
import '../superadmin_providers.dart';

class SuperAdminPanelScreen extends ConsumerStatefulWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  ConsumerState<SuperAdminPanelScreen> createState() =>
      _SuperAdminPanelScreenState();
}

class _SuperAdminPanelScreenState extends ConsumerState<SuperAdminPanelScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  Future<void> _showChurchDetails(AdminChurchDto c) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(c.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((c.city ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('City: ${c.city}'),
                ),
              const Text(
                'Join code',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(
                c.joinCode.isEmpty ? '—' : c.joinCode,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () async {
                  // IMPORTANT: for SUPERADMIN we can be in an impersonated church context
                  // that comes from the token, not from /auth/me (which returns DB user.churchId).
                  // So we must NOT block switching based on currentUserProvider.churchId.

                  try {
                    final token = await ref
                        .read(superadminApiProvider)
                        .impersonate(churchId: c.id);

                    // Close dialog first to avoid navigator lock during session refresh.
                    Navigator.of(ctx).pop();

                    // Let the dialog pop finish.
                    await Future<void>.delayed(const Duration(milliseconds: 10));

                    await ref.read(authTokenProvider.notifier).setToken(token);

                    // Force /auth/me to re-run and update churchId in memory.
                    // Using refresh().future ensures we wait for the new /auth/me
                    // response before showing success (and before other screens
                    // compute "already in this church" from stale user data).
                    // Riverpod's refresh() returns the new value/future; keep it explicitly
                    // to satisfy analyzer and to ensure /auth/me completed.
                    final _ = await ref.refresh(currentUserProvider.future);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Switched church context')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to switch church: $e')),
                    );
                  }
                },
                label: const Text('Switch to this church'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.autorenew),
                onPressed: () async {
                  try {
                    await ref
                        .read(superadminApiProvider)
                        .rotateJoinCode(id: c.id);
                    if (!mounted) return;
                    ref.invalidate(superadminChurchesProvider);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New join code generated')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to rotate join code: $e')),
                    );
                  }
                },
                label: const Text('Generate new code'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = (ref.watch(userRoleProvider) ?? '').trim().toUpperCase();
    if (role != 'SUPERADMIN' && role != 'SUPERADMIN') {
      // Hard guard: do not render this screen for non-superadmin.
      return Scaffold(
        appBar: AppBar(title: const Text('No access')),
        body: const Center(
          child: Text('Forbidden: SUPERADMIN only'),
        ),
      );
    }

    final churchesAsync = ref.watch(superadminChurchesProvider);
    final createState = ref.watch(superadminCreateChurchProvider);
    final isCreating = createState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('SuperAdmin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create church',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityCtrl,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = _nameCtrl.text.trim();
                          final city = _cityCtrl.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name is required')),
                            );
                            return;
                          }

                          final ok = await ref
                              .read(superadminCreateChurchProvider.notifier)
                              .createChurch(
                                name: name,
                                city: city.isEmpty ? null : city,
                              );

                          if (!mounted) return;
                          if (ok) {
                            _nameCtrl.clear();
                            _cityCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Church created')),
                            );
                            ref.invalidate(superadminChurchesProvider);
                          } else {
                            final err = createState.error;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  err == null
                                      ? 'Failed to create church'
                                      : 'Failed to create church: $err',
                                ),
                              ),
                            );
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: isCreating
                      ? null
                      : () => ref.invalidate(superadminChurchesProvider),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Churches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: churchesAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No churches yet'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.city ?? ''),
                        trailing: const Icon(Icons.chevron_right, size: 26),
                        onTap: () => _showChurchDetails(c),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load churches: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
