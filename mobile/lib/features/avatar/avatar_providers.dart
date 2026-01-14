import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_providers.dart';
import '../../core/providers/providers.dart';
import 'dicebear/dicebear_url.dart';
import 'domain/avatar_options.dart';

class AvatarOptionsController extends StateNotifier<AvatarOptions> {
  AvatarOptionsController(super.state);

  void setBackgroundColor(String hex) {
    state = state.copyWith(backgroundColor: hex);
  }

  void setSkinColor(String hex) {
    state = state.copyWith(skinColor: hex);
  }

  void setHair(String v) {
    state = state.copyWith(hair: v);
  }

  void setHairColor(String hex) {
    state = state.copyWith(hairColor: hex);
  }

  void setEyes(String v) {
    state = state.copyWith(eyes: v);
  }

  void setEyebrows(String v) {
    state = state.copyWith(eyebrows: v);
  }

  void setMouth(String v) {
    state = state.copyWith(mouth: v);
  }

  void setGlasses(String? v) {
    if (v == null) {
      state = state.copyWith(glasses: null, glassesProbability: 0);
    } else {
      state = state.copyWith(glasses: v, glassesProbability: 100);
    }
  }

  void setFeatures(String? v) {
    if (v == null) {
      state = state.copyWith(features: null, featuresProbability: 0);
    } else {
      state = state.copyWith(features: v, featuresProbability: 100);
    }
  }

  void setEarrings(String? v) {
    if (v == null) {
      state = state.copyWith(earrings: null, earringsProbability: 0);
    } else {
      state = state.copyWith(earrings: v, earringsProbability: 100);
    }
  }

  void setSeed(String seed) {
    state = state.copyWith(seed: seed);
  }

  /// Replace current options from server-stored avatarConfig.
  ///
  /// Config is intentionally flexible; we map only known DiceBear keys.
  /// Unknown keys are ignored.
  void setFromServer(Map<String, dynamic> config) {
    String? s(dynamic v) {
      if (v == null) return null;
      final str = v.toString().trim();
      return str.isEmpty ? null : str;
    }

    int i(dynamic v, {required int fallback}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    final seed = s(config['seed']) ?? state.seed;

    // For nullable fields that support explicit null (glasses/features/earrings),
    // only override them when the server actually sent the key.
    final next = state.copyWith(
      seed: seed,
      backgroundColor: s(config['backgroundColor']),
      skinColor: s(config['skinColor']),
      hair: s(config['hair']),
      hairColor: s(config['hairColor']),
      eyes: s(config['eyes']),
      eyebrows: s(config['eyebrows']),
      mouth: s(config['mouth']),
      glassesProbability:
          i(config['glassesProbability'], fallback: state.glassesProbability),
      featuresProbability:
          i(config['featuresProbability'], fallback: state.featuresProbability),
      earringsProbability:
          i(config['earringsProbability'], fallback: state.earringsProbability),
    );

    state = next.copyWith(
      glasses: config.containsKey('glasses') ? s(config['glasses']) : null,
      features: config.containsKey('features') ? s(config['features']) : null,
      earrings: config.containsKey('earrings') ? s(config['earrings']) : null,
    );
  }
}

final avatarOptionsProvider =
    StateNotifierProvider<AvatarOptionsController, AvatarOptions>((ref) {
  // NOTE: Do not watch full userSessionProvider here.
  // userSessionProvider changes on profile edits (firstName/lastName), which would
  // rebuild avatarOptionsProvider and can cascade into app-wide rebuilds.
  // Avatar seed/config only depends on (id, avatarConfig).
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  final seed = user?.id ?? 'guest';

  final ctrl = AvatarOptionsController(AvatarOptions.defaults(seed: seed));

  // Sync from server config if present.
  final serverConfig = user?.avatarConfig;
  if (serverConfig != null && serverConfig.isNotEmpty) {
    ctrl.setFromServer(serverConfig);
  }

  return ctrl;
});

/// Cache-busting stamp for avatar preview images.
///
/// Used to force CachedNetworkImage to re-fetch when avatar is updated.
final avatarPreviewBustProvider = StateProvider<int>((ref) => 0);

final avatarPreviewUrlProvider = Provider<Uri>((ref) {
  final options = ref.watch(avatarOptionsProvider);
  final bust = ref.watch(avatarPreviewBustProvider);

  // Base URL comes from the same config used by the API client.
  final baseUrl = ref.watch(appConfigProvider).baseUrl;

  final uri = buildAdventurerPngUrl(baseUrl, options.toQuery());

  // Always add a cache-busting stamp.
  final qp = Map<String, String>.from(uri.queryParameters);
  qp['t'] = bust.toString();
  return uri.replace(queryParameters: qp);
});

final adventurerSchemaProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final baseUrl = ref.watch(appConfigProvider).baseUrl;
  if (baseUrl.isEmpty) {
    throw StateError('Base URL not configured');
  }

  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  final res = await dio.get('/avatars/dicebear/adventurer.schema.json');
  return Map<String, dynamic>.from(res.data as Map);
});

List<String> schemaEnum(Map schema, String key) {
  final list = schema['properties']?[key]?['items']?['enum'] as List?;
  if (list == null) return const [];
  return list.map((e) => e.toString()).toList();
}

List<String> schemaDefaultColors(Map schema, String key) {
  final list = schema['properties']?[key]?['default'] as List?;
  if (list == null) return const [];
  return list.map((e) => e.toString()).toList();
}
