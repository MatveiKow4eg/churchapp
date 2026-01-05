import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/providers.dart';
import '../features/admin/presentation/admin_panel_screen.dart';
import '../features/admin/presentation/no_access_screen.dart';
import '../features/admin/presentation/pending_submissions_screen.dart';
import '../features/admin/tasks/admin_tasks_screen.dart';
import '../features/admin/tasks/create_task_screen.dart';
import '../features/admin/tasks/edit_task_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/user_session_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/session_providers.dart';
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
        path: AppRoutes.forbidden,
        builder: (context, state) => const NoAccessScreen(),
      ),
    ],
    redirect: (context, state) {
      final baseUrl = ref.read(baseUrlProvider);
      final loc = state.matchedLocation;

      // /server is always accessible
      if (loc == AppRoutes.server) return null;

      // 1) Base URL gate: must be configured first.
      if (baseUrl.isEmpty) {
        return AppRoutes.server;
      }

      final authAsync = ref.read(authStateProvider);

      // While loading storage/me -> show splash (avoid loops)
      if (authAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // If provider errored, keep user on splash (avoid bouncing to auth/server)
      if (authAsync.hasError) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final auth = authAsync.valueOrNull;
      if (auth == null) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Rules:
      // - If no token -> always /register (except /server)
      // - If token but churchId == null -> always /church (except /server)
      // - If token and churchId != null -> /register and /church -> /tasks

      if (auth is Unauthenticated) {
        // Allow /login and /register without token.
        if (loc == AppRoutes.register || loc == AppRoutes.login) return null;
        return AppRoutes.register;
      }

      if (auth is AuthenticatedNoChurch) {
        // If user has no church, keep them in church flow even if they try /admin.
        return loc == AppRoutes.church ? null : AppRoutes.church;
      }

      if (auth is AuthenticatedReady) {
        if (loc == AppRoutes.register ||
            loc == AppRoutes.login ||
            loc == AppRoutes.church) {
          return AppRoutes.tasks;
        }

        // Admin guard
        if (loc == AppRoutes.admin || loc.startsWith('${AppRoutes.admin}/')) {
          final isAdmin = ref.read(isAdminProvider);
          if (!isAdmin) {
            return AppRoutes.forbidden;
          }
        }

        return null;
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
  static const forbidden = '/403';

  static const adminPending = '/admin/pending';
  static const adminTasks = '/admin/tasks';
}
