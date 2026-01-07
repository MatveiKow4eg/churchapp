import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';

/// Local stub for avatar setup flow.
///
/// Backend is not touched: avatar is considered "absent" while this flag is false.
///
/// IMPORTANT: this is persisted locally so that after app restart the user
/// won't be forced into /avatar/setup again.
final avatarSetupProvider = AsyncNotifierProvider<AvatarSetupNotifier, bool>(
  AvatarSetupNotifier.new,
);

class AvatarSetupNotifier extends AsyncNotifier<bool> {
  static const _kKey = 'avatarCreated';

  @override
  Future<bool> build() async {
    final store = ref.read(secureStoreProvider);
    return await store.getBool(_kKey) ?? false;
  }

  Future<void> markCreated() async {
    final store = ref.read(secureStoreProvider);
    await store.setBool(_kKey, true);
    state = const AsyncData(true);
  }

  Future<void> clear() async {
    final store = ref.read(secureStoreProvider);
    await store.delete(_kKey);
    state = const AsyncData(false);
  }
}
