import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/providers/providers.dart';
import '../../auth/models/user_model.dart';
import '../../auth/session_providers.dart';
import '../avatar_providers.dart';
import '../dicebear/schema_utils.dart';
import 'avatar_preview_urls.dart';
import 'avatar_thumb_image.dart';
import 'avatar_prefetch.dart';
import 'widgets/svg_tab_icon.dart';

class AvatarCustomizeScreen extends ConsumerStatefulWidget {
  const AvatarCustomizeScreen({super.key});

  @override
  ConsumerState<AvatarCustomizeScreen> createState() =>
      _AvatarCustomizeScreenState();
}

class _AvatarCustomizeScreenState extends ConsumerState<AvatarCustomizeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  final Set<int> _prefetchedTabs = <int>{};
  final Map<int, Map<String, dynamic>> _tabBaseOptions =
      <int, Map<String, dynamic>>{};

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      // Only react once the index has settled.
      if (_tabController.indexIsChanging) return;
      if (_tabIndex == _tabController.index) return;
      setState(() {
        _tabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ref.watch(avatarPreviewUrlProvider).toString();

    final controller = ref.read(avatarOptionsProvider.notifier);
    final options = ref.watch(avatarOptionsProvider);

    final schemaAsync = ref.watch(adventurerSchemaProvider);

    const tabIconAssets = <String>[
      'assets/icons/avatar_tabs/hair.svg',
      'assets/icons/avatar_tabs/eyes.svg',
      'assets/icons/avatar_tabs/eyebrows.svg',
      'assets/icons/avatar_tabs/mouth.svg',
      'assets/icons/avatar_tabs/extras.svg',
      'assets/icons/avatar_tabs/colors.svg',
    ];

    Widget bigPreview({required double size}) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              final expected = loadingProgress.expectedTotalBytes;
              final loaded = loadingProgress.cumulativeBytesLoaded;
              final value = expected == null ? null : loaded / expected;

              return Center(
                child: CircularProgressIndicator(value: value),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Avatar error: $error');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        imageUrl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    List<String> enumList(Map<String, dynamic> schema, String key) {
      final list =
          (schema['properties']?[key]?['items']?['enum'] as List?) ?? const [];
      return List<String>.from(list);
    }

    List<String> defaultList(Map<String, dynamic> schema, String key) {
      final list =
          (schema['properties']?[key]?['default'] as List?) ?? const [];
      return List<String>.from(list);
    }

    const fallbackSchema = {
      'properties': {
        'backgroundColor': {
          'default': ['b6e3f4', 'c0aede', 'd1d4f9', 'ffd5dc', 'ffdfbf']
        },
        'skinColor': {
          'default': ['9e5622', '763900', 'ecad80', 'f2d3b1']
        },
        'hairColor': {
          'default': ['0e0e0e', '6a4e35', 'afafaf', 'cb6820', 'dba3be', 'e5d7a3']
        },
        'hair': {
          'items': {
            'enum': [
              'short01',
              'short02',
              'short03',
              'short04',
              'short05',
              'short12',
              'long01',
              'long02',
              'long03',
              'long04',
              'long05'
            ]
          }
        },
        'eyes': {
          'items': {
            'enum': [
              'variant01',
              'variant02',
              'variant03',
              'variant04',
              'variant05',
              'variant06'
            ]
          }
        },
        'eyebrows': {
          'items': {
            'enum': [
              'variant01',
              'variant02',
              'variant03',
              'variant04',
              'variant05',
              'variant06'
            ]
          }
        },
        'mouth': {
          'items': {
            'enum': [
              'variant01',
              'variant02',
              'variant03',
              'variant04',
              'variant05',
              'variant06'
            ]
          }
        },
        'glasses': {
          'items': {
            'enum': ['variant01', 'variant02', 'variant03']
          }
        },
        'earrings': {
          'items': {
            'enum': ['variant01', 'variant02', 'variant03']
          }
        },
        'features': {
          'items': {
            'enum': ['freckles']
          }
        }
      }
    };

    Future<void> ensurePrefetchForTab({
      required BuildContext context,
      required int index,
      required String baseUrl,
      required Map<String, dynamic> base,
      required List<String> hairItems,
      required List<String> eyesItems,
      required List<String> eyebrowsItems,
      required List<String> mouthItems,
      required List<String> glassesItems,
      required List<String> earringsItems,
      required List<String> featuresItems,
    }) async {
      if (!_prefetchedTabs.add(index)) return;

      switch (index) {
        case 0:
          await prefetchThumbs(
            context: context,
            itemsWithOff: hairItems.cast<String?>(),
            urlBuilder: (item) => buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: base,
              overrideOptions: {'hair': item!},
              size: 96,
            ),
          );
          break;
        case 1:
          await prefetchThumbs(
            context: context,
            itemsWithOff: eyesItems.cast<String?>(),
            urlBuilder: (item) => buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: base,
              overrideOptions: {'eyes': item!},
              size: 96,
            ),
          );
          break;
        case 2:
          await prefetchThumbs(
            context: context,
            itemsWithOff: eyebrowsItems.cast<String?>(),
            urlBuilder: (item) => buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: base,
              overrideOptions: {'eyebrows': item!},
              size: 96,
            ),
          );
          break;
        case 3:
          await prefetchThumbs(
            context: context,
            itemsWithOff: mouthItems.cast<String?>(),
            urlBuilder: (item) => buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: base,
              overrideOptions: {'mouth': item!},
              size: 96,
            ),
          );
          break;
        case 4:
          await prefetchThumbs(
            context: context,
            itemsWithOff: <String?>[
              null,
              ...glassesItems,
              ...earringsItems,
              ...featuresItems,
            ],
            urlBuilder: (item) {
              final v = item!;
              if (glassesItems.contains(v)) {
                return buildAdventurerThumbUrl(
                  baseUrl: baseUrl,
                  baseOptions: base,
                  overrideOptions: {'glasses': v},
                  size: 96,
                );
              }
              if (earringsItems.contains(v)) {
                return buildAdventurerThumbUrl(
                  baseUrl: baseUrl,
                  baseOptions: base,
                  overrideOptions: {'earrings': v},
                  size: 96,
                );
              }
              return buildAdventurerThumbUrl(
                baseUrl: baseUrl,
                baseOptions: base,
                overrideOptions: {'features': v},
                size: 96,
              );
            },
          );
          break;
        default:
          break;
      }
    }

    Widget buildWithSchema(Map<String, dynamic> schema) {
      final hairItems = sortVariants(enumList(schema, 'hair'));
      final eyesItems = sortVariants(enumList(schema, 'eyes'));
      final eyebrowsItems = sortVariants(enumList(schema, 'eyebrows'));
      final mouthItems = sortVariants(enumList(schema, 'mouth'));
      final glassesItems = sortVariants(enumList(schema, 'glasses'));
      final earringsItems = sortVariants(enumList(schema, 'earrings'));
      final featuresItems = enumList(schema, 'features');

      final schemaBackgroundColors = defaultList(schema, 'backgroundColor');
      final schemaSkinColors = defaultList(schema, 'skinColor');
      final schemaHairColors = defaultList(schema, 'hairColor');

      final backgroundColors = schemaBackgroundColors.isNotEmpty
          ? schemaBackgroundColors
          : const ['b6e3f4', 'c0aede', 'd1d4f9', 'ffd5dc', 'ffdfbf'];

      if (schemaBackgroundColors.isEmpty) {
        debugPrint(
          '[avatar] schema has no backgroundColor enum -> using fallback palette',
        );
      }

      final skinColors = schemaSkinColors.isNotEmpty
          ? schemaSkinColors
          : const ['9e5622', '763900', 'ecad80', 'f2d3b1'];

      final hairColors = schemaHairColors.isNotEmpty
          ? schemaHairColors
          : const ['0e0e0e', '6a4e35', 'afafaf', 'cb6820', 'dba3be', 'e5d7a3'];

      // Base URL for backend proxy. Derive from the big preview URL.
      final baseUrl = Uri.parse(imageUrl).origin;

      // Frozen per-tab thumbnail base options.
      final optionsQuery = options.toQuery();

      final pages = <Widget>[
        _HairTab(
          items: hairItems,
          selected: options.hair,
          onSelect: controller.setHair,
          baseUrl: baseUrl,
          baseOptions: _tabBaseOptions[0] ?? optionsQuery,
        ),
        _EyesTab(
          items: eyesItems,
          selected: options.eyes,
          onSelect: controller.setEyes,
          baseUrl: baseUrl,
          baseOptions: _tabBaseOptions[1] ?? optionsQuery,
        ),
        _EyebrowsTab(
          variants: eyebrowsItems,
          selected: options.eyebrows,
          onSelect: controller.setEyebrows,
          baseUrl: baseUrl,
          baseOptions: _tabBaseOptions[2] ?? optionsQuery,
        ),
        _MouthTab(
          items: mouthItems,
          selected: options.mouth,
          onSelect: controller.setMouth,
          baseUrl: baseUrl,
          baseOptions: _tabBaseOptions[3] ?? optionsQuery,
        ),
        _ExtrasTab(
          glassesItems: glassesItems,
          earringsItems: earringsItems,
          featuresItems: featuresItems,
          optionsQuery: _tabBaseOptions[4] ?? optionsQuery,
          baseUrl: baseUrl,
          selectedGlasses: options.glasses,
          selectedEarrings: options.earrings,
          selectedFeatures: options.features,
          glassesProbability: options.glassesProbability,
          earringsProbability: options.earringsProbability,
          featuresProbability: options.featuresProbability,
          onSelectGlasses: controller.setGlasses,
          onSelectEarrings: controller.setEarrings,
          onSelectFeatures: controller.setFeatures,
        ),
        _ColorsTab(
          backgroundColors: backgroundColors,
          skinColors: skinColors,
          hairColors: hairColors,
          selectedBackground: options.backgroundColor,
          selectedSkin: options.skinColor,
          selectedHair: options.hairColor,
          onSelectBackground: controller.setBackgroundColor,
          onSelectSkin: controller.setSkinColor,
          onSelectHair: controller.setHairColor,
        ),
      ];

      final safeIndex = _tabIndex.clamp(0, pages.length - 1);

      // Ensure snapshot + prefetch for initial tab.
      _tabBaseOptions.putIfAbsent(safeIndex, () => Map<String, dynamic>.from(optionsQuery));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final base = _tabBaseOptions[safeIndex] ?? optionsQuery;
        ensurePrefetchForTab(
          context: context,
          index: safeIndex,
          baseUrl: baseUrl,
          base: base,
          hairItems: hairItems,
          eyesItems: eyesItems,
          eyebrowsItems: eyebrowsItems,
          mouthItems: mouthItems,
          glassesItems: glassesItems,
          earringsItems: earringsItems,
          featuresItems: featuresItems,
        );
      });

      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final orientation = MediaQuery.orientationOf(context);
            debugPrint('[Avatar] constraints=$constraints orientation=$orientation');

            const tabBarHeight = 48.0;
            const topPad = 12.0;
            const betweenPreviewAndTabs = 10.0;
            const betweenTabsAndContent = 8.0;

            // Keep controller in sync if some other part ever mutates _tabIndex.
            if (_tabController.index != safeIndex) {
              _tabController.index = safeIndex;
            }

            Widget tabBar() {
              final cs = Theme.of(context).colorScheme;
              final selected = cs.primary;
              final unselected = cs.onSurface.withOpacity(0.65);

              final tabs = [
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/hair.svg')),
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/eyes.svg')),
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/eyebrows.svg')),
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/mouth.svg')),
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/extras.svg')),
                Tab(icon: AvatarTabSvgIcon('assets/icons/avatar_tabs/colors.svg')),
              ];

              return Container(
                height: tabBarHeight,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  // Use a clearly visible surface tint across themes.
                  color: Color.alphaBlend(
                    cs.primary.withValues(alpha: 0.10),
                    cs.surface,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.10),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    // Rounded underline indicator (DiceBear-like)
                    indicator: UnderlineTabIndicator(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        width: 3,
                        color: cs.primary,
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    labelColor: selected,
                    unselectedLabelColor: unselected,
                    splashBorderRadius: BorderRadius.circular(999),
                    overlayColor: WidgetStateProperty.all(
                      cs.primary.withValues(alpha: 0.08),
                    ),
                    tabs: tabs,
                    onTap: (index) {
                    setState(() {
                      _tabIndex = index;
                    });

                    _tabBaseOptions.putIfAbsent(
                      index,
                      () => Map<String, dynamic>.from(optionsQuery),
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final base = _tabBaseOptions[index] ?? optionsQuery;
                      ensurePrefetchForTab(
                        context: context,
                        index: index,
                        baseUrl: baseUrl,
                        base: base,
                        hairItems: hairItems,
                        eyesItems: eyesItems,
                        eyebrowsItems: eyebrowsItems,
                        mouthItems: mouthItems,
                        glassesItems: glassesItems,
                        earringsItems: earringsItems,
                        featuresItems: featuresItems,
                      );
                    });
                  },
                  ),
                ),
              );
            }

            Widget content() {
              return Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: pages,
                ),
              );
            }

            if (orientation == Orientation.landscape) {
              final availableH = constraints.maxHeight;
              final previewSize = (availableH - topPad).clamp(140.0, 260.0);

              return Padding(
                padding: const EdgeInsets.only(top: topPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: bigPreview(size: previewSize),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          tabBar(),
                          const SizedBox(height: betweenTabsAndContent),
                          content(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Portrait
            final availableH = constraints.maxHeight;
            final reserved =
                topPad + betweenPreviewAndTabs + tabBarHeight + betweenTabsAndContent;
            final previewSize = (availableH - reserved).clamp(140.0, 220.0);

            return Column(
              children: [
                const SizedBox(height: topPad),
                Center(child: bigPreview(size: previewSize)),
                const SizedBox(height: betweenPreviewAndTabs),
                tabBar(),
                const SizedBox(height: betweenTabsAndContent),
                content(),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar'),
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            // /avatar/setup is an onboarding hard-gate: there is nowhere "back" to go.
            // Keep button responsive by giving a consistent deterministic destination.
            final loc = GoRouterState.of(context).matchedLocation;

            if (context.canPop()) {
              context.pop();
              return;
            }

            // If we are in setup -> send to church (previous onboarding step).
            if (loc == AppRoutes.avatarSetup) {
              context.go(AppRoutes.church);
              return;
            }

            // Otherwise (editing avatar from inside the app), go back to profile.
            context.go(AppRoutes.profile);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final options = ref.read(avatarOptionsProvider);
                  final repo = ref.read(authRepositoryProvider);

                  final user = await repo.saveAvatarConfig(options.toQuery());

                  // Preserve profile fields (firstName/lastName/etc.) even if backend
                  // returns a partial user for /me/avatar.
                  final prev = ref.read(currentUserProvider).valueOrNull;
                  final merged = prev == null
                      ? user
                      : UserModel(
                          id: user.id,
                          firstName: user.firstName.isNotEmpty
                              ? user.firstName
                              : prev.firstName,
                          lastName: user.lastName.isNotEmpty
                              ? user.lastName
                              : prev.lastName,
                          age: user.age != 0 ? user.age : prev.age,
                          city: user.city.isNotEmpty ? user.city : prev.city,
                          email: user.email.isNotEmpty ? user.email : prev.email,
                          role: user.role.isNotEmpty ? user.role : prev.role,
                          status: user.status.isNotEmpty ? user.status : prev.status,
                          churchId: user.churchId ?? prev.churchId,
                          avatarConfig: user.avatarConfig,
                          avatarUpdatedAt: user.avatarUpdatedAt,
                        );

                  // Update in-memory user session so router/guards react immediately.
                  ref.read(currentUserProvider.notifier).setUser(merged);

                  // Force preview images to refetch.
                  ref.read(avatarPreviewBustProvider.notifier).state++;

                  if (!context.mounted) return;

                  // If user came from onboarding (/avatar/setup) -> send to tasks.
                  // If user edited avatar from within the app (/avatar) -> return to profile/settings flow.
                  final loc = GoRouterState.of(context).matchedLocation;
                  if (loc == AppRoutes.avatarSetup) {
                    context.go(AppRoutes.tasks);
                  } else {
                    context.go(AppRoutes.profile);
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Не удалось сохранить: $e')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
      body: schemaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('[AvatarCustomizeScreen] Schema load failed: $e');
          return buildWithSchema(fallbackSchema);
        },
        data: (schema) => buildWithSchema(schema),
      ),
    );
  }
}

class AvatarTabSvgIcon extends StatelessWidget {
  const AvatarTabSvgIcon(
    this.asset, {
    super.key,
    this.box = 44,
    this.icon = 20,
  });

  final String asset;
  final double box;
  final double icon;

  @override
  Widget build(BuildContext context) {
    // TabBar provides IconTheme which reflects labelColor/unselectedLabelColor.
    final color = IconTheme.of(context).color;

    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: SizedBox(
          width: icon,
          height: icon,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SvgPicture.asset(
              asset,
              width: icon,
              height: icon,
              colorFilter:
                  ColorFilter.mode(color ?? Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantGrid extends StatelessWidget {
  const _VariantGrid({
    required this.items,
    required this.selected,
    required this.thumbFor,
    required this.onTap,
    this.showLabels = true,
  });

  final List<String> items;
  final String? selected;
  final Uri Function(String item) thumbFor;
  final void Function(String item) onTap;

  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final thumbUrl = thumbFor(item);

        final isSelected = selected == item;
        final borderColor = Theme.of(context).colorScheme.primary;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(item),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: borderColor, width: 2)
                  : BorderSide(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: AvatarThumbImage(
                      url: thumbUrl,
                      fit: BoxFit.contain,
                      cacheWidth: 96,
                    ),
                  ),
                  if (showLabels) const SizedBox(height: 6),
                  if (showLabels)
                    Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HairTab extends StatelessWidget {
  const _HairTab({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.baseUrl,
    required this.baseOptions,
  });

  final List<String> items;
  final String? selected;
  final void Function(String) onSelect;

  final String baseUrl;
  final Map<String, dynamic> baseOptions;

  @override
  Widget build(BuildContext context) {
    return _VariantGrid(
      items: items,
      selected: selected,
      thumbFor: (v) => buildAdventurerThumbUrl(
        baseUrl: baseUrl,
        baseOptions: baseOptions,
        overrideOptions: {'hair': v},
        size: 96,
      ),
      onTap: onSelect,
      showLabels: false,
    );
  }
}

class _EyesTab extends StatelessWidget {
  const _EyesTab({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.baseUrl,
    required this.baseOptions,
  });

  final List<String> items;
  final String? selected;
  final void Function(String) onSelect;

  final String baseUrl;
  final Map<String, dynamic> baseOptions;

  @override
  Widget build(BuildContext context) {
    return _VariantGrid(
      items: items,
      selected: selected,
      thumbFor: (v) => buildAdventurerThumbUrl(
        baseUrl: baseUrl,
        baseOptions: baseOptions,
        overrideOptions: {'eyes': v},
        size: 96,
      ),
      onTap: onSelect,
      showLabels: false,
    );
  }
}

class _MouthTab extends StatelessWidget {
  const _MouthTab({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.baseUrl,
    required this.baseOptions,
  });

  final List<String> items;
  final String? selected;
  final void Function(String) onSelect;

  final String baseUrl;
  final Map<String, dynamic> baseOptions;

  @override
  Widget build(BuildContext context) {
    return _VariantGrid(
      items: items,
      selected: selected,
      thumbFor: (v) => buildAdventurerThumbUrl(
        baseUrl: baseUrl,
        baseOptions: baseOptions,
        overrideOptions: {'mouth': v},
        size: 96,
      ),
      onTap: onSelect,
      showLabels: false,
    );
  }
}

class _EyebrowsTab extends StatelessWidget {
  const _EyebrowsTab({
    required this.variants,
    required this.selected,
    required this.onSelect,
    required this.baseUrl,
    required this.baseOptions,
  });

  final List<String> variants;
  final String? selected;
  final void Function(String) onSelect;

  final String baseUrl;
  final Map<String, dynamic> baseOptions;

  @override
  Widget build(BuildContext context) {
    return _VariantGrid(
      items: variants,
      selected: selected,
      thumbFor: (v) => buildAdventurerThumbUrl(
        baseUrl: baseUrl,
        baseOptions: baseOptions,
        overrideOptions: {'eyebrows': v},
        size: 96,
      ),
      onTap: onSelect,
      showLabels: false,
    );
  }
}

class _ExtrasTab extends StatelessWidget {
  const _ExtrasTab({
    required this.glassesItems,
    required this.earringsItems,
    required this.featuresItems,
    required this.optionsQuery,
    required this.baseUrl,
    required this.selectedGlasses,
    required this.selectedEarrings,
    required this.selectedFeatures,
    required this.glassesProbability,
    required this.earringsProbability,
    required this.featuresProbability,
    required this.onSelectGlasses,
    required this.onSelectEarrings,
    required this.onSelectFeatures,
  });

  final List<String> glassesItems;
  final List<String> earringsItems;
  final List<String> featuresItems;

  final Map<String, dynamic> optionsQuery;
  final String baseUrl;

  final String? selectedGlasses;
  final String? selectedEarrings;
  final String? selectedFeatures;

  final int? glassesProbability;
  final int? earringsProbability;
  final int? featuresProbability;

  final void Function(String?) onSelectGlasses;
  final void Function(String?) onSelectEarrings;
  final void Function(String?) onSelectFeatures;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ExtrasGridSection(
          title: 'Glasses',
          itemsWithOff: <String?>[null, ...glassesItems],
          isSelected: (item) {
            if (item == null) return (glassesProbability ?? 0) == 0;
            return (glassesProbability ?? 0) != 0 && selectedGlasses == item;
          },
          urlFor: (item) {
            if (item == null) {
              return buildAdventurerThumbUrl(
                baseUrl: baseUrl,
                baseOptions: optionsQuery,
                overrideOptions: const {'glassesProbability': 0},
                size: 96,
              );
            }
            return buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: optionsQuery,
              overrideOptions: {
                'glasses': item,
                'glassesProbability': 100,
              },
              size: 96,
            );
          },
          onTap: onSelectGlasses,
        ),
        const SizedBox(height: 16),
        _ExtrasGridSection(
          title: 'Earrings',
          itemsWithOff: <String?>[null, ...earringsItems],
          isSelected: (item) {
            if (item == null) return (earringsProbability ?? 0) == 0;
            return (earringsProbability ?? 0) != 0 && selectedEarrings == item;
          },
          urlFor: (item) {
            if (item == null) {
              return buildAdventurerThumbUrl(
                baseUrl: baseUrl,
                baseOptions: optionsQuery,
                overrideOptions: const {'earringsProbability': 0},
                size: 96,
              );
            }
            return buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: optionsQuery,
              overrideOptions: {
                'earrings': item,
                'earringsProbability': 100,
              },
              size: 96,
            );
          },
          onTap: onSelectEarrings,
        ),
        const SizedBox(height: 16),
        _ExtrasGridSection(
          title: 'Features',
          itemsWithOff: <String?>[null, ...featuresItems],
          isSelected: (item) {
            if (item == null) return (featuresProbability ?? 0) == 0;
            return (featuresProbability ?? 0) != 0 && selectedFeatures == item;
          },
          urlFor: (item) {
            if (item == null) {
              return buildAdventurerThumbUrl(
                baseUrl: baseUrl,
                baseOptions: optionsQuery,
                overrideOptions: const {'featuresProbability': 0},
                size: 96,
              );
            }
            return buildAdventurerThumbUrl(
              baseUrl: baseUrl,
              baseOptions: optionsQuery,
              overrideOptions: {
                'features': item,
                'featuresProbability': 100,
              },
              size: 96,
            );
          },
          onTap: onSelectFeatures,
        ),
      ],
    );
  }
}

class _ExtrasGridSection extends StatelessWidget {
  const _ExtrasGridSection({
    required this.title,
    required this.itemsWithOff,
    required this.urlFor,
    required this.onTap,
    required this.isSelected,
  });

  final String title;
  final List<String?> itemsWithOff;
  final Uri Function(String? item) urlFor;
  final void Function(String? item) onTap;
  final bool Function(String? item) isSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: itemsWithOff.length,
          itemBuilder: (context, index) {
            final item = itemsWithOff[index];
            final selected = isSelected(item);
            final url = urlFor(item);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(item),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: selected
                      ? BorderSide(color: borderColor, width: 2)
                      : BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AvatarThumbImage(
                    url: url,
                    fit: BoxFit.contain,
                    cacheWidth: 96,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorsTab extends StatelessWidget {
  const _ColorsTab({
    required this.backgroundColors,
    required this.skinColors,
    required this.hairColors,
    required this.selectedBackground,
    required this.selectedSkin,
    required this.selectedHair,
    required this.onSelectBackground,
    required this.onSelectSkin,
    required this.onSelectHair,
  });

  final List<String> backgroundColors;
  final List<String> skinColors;
  final List<String> hairColors;

  final String? selectedBackground;
  final String? selectedSkin;
  final String? selectedHair;

  final void Function(String hex) onSelectBackground;
  final void Function(String hex) onSelectSkin;
  final void Function(String hex) onSelectHair;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ColorSection(
          title: 'Background color',
          colors: backgroundColors,
          selected: selectedBackground,
          onTap: onSelectBackground,
        ),
        const SizedBox(height: 16),
        _ColorSection(
          title: 'Skin color',
          colors: skinColors,
          selected: selectedSkin,
          onTap: onSelectSkin,
        ),
        const SizedBox(height: 16),
        _ColorSection(
          title: 'Hair color',
          colors: hairColors,
          selected: selectedHair,
          onTap: onSelectHair,
        ),
      ],
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.title,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final List<String> colors;
  final String? selected;
  final void Function(String hex) onTap;

  Color _toColor(String hex) {
    final value = int.tryParse(hex, radix: 16) ?? 0;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final hex in colors)
              InkWell(
                onTap: () => onTap(hex),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _toColor(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == hex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black.withValues(alpha: 0.15),
                      width: selected == hex ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
