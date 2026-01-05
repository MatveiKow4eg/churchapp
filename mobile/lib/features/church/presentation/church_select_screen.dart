import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../church_providers.dart';

class ChurchSelectScreen extends ConsumerStatefulWidget {
  const ChurchSelectScreen({super.key});

  @override
  ConsumerState<ChurchSelectScreen> createState() => _ChurchSelectScreenState();
}

class _ChurchSelectScreenState extends ConsumerState<ChurchSelectScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String _searchText = '';
  String _debouncedText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    ref.listen<AsyncValue>(
      churchSearchProvider,
      (prev, next) {
        next.whenOrNull(
          error: (err, st) {
            final msg = err.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() => _searchText = text);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final debounced = _controller.text.trim();
      setState(() => _debouncedText = debounced);

      // Trigger search AFTER debounce (debounce remains in UI).
      ref.read(churchSearchProvider.notifier).search(debounced);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(churchSearchProvider);

    final query = _debouncedText.trim();

    Widget content;

    if (query.isEmpty) {
      content = const _InfoBox(
        text: 'Начни вводить название',
        icon: Icons.info_outline,
      );
    } else if (query.length < 2) {
      content = const _InfoBox(
        text: 'Введите минимум 2 символа',
        icon: Icons.info_outline,
      );
    } else if (_searchText.trim().isNotEmpty && _debouncedText.trim().isEmpty) {
      content = const _InfoBox(
        text: 'Введите название церкви',
        icon: Icons.search,
      );
    } else {
      content = async.when(
        data: (items) {
          if (items.isEmpty) {
            return const _InfoBox(
              text: 'Ничего не найдено',
              icon: Icons.search_off,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...items.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: c.city == null ? null : Text(c.city!),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Выбрано: ${c.name}')),
                        );
                      },
                      trailing: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Выбрано: ${c.name}')),
                          );
                        },
                        child: const Text('Войти'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, st) => const _InfoBox(
          text: 'Не удалось загрузить',
          icon: Icons.error_outline,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор церкви')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Выбор церкви',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Введи название церкви и вы��ери из списка',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Например: Jumala sõna',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Результаты поиска',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
