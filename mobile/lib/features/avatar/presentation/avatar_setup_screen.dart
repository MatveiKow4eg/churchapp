import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../avatar_setup_provider.dart';

class AvatarSetupScreen extends ConsumerWidget {
  const AvatarSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аватар'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Надо создать аватар',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Без аватара нельзя продолжить.\n\n'
                'Сейчас это заглушка: кнопка «Сохранить» просто помечает аватар как созданный локально.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(avatarSetupProvider.notifier).markCreated();
                  if (context.mounted) {
                    context.go(AppRoutes.tasks);
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
