import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class StubScreenScaffold extends StatelessWidget {
  const StubScreenScaffold({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final buttons = <_NavButtonData>[
      _NavButtonData('Server setup', AppRoutes.server),
      _NavButtonData('Register', AppRoutes.register),
      _NavButtonData('Church select', AppRoutes.church),
      _NavButtonData('Tasks', AppRoutes.tasks),
      _NavButtonData('Shop', AppRoutes.shop),
      _NavButtonData('Inventory', AppRoutes.inventory),
      _NavButtonData('Stats', AppRoutes.stats),
      _NavButtonData('Admin panel', AppRoutes.admin),
      _NavButtonData('Admin / Pending submissions', AppRoutes.adminPending),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final b = buttons[index];
          return FilledButton(
            onPressed: () => context.go(b.path),
            child: Text('Next: ${b.label} (${b.path})'),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: buttons.length,
      ),
    );
  }
}

class _NavButtonData {
  _NavButtonData(this.label, this.path);

  final String label;
  final String path;
}
