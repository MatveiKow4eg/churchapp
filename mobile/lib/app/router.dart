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
import '../features/avatar/avatar_setup_provider.dart';
import '../features/avatar/presentation/avatar_thumb_image.dart';
import '../features/avatar/presentation/avatar_customize_screen.dart';
import '../features/avatar/presentation/avatar_setup_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/change_password_screen.dart';
import '../features/profile/presentation/change_email_screen.dart';
import '../features/bible/presentation/bible_books_screen.dart';
import '../features/bible/presentation/bible_chapter_screen.dart';
import '../features/bible/presentation/bible_search_screen.dart';
import '../features/bible/presentation/bible_search_all_screen.dart';
import '../features/bible/models/bible_search.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  debugPrint('appRouterProvider created');
  final refreshListenable = ref.watch(routerRefreshNotifierProvider);

  // IMPORTANT:
  // Do not `watch` user/auth providers here to avoid recreating GoRouter.
  // GoRouter must be stable; use refreshListenable + redirect() for re-evaluation.
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
      GoRoute(
        path: AppRoutes.avatarSetup,
        builder: (context, state) => const AvatarCustomizeScreen(),
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
            path: AppRoutes.bible,
            builder: (context, state) => const BibleBooksScreen(),
            routes: <RouteBase>[
              // Static routes must be above dynamic ':bookId/:chapter'.
              GoRoute(
                path: 'search',
                builder: (context, state) => const BibleSearchScreen(),
              ),
              GoRoute(
                path: 'search-all',
                builder: (context, state) {
                  String query = '';
                  List<BibleSearchHit> initial = const [];

                  final extra = state.extra;
                  if (extra is Map) {
                    final qAny = extra['query'];
                    if (qAny is String) query = qAny;
                    final initAny = extra['initialResults'];
                    if (initAny is List) {
                      initial = initAny.whereType<BibleSearchHit>().toList();
                    }
                  }

                  return BibleSearchAllScreen(
                    query: query,
                    initialResults: initial,
                  );
                },
              ),
              GoRoute(
                path: ':bookId/:chapter',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId']!;
                  final chapter = int.parse(state.pathParameters['chapter']!);

                  String bookName = bookId;
                  int? maxChapters;

                  final extra = state.extra;
                  if (extra is Map) {
                    final nameAny = extra['bookName'];
                    if (nameAny is String && nameAny.trim().isNotEmpty) {
                      bookName = nameAny;
                    }
                    final maxAny = extra['maxChapters'];
                    if (maxAny is int) {
                      maxChapters = maxAny;
                    } else if (maxAny is String) {
                      maxChapters = int.tryParse(maxAny);
                    }
                  }

                  int? highlightVerse;
                  int? highlightToVerse;
                  String? highlightQuery;
                  final extraHv = state.extra;
                  if (extraHv is Map) {
                    final hvAny = extraHv['highlightVerse'];
                    if (hvAny is int) {
                      highlightVerse = hvAny;
                    } else if (hvAny is String) {
                      highlightVerse = int.tryParse(hvAny);
                    }

                    final htvAny = extraHv['highlightToVerse'];
                    if (htvAny is int) {
                      highlightToVerse = htvAny;
                    } else if (htvAny is String) {
                      highlightToVerse = int.tryParse(htvAny);
                    }

                    final hqAny = extraHv['highlightQuery'];
                    if (hqAny is String && hqAny.trim().isNotEmpty) {
                      highlightQuery = hqAny.trim();
                    }
                  }

                  return BibleChapterScreen(
                    bookId: bookId,
                    bookName: bookName,
                    initialChapter: chapter,
                    maxChapters: maxChapters,
                    highlightVerse: highlightVerse,
                    highlightToVerse: highlightToVerse,
                    highlightQuery: highlightQuery,
                  );
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
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsEditProfile,
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsChangePassword,
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsChangeEmail,
            builder: (context, state) => const ChangeEmailScreen(),
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
      //
      // NOTE: `currentUserProvider` can legitimately stay in loading state when
      // there is no token/baseUrl (because it awaits those gates). In that case
      // we must NOT force /splash forever.
      final baseUrlResolved = !baseUrlAsync.isLoading;
      final tokenResolved = !tokenAsync.isLoading;
      final baseUrl = baseUrlAsync.valueOrNull ?? '';
      final token = tokenAsync.valueOrNull;

      final userNeedsToBeResolved = baseUrlResolved && tokenResolved && baseUrl.isNotEmpty && (token?.isNotEmpty ?? false);

      if (baseUrlAsync.isLoading || tokenAsync.isLoading || (userNeedsToBeResolved && userAsync.isLoading)) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2) BaseUrl gate
      if (baseUrl.isEmpty) {
        // Server setup must be reachable only in "no baseUrl" state.
        return loc == AppRoutes.server ? null : AppRoutes.server;
      }

      // If baseUrl is configured, /server must not be a terminal location.
      if (loc == AppRoutes.server) return AppRoutes.splash;

      // 3) Auth gate (token + user)
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
            loc.startsWith(AppRoutes.bible) ||
            loc.startsWith(AppRoutes.shop) ||
            loc.startsWith(AppRoutes.inventory) ||
            loc.startsWith(AppRoutes.stats) ||
            loc.startsWith(AppRoutes.submissionsMine) ||
            loc.startsWith(AppRoutes.avatar) ||
            loc.startsWith(AppRoutes.admin) ||
            loc.startsWith(AppRoutes.profile) ||
            loc.startsWith(AppRoutes.settings);

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

      // 5) Avatar setup gate (server-driven)
      // Backend stores avatarConfig/avatarUpdatedAt, so rely on /auth/me payload.
      // If user is authenticated and already has churchId, but avatar is absent,
      // we MUST keep them on /avatar/setup (and not bounce to /tasks).
      final hasAvatar = user.hasAvatar;

      if (!hasAvatar) {
        // Allow staying on avatar setup.
        if (loc == AppRoutes.avatarSetup) return null;
        // Allow avatar flow itself.
        if (loc.startsWith(AppRoutes.avatar)) return null;
        // Allow going back to church selection from setup.
        if (loc == AppRoutes.church) return null;
        return AppRoutes.avatarSetup;
      }

      // User has a church and avatar: normal flow.
      // Redirect only from bootstrap/auth flow screens into the app shell.
      // For any valid in-shell location (including /settings), do NOT override it.
      if (loc == AppRoutes.splash ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.server ||
          loc == AppRoutes.church) {
        return AppRoutes.tasks;
      }

      // If user is authenticated and has churchId, keep current location.
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
  static const avatarSetup = '/avatar/setup';

  // Profile / side menu entry point
  static const profile = '/profile';

  // Settings
  static const settings = '/settings';
  static const settingsEditProfile = '/settings/edit-profile';
  static const settingsChangePassword = '/settings/change-password';
  static const settingsChangeEmail = '/settings/change-email';

  // Admin
  static const admin = '/admin';
  static const superadmin = '/superadmin';
  static const forbidden = '/403';

  // Bible
  static const bible = '/bible';
  static const bibleSearch = '/bible/search';
  static const bibleChapter = '/bible/:bookId/:chapter';
  static const bibleSearchAll = '/bible/search-all';

  static const adminPending = '/admin/pending';
  static const adminTasks = '/admin/tasks';
}

class _InDevelopmentScreen extends StatelessWidget {
  const _InDevelopmentScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('В разработке')),
    );
  }
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
        final roleRaw = (user?.role ?? '').trim();
        final roleNorm = roleRaw.toUpperCase();
        final roleLabel = (roleNorm.isEmpty || roleNorm == 'USER') ? '' : roleRaw;
        final avatarUrl = ref.watch(avatarPreviewUrlProvider);
        final hasAvatar = user?.hasAvatar ?? false;
        return ListTile(
          leading: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go(hasAvatar ? AppRoutes.avatar : AppRoutes.avatarSetup),
            child: CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ClipOval(
                child: AvatarThumbImage(
                  url: avatarUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 96,
                ),
              ),
            ),
          ),
          title: Text(name.isNotEmpty ? name : 'Пользователь'),
          subtitle: Text(roleLabel),
          trailing: const Icon(Icons.chevron_right),
          // Tap on the tile opens avatar editor if avatar exists, otherwise avatar setup.
          onTap: () => context.go(
            hasAvatar ? AppRoutes.avatar : AppRoutes.avatarSetup,
          ),
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
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
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
            onTap: () => context.go(
              (ref.read(currentUserProvider).valueOrNull?.hasAvatar ?? false)
                  ? AppRoutes.avatar
                  : AppRoutes.avatarSetup,
            ),
          ),
                    ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Статистика'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.stats),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(authTokenProvider.notifier).clearToken();
              ref.invalidate(currentUserProvider);
              context.go(AppRoutes.login);
            },
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

final class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  late final PageController _pageController;

  List<String> _tabs({required bool isAdmin}) {
    // Order matters: index in this list == NavigationBar index.
    // Bottom navigation: Tasks, Bible, My Submissions.
    // Admin stays reachable via routes, but not as a bottom tab.
    return const <String>[
      AppRoutes.tasks,
      AppRoutes.bible,
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
  void initState() {
    super.initState();
    final isAdmin = ref.read(isAdminProvider);
    final tabs = _tabs(isAdmin: isAdmin);
    final initialIndex = _indexFromLocation(widget.location, tabs: tabs);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(covariant _AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isAdmin = ref.read(isAdminProvider);
    final tabs = _tabs(isAdmin: isAdmin);
    final newIndex = _indexFromLocation(widget.location, tabs: tabs);
    final atRoot = tabs.contains(widget.location);
    if (atRoot && _pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
      if (currentPage != newIndex) {
        _pageController.jumpToPage(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final child = widget.child;

    debugPrint('Shell build location=$location');
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
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Библия',
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
        location.startsWith(AppRoutes.church) ||
        location.startsWith(AppRoutes.admin) ||
        location.startsWith(AppRoutes.superadmin) ||
        location.startsWith('/bible/');

    final atRoot = tabs.contains(location);

    final body = (!hideBottomBar && atRoot)
        ? PageView(
            controller: _pageController,
            onPageChanged: (idx) {
              final target = _locationFromIndex(idx, tabs: tabs);
              if (target != location) {
                context.go(target);
              }
            },
            children: const [
              TasksScreen(),
              BibleBooksScreen(),
              MySubmissionsScreen(),
            ],
          )
        : child;

    return Scaffold(
      body: body,
      bottomNavigationBar: hideBottomBar
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (idx) {
                if (!atRoot) {
                  final target = _locationFromIndex(idx, tabs: tabs);
                  if (target != location) context.go(target);
                  return;
                }
                if (_pageController.hasClients) {                  final distance = (currentIndex - idx).abs();
                  if (distance <= 1) {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  } else {
                    // Jump for non-adjacent to avoid passing through middle page visually.
                    _pageController.jumpToPage(idx);
                  }
                }
              },
              destinations: destinations,
            ),
    );
  }
}
