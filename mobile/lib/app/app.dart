import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presence/presence_ping_service.dart';
import '../core/providers/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  PresencePingService? _presence;

  @override
  void initState() {
    super.initState();

    // Start presence pings a moment after startup so providers are ready.
    Future.microtask(() {
      if (!mounted) return;
      final apiClient = ref.read(apiClientProvider);
      _presence = PresencePingService(apiClient: apiClient);
      _presence?.start();
    });
  }

  @override
  void dispose() {
    _presence?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.read(appRouterProvider);
    final themeState = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'App MVP',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        brightness: Brightness.light,
        accentColor: themeState.accentColor,
      ),
      darkTheme: buildTheme(
        brightness: Brightness.dark,
        accentColor: themeState.accentColor,
      ),
      themeMode: themeState.mode == AppThemeMode.system
          ? ThemeMode.system
          : themeState.mode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
      routerConfig: router,
    );
  }
}
