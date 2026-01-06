class ServerShopItem {
  const ServerShopItem({
    required this.itemKey,
    required this.pricePoints,
    required this.isActive,
  });

  final String itemKey;
  final int pricePoints;
  final bool isActive;

  factory ServerShopItem.fromJson(Map<String, dynamic> json) {
    return ServerShopItem(
      itemKey: (json['itemKey'] ?? '').toString(),
      pricePoints: (json['pricePoints'] is num)
          ? (json['pricePoints'] as num).toInt()
          : int.tryParse((json['pricePoints'] ?? '0').toString()) ?? 0,
      isActive: (json['isActive'] is bool)
          ? (json['isActive'] as bool)
          : (json['isActive']?.toString().toLowerCase() == 'true'),
    );
  }
}
