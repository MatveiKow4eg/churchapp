import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
