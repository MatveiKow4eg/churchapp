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

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    // Keep as-is; redirects will enforce correct route.
    initialLocation: AppRoutes.server,
    refreshListenable: refreshListenable,
    routes: <RouteBase>[
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
        ],
      ),
      GoRoute(
        path: AppRoutes.superadmin,
        builder: (context, state) => const SuperAdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (context, state) => const NoAccessScreen(),
      ),
    ],
    redirect: (context, state) {
      final baseUrlAsync = ref.read(baseUrlProvider);
      final loc = state.matchedLocation;

      // 0) While baseUrl is loading from storage, do not make any decision
      // other than keeping user on /splash.
      if (baseUrlAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // If baseUrl failed to load, keep user on /splash (SplashScreen shows actions).
      if (baseUrlAsync.hasError) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final baseUrl = baseUrlAsync.value ?? '';

      // 1) Base URL gate: must be configured first.
      // If baseUrl is missing, ALWAYS send to /server.
      if (baseUrl.isEmpty) {
        return loc == AppRoutes.server ? null : AppRoutes.server;
      }

      // /server is always accessible
      if (loc == AppRoutes.server) return null;

      // /splash is not a terminal state. If we are on /splash and all required
      // state is already resolved, redirect will move us away.

      // Token must be resolved before we can make any auth decision.
      final tokenAsync = ref.read(authTokenProvider);
      if (tokenAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final userAsync = ref.read(currentUserProvider);

      // While /auth/me is being resolved, stay on splash.
      if (userAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // If /auth/me failed, clear token and go to /login.
      if (userAsync.hasError) {
        ref.read(authTokenProvider.notifier).clearToken();
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      final user = userAsync.value;

      // DEBUG (temporary)
      final token = ref.read(authTokenProvider).valueOrNull;
      // ignore: avoid_print
      print(
        '[router] loc=$loc token=${token == null ? 'null' : token.substring(0, token.length < 20 ? token.length : 20)} user=${user == null ? 'null' : user.id} role=${user?.role} churchId=${user?.churchId}',
      );

      // Unauthenticated: no user.
      if (user == null) {
        if (loc == AppRoutes.login || loc == AppRoutes.register) return null;
        return AppRoutes.login;
      }

      // We derive role/churchId from the server-confirmed user (via /auth/me).
      final role = user.role;
      final churchId = user.churchId;
      final isSuperAdmin = role == 'SUPERADMIN';

      // Guard: /superadmin must be accessible ONLY for real SUPERADMIN.
      if (loc == AppRoutes.superadmin && !isSuperAdmin) {
        // If you're not superadmin, don't allow manual deep-link to superadmin.
        return AppRoutes.forbidden;
      }

      // SUPERADMIN must never be forced into church selection.
      if (isSuperAdmin) {
        // Allow them only /superadmin (and also let /403 be reachable)
        if (loc == AppRoutes.superadmin || loc == AppRoutes.forbidden) {
          return null;
        }
        return AppRoutes.superadmin;
      }

      // Non-superadmin users without church must complete church flow.
      if (churchId == null) {
        if (loc == AppRoutes.church) return null;
        return AppRoutes.church;
      }

      // Non-superadmin users with church: block auth/church screens.
      if (loc == AppRoutes.register ||
          loc == AppRoutes.login ||
          loc == AppRoutes.church) {
        return AppRoutes.tasks;
      }

      // Admin guard (for ADMIN only; SUPERADMIN already handled above)
      if (loc == AppRoutes.admin || loc.startsWith('${AppRoutes.admin}/')) {
        final isAdmin = ref.read(isAdminProvider);
        if (!isAdmin) {
          return AppRoutes.forbidden;
        }
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
  static const tasks = '/tasks';
  static const submissionsMine = '/submissions/mine';
  static const shop = '/shop';
  static const inventory = '/inventory';
  static const stats = '/stats';
  static const admin = '/admin';
  static const superadmin = '/superadmin';
  static const forbidden = '/403';

  static const adminPending = '/admin/pending';
  static const adminTasks = '/admin/tasks';
}
