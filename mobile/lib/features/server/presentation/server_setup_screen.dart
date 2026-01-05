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
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Prefill from synchronous provider once it's loaded from storage.
    // We also update it in build() when state changes to keep it consistent.
    _controller.text = ref.read(baseUrlProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String value) {
    var v = value.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final currentBaseUrl = ref.watch(baseUrlProvider);

    // Keep text field in sync when baseUrl is loaded/changed externally.
    if (_controller.text != currentBaseUrl) {
      _controller.value = _controller.value.copyWith(
        text: currentBaseUrl,
        selection: TextSelection.collapsed(offset: currentBaseUrl.length),
        composing: TextRange.empty,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Server Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Base URL'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final normalized = _normalizeBaseUrl(_controller.text);
                if (normalized.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('baseUrl must not be empty')),
                  );
                  return;
                }

                await ref.read(baseUrlProvider.notifier).setBaseUrl(normalized);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('saved')),
                );

                context.go(AppRoutes.register);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Debug: after app restart this value should be loaded from storage.',
            ),
          ],
        ),
      ),
    );
  }
}
