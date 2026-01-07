import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/session_providers.dart';
import '../../auth/auth_providers.dart';
import '../../../core/providers/providers.dart';
import '../avatar_providers.dart';
import '../avatar_setup_provider.dart';
import 'avatar_customize_screen.dart';

/// Mandatory avatar creation step.
///
/// Pressing "Сохранить" persists avatarConfig on backend via PUT /me/avatar,
/// refreshes /auth/me, and then navigates to /tasks.
class AvatarSetupScreen extends ConsumerStatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  ConsumerState<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends ConsumerState<AvatarSetupScreen> {
  bool _saving = false;

  Map<String, dynamic> _buildAvatarConfig() {
    final options = ref.read(avatarOptionsProvider);

    // Keep config flexible: store only selected options.
    return {
      'seed': options.seed,
      'backgroundColor': options.backgroundColor,
      'skinColor': options.skinColor,
      'hair': options.hair,
      'hairColor': options.hairColor,
      'eyes': options.eyes,
      'eyebrows': options.eyebrows,
      'mouth': options.mouth,
      'glasses': options.glasses,
      'glassesProbability': options.glassesProbability,
      'features': options.features,
      'featuresProbability': options.featuresProbability,
      'earrings': options.earrings,
      'earringsProbability': options.earringsProbability,
    };
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;

    debugPrint('AVATAR_SAVE: pressed');

    setState(() => _saving = true);

    // Read dependencies/config BEFORE any awaits.
    final repo = ref.read(authRepositoryProvider);
    final avatarSetupNotifier = ref.read(avatarSetupProvider.notifier);
    final avatarConfig = _buildAvatarConfig();

    try {
      final baseUrl = await ref.read(baseUrlProvider.future);
      if (!mounted) return;

      final token = await ref.read(authTokenProvider.future);
      if (!mounted) return;

      debugPrint('AVATAR_SAVE: baseUrl=$baseUrl, token exists=${token != null && token.isNotEmpty}');

      await repo.saveAvatarConfig(avatarConfig);
      if (!mounted) return;

      debugPrint('AVATAR_SAVE: success');

      // Mark locally (legacy flag) so old gating logic stays satisfied.
      await avatarSetupNotifier.markCreated();
      if (!mounted) return;

      // 2) Refresh user session (GET /auth/me)
      ref.invalidate(currentUserProvider);
      final me = await ref.read(currentUserProvider.future);
      if (!mounted) return;

      // 3) Sync avatar options from server (source of truth after save)
      final serverConfig = me?.avatarConfig;
      if (serverConfig != null && serverConfig.isNotEmpty) {
        ref.read(avatarOptionsProvider.notifier).setFromServer(serverConfig);
      }
      if (!mounted) return;

      // 4) Bust cache so CachedNetworkImage reloads immediately
      ref.read(avatarPreviewBustProvider.notifier).state =
          DateTime.now().millisecondsSinceEpoch;

      // Recompute preview URL if needed.
      ref.invalidate(avatarPreviewUrlProvider);

      if (!mounted) return;
      context.go(AppRoutes.tasks);
    } catch (e) {
      debugPrint('AVATAR_SAVE: error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить аватар. Попробуйте ещё раз.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание аватара'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _onSavePressed,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ),
        ],
      ),
      // Reuse the existing avatar editor as the required setup UI.
      body: const AvatarCustomizeScreen(),
    );
  }
}
