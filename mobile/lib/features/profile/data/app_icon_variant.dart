/// Варианты иконок приложения
enum AppIconVariant {
  main('main', 'Основная', 'icon_main.png'),
  amber('amber', 'Янтарная', 'icon_amber.png'),
  darkCyan('dark_cyan', 'Темно-бирюзовая', 'icon_dark_cyan.png'),
  darkGold('dark_gold', 'Темно-золотая', 'icon_dark_gold.png'),
  darkPurple('dark_purple', 'Темно-фиолетовая', 'icon_dark_purple.png'),
  emerald('emerald', 'Изумрудная', 'icon_emerald.png'),
  indigo('indigo', 'Индиго', 'icon_indigo.png'),
  mono('mono', 'Монохромная', 'icon_mono.png'),
  pink('pink', 'Розовая', 'icon_pink.png'),
  red('red', 'Красная', 'icon_red.png'),
  sky('sky', 'Небесная', 'icon_sky.png');

  const AppIconVariant(this.id, this.label, this.assetPath);

  final String id;
  final String label;
  final String assetPath;

  /// Для iOS используются именованные варианты (например, "AppIcon-amber")
  String get iosIconName => this == main ? 'AppIcon' : 'AppIcon-$id';

  /// Для Android используются activity-alias (например, ".MainActivityAmber")
  String get androidActivityAlias {
    if (this == main) return '.MainActivity';

    // Преобразуем snake_case в PascalCase
    // amber -> Amber
    // dark_cyan -> DarkCyan
    final parts = id.split('_');
    final pascalCase = parts.map((part) => part[0].toUpperCase() + part.substring(1)).join('');
    return '.MainActivity$pascalCase';
  }

  static AppIconVariant fromId(String? id) {
    return values.firstWhere(
      (v) => v.id == id,
      orElse: () => main,
    );
  }
}
