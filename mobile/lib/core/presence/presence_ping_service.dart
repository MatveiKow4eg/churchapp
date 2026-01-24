import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Lightweight presence approximation.
///
/// Client periodically calls POST /me/ping while app is running.
/// Backend stores `User.lastSeenAt` and church stats compute online users as
/// ACTIVE users with lastSeenAt within a short window.
class PresencePingService {
  PresencePingService({
    required ApiClient apiClient,
    Duration interval = const Duration(minutes: 1),
  })  : _apiClient = apiClient,
        _interval = interval;

  final ApiClient _apiClient;
  final Duration _interval;

  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // Fire immediately, then periodically.
    _pingOnce();
    _timer = Timer.periodic(_interval, (_) => _pingOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> _pingOnce() async {
    try {
      await _apiClient.dio.post('/me/ping');
    } catch (e) {
      // Presence ping must never break the app.
      if (kDebugMode) {
        // ignore: avoid_print
        print('[presence] ping failed: $e');
      }
    }
  }
}
