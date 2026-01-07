import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/providers/providers.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  late final TextEditingController _controller;
  ProviderSubscription<AsyncValue<String>>? _baseUrlSub;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: '');

    // Correct pattern for ConsumerState:
    // - use listenManual in initState
    // - close subscription in dispose
    _baseUrlSub = ref.listenManual<AsyncValue<String>>(
      baseUrlProvider,
      (prev, next) {
        next.whenOrNull(
          data: (value) {
            if (_controller.text == value) return;
            _controller.value = _controller.value.copyWith(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
              composing: TextRange.empty,
            );
          },
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _baseUrlSub?.close();
    _controller.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String value) {
    var v = value.trim();

    // Accept common inputs like "10.0.2.2:3000" and normalize to a valid URL.
    // Dio requires a scheme in baseUrl.
    if (v.isNotEmpty && !v.contains('://')) {
      v = 'http://$v';
    }

    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }

    return v;
  }

  @override
  Widget build(BuildContext context) {
    final baseUrlAsync = ref.watch(baseUrlProvider);
    final currentBaseUrl = baseUrlAsync.valueOrNull ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Server Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Base URL'),
            const SizedBox(height: 8),
            if (baseUrlAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (baseUrlAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ошибка загрузки baseUrl: ${baseUrlAsync.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:3000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: baseUrlAsync.isLoading
                  ? null
                  : () async {
                      final normalized = _normalizeBaseUrl(_controller.text);
                      if (normalized.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('baseUrl must not be empty'),
                          ),
                        );
                        return;
                      }

                      await ref
                          .read(baseUrlProvider.notifier)
                          .setBaseUrl(normalized);

                      if (!context.mounted) return;
                      context.go(AppRoutes.splash);
                    },
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
            Text(
              'Current: $currentBaseUrl',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
