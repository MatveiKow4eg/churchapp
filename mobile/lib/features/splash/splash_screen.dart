import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(authTokenProvider);
    final userAsync = ref.watch(currentUserProvider);

    final isLoading = tokenAsync.isLoading || userAsync.isLoading;
    final hasError = tokenAsync.hasError || userAsync.hasError;

    if (hasError) {
      final Object? error = tokenAsync.error ?? userAsync.error;

      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Не удалось инициализировать приложение',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error?.toString() ?? 'Unknown error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(authTokenProvider.notifier)
                              .clearToken();
                        },
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка...'),
              ],
            ),
          ),
        ),
      );
    }

    // Splash is a pure intermediate screen.
    // Navigation is handled exclusively by GoRouter.redirect.
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...'),
            ],
          ),
        ),
      ),
    );
  }
}
