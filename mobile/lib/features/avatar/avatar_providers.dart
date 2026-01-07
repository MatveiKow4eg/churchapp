import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/user_session_provider.dart';
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
}

final avatarOptionsProvider =
    StateNotifierProvider<AvatarOptionsController, AvatarOptions>((ref) {
  final user = ref.watch(userSessionProvider);
  final seed = user?.id ?? 'guest';

  return AvatarOptionsController(AvatarOptions.defaults(seed: seed));
});

final avatarPreviewUrlProvider = Provider<Uri>((ref) {
  final options = ref.watch(avatarOptionsProvider);

  // Base URL comes from the same config used by the API client.
  final baseUrl = ref.watch(baseUrlProvider).valueOrNull ?? '';

  return buildAdventurerPngUrl(baseUrl, options.toQuery());
});

final adventurerSchemaProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final baseUrl = ref.watch(appConfigProvider).baseUrl;
  if (baseUrl.isEmpty || baseUrl == kBaseUrlLoadingMarker) {
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
