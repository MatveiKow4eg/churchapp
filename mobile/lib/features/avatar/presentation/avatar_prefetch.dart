import 'package:flutter/material.dart';

/// Prefetch a batch of thumbnail images into Flutter's image cache.
///
/// - Skips null items (used for "Off").
/// - Caps total items via [maxItems].
/// - Limits concurrent in-flight prefetches via [maxConcurrent] to avoid
///   flooding the network/proxy.
Future<void> prefetchThumbs({
  required BuildContext context,
  required List<String?> itemsWithOff,
  required Uri Function(String? item) urlBuilder,
  int maxConcurrent = 4,
  int maxItems = 60,
}) async {
  final items = itemsWithOff
      .where((e) => e != null)
      .take(maxItems)
      .toList(growable: false);

  if (items.isEmpty) return;

  // Simple worker pool.
  var index = 0;

  Future<void> worker() async {
    while (true) {
      final i = index;
      if (i >= items.length) return;
      index = i + 1;

      final item = items[i];
      final uri = urlBuilder(item);

      try {
        await precacheImage(NetworkImage(uri.toString()), context);
      } catch (e) {
        // Prefetch failures should be silent; runtime widget will retry.
        debugPrint('[prefetchThumbs] failed url=$uri error=$e');
      }
    }
  }

  final poolSize = maxConcurrent.clamp(1, 32);
  await Future.wait(List.generate(poolSize, (_) => worker()));
}
