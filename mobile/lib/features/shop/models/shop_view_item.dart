class ShopViewItem {
  const ShopViewItem({
    required this.key,
    required this.name,
    required this.iconPath,
    required this.layerPath,
    required this.slot,
    required this.rarity,
    required this.pricePoints,
    required this.isActive,
    required this.owned,
  });

  final String key;
  final String name;
  final String iconPath;
  final String layerPath;
  final String slot;
  final String rarity;

  final int pricePoints;
  final bool isActive;
  final bool owned;
}
