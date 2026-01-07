import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/providers.dart';
import '../features/admin/presentation/admin_panel_screen.dart';
import '../features/superadmin/presentation/superadmin_panel_screen.dart';
import '../features/admin/presentation/no_access_screen.dart';
import '../features/admin/presentation/pending_submissions_screen.dart';
import '../features/admin/tasks/admin_tasks_screen.dart';
import '../features/admin/tasks/create_task_screen.dart';
import '../features/admin/tasks/edit_task_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/session_providers.dart';
import '../features/auth/user_session_provider.dart';
import '../features/church/church_select_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/server/presentation/server_setup_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/submissions/my_submissions_screen.dart';
import '../features/tasks/presentation/task_details_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/avatar/avatar_providers.dart';
import '../features/avatar/presentation/avatar_thumb_image.dart';
import '../features/avatar/presentation/avatar_customize_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    // Keep as-is; redirects will enforce correct route.
    initialLocation: AppRoutes.server,
    refreshListenable: refreshListenable,
    routes: <RouteBase>[
      // Bootstrap / auth flow routes (no bottom navigation)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.server,
        builder: (context, state) => const ServerSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.church,
        builder: (context, state) => const ChurchSelectScreen(),
      ),

      // App shell (bottom navigation)
      ShellRoute(
        builder: (context, state, child) => _AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return TaskDetailsScreen(taskId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.shop,
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.submissionsMine,
            builder: (context, state) => const MySubmissionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.avatar,
            builder: (context, state) => const AvatarCustomizeScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const _ProfileScreenPlaceholder(),
          ),
          // Admin inside shell so bottom navigation stays visible.
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, state) => const AdminPanelScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: 'pending',
                builder: (context, state) => const PendingSubmissionsScreen(),
              ),
              GoRoute(
                path: 'tasks',
                builder: (context, state) => const AdminTasksScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateTaskScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EditTaskScreen(taskId: id);
                    },
                  ),
                ],
              ),
              // Superadmin panel under /admin so it stays inside the shell.
              GoRoute(
                path: 'superadmin',
                builder: (context, state) => const SuperAdminPanelScreen(),
              ),
            ],
          ),
        ],
      ),
      // NOTE: Superadmin screen moved under /admin/superadmin to keep bottom navigation.
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (context, state) => const NoAccessScreen(),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Read all gate providers. GoRouter will re-run redirect via refreshListenable.
      final baseUrlAsync = ref.read(baseUrlProvider);
      final tokenAsync = ref.read(authTokenProvider);
      final userAsync = ref.read(currentUserProvider);

      // 1) LOADING gate: splash is used ONLY as loading screen.
      // If anything required for routing is still resolving, force /splash.
      if (baseUrlAsync.isLoading || tokenAsync.isLoading || userAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2) BaseUrl gate
      final baseUrl = baseUrlAsync.valueOrNull ?? '';
      if (baseUrl.isEmpty) {
        // Server setup must be reachable only in "no baseUrl" state.
        return loc == AppRoutes.server ? null : AppRoutes.server;
      }

      // If baseUrl is configured, /server must not be a terminal location.
      if (loc == AppRoutes.server) return AppRoutes.splash;

      // 3) Auth gate (token + user)
      final token = tokenAsync.valueOrNull;
      final user = userAsync.valueOrNull;

      // If token is missing OR session resolved as unauthenticated -> /login.
      // Keep /register reachable from /login.
      if (token == null || token.isEmpty || user == null) {
        if (loc == AppRoutes.register) return null;
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      // 4) User is present: route by church flow
      // Make routing decision based on role FIRST.

      // SUPERADMIN: allow /superadmin even without church.
      // IMPORTANT: do NOT redirect superadmin to /tasks from /superadmin,
      // otherwise they get kicked back into tasks where API returns NO_CHURCH.
      final role = user.role.trim().toUpperCase();
      if (role == 'SUPERADMIN') {
        if (loc == AppRoutes.superadmin) return null;

        final isInShell = loc.startsWith(AppRoutes.tasks) ||
            loc.startsWith(AppRoutes.shop) ||
            loc.startsWith(AppRoutes.inventory) ||
            loc.startsWith(AppRoutes.stats) ||
            loc.startsWith(AppRoutes.submissionsMine) ||
            loc.startsWith(AppRoutes.avatar) ||
            loc.startsWith(AppRoutes.admin);

        // If they are in any bootstrap/auth screens, jump into the shell.
        if (!isInShell &&
            (loc == AppRoutes.splash ||
                loc == AppRoutes.login ||
                loc == AppRoutes.register ||
                loc == AppRoutes.server ||
                loc == AppRoutes.church)) {
          return AppRoutes.tasks;
        }

        // No other redirects for superadmin.
        return null;
      }

      // NON-superadmin: must pick a church before entering the shell.
      final churchId = user.churchId;
      if (churchId == null) {
        // Allow SUPERADMIN/SUPERADMIN to access superadmin area without church.
        // Everyone else must pick a church.
        return AppRoutes.church;
      }

      // User has a church: normal flow.
      if (loc == AppRoutes.splash ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.server ||
          loc == AppRoutes.church) {
        return AppRoutes.tasks;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Route not found')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(state.error?.toString() ?? 'Unknown routing error'),
      ),
    ),
  );
});

/// Central place for route paths.
abstract final class AppRoutes {
  static const server = '/server';
  static const splash = '/splash';
  static const register = '/register';
  static const login = '/login';
  static const church = '/church';

  // Main tabs
  static const tasks = '/tasks';
  static const shop = '/shop';
  static const inventory = '/inventory';
  static const stats = '/stats';
  static const submissionsMine = '/submissions/mine';
  static const avatar = '/avatar';

  // Profile / side menu entry point
  static const profile = '/profile';

  // Admin
  static const admin = '/admin';
  static const superadmin = '/superadmin';
  static const forbidden = '/403';

  static const adminPending = '/admin/pending';
  static const adminTasks = '/admin/tasks';
}

class _ProfileScreenPlaceholder extends ConsumerWidget {
  const _ProfileScreenPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    Widget header;
    header = userAsync.when(
      data: (user) {
        final firstName = (user?.firstName ?? '').trim();
        final lastName = (user?.lastName ?? '').trim();
        final name = ('$firstName $lastName').trim();
        final role = (user?.role ?? '').trim();
        final avatarUrl = ref.watch(avatarPreviewUrlProvider);
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ClipOval(
              child: AvatarThumbImage(
                url: avatarUrl,
                fit: BoxFit.cover,
                cacheWidth: 96,
              ),
            ),
          ),
          title: Text(name.isNotEmpty ? name : 'Пользователь'),
          subtitle: Text(role.isNotEmpty ? role : ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.avatar),
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(radius: 24, child: Icon(Icons.person)),
        title: Text('Загрузка...'),
      ),
      error: (e, _) => ListTile(
        leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        title: const Text('Профиль'),
        subtitle: Text(e.toString()),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.tasks);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          header,
          const Divider(height: 1),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.face_outlined),
            title: const Text('Аватар'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.avatar),
          ),
                    ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Статистика'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.stats),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text('Сменить церковь'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.church),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isAdmin = ref.watch(isAdminProvider);
              if (!isAdmin) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Админ-панель'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.admin),
              );
            },
          ),
        ],
      ),
    );
  }
}

final class _AppShell extends ConsumerWidget {
  const _AppShell({
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  List<String> _tabs({required bool isAdmin}) {
    // Order matters: index in this list == NavigationBar index.
    // Bottom navigation must have only two tabs: Tasks and My Submissions.
    // Admin stays reachable via routes, but not as a bottom tab.
    return const <String>[
      AppRoutes.tasks,
      AppRoutes.submissionsMine,
    ];
  }

  int _indexFromLocation(String loc, {required List<String> tabs}) {
    for (var i = 0; i < tabs.length; i++) {
      if (loc.startsWith(tabs[i])) return i;
    }
    return 0;
  }

  String _locationFromIndex(int index, {required List<String> tabs}) {
    if (index < 0 || index >= tabs.length) return AppRoutes.tasks;
    return tabs[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final tabs = _tabs(isAdmin: isAdmin);

    final currentIndex = _indexFromLocation(location, tabs: tabs);

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.checklist_outlined),
        selectedIcon: Icon(Icons.checklist),
        label: 'Задания',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: 'Мои заявки',
      ),
    ];

    final hideBottomBar = location.startsWith(AppRoutes.profile) ||
        location.startsWith(AppRoutes.avatar) ||
        location.startsWith(AppRoutes.shop) ||
        location.startsWith(AppRoutes.inventory) ||
        location.startsWith(AppRoutes.stats) ||
        location.startsWith(AppRoutes.church);

    return Scaffold(
      body: child,
      bottomNavigationBar: hideBottomBar
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (idx) {
                final target = _locationFromIndex(idx, tabs: tabs);
                if (target == location) return;
                context.go(target);
              },
              destinations: destinations,
            ),
    );
  }
}
