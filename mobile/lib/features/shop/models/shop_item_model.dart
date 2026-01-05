class ShopItemModel {
  const ShopItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.pricePoints,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String type;
  final int pricePoints;
  final bool isActive;
  final DateTime createdAt;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      pricePoints: (json['pricePoints'] is num)
          ? (json['pricePoints'] as num).toInt()
          : int.tryParse((json['pricePoints'] ?? '0').toString()) ?? 0,
      isActive: json['isActive'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
