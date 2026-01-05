class CatalogItem {
  const CatalogItem({
    required this.key,
    required this.slot,
    required this.rarity,
    required this.price,
    required this.nameRu,
    required this.nameEn,
    required this.iconPath,
    required this.layerPath,
  });

  final String key;
  final String slot;
  final String rarity;
  final int price;
  final String nameRu;
  final String nameEn;
  final String iconPath;
  final String layerPath;

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final nameRaw = json['name'];
    String ru = '';
    String en = '';
    if (nameRaw is Map) {
      ru = (nameRaw['ru'] ?? '') as String;
      en = (nameRaw['en'] ?? '') as String;
    }

    final priceRaw = json['price'];
    final int price = switch (priceRaw) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    return CatalogItem(
      key: json['key']?.toString() ?? '',
      slot: (json['slot'] ?? '') as String,
      rarity: (json['rarity'] ?? '') as String,
      price: price,
      nameRu: ru,
      nameEn: en,
      iconPath: (json['iconPath'] ?? '') as String,
      layerPath: (json['layerPath'] ?? '') as String,
    );
  }

  String displayName({String locale = 'ru'}) {
    if (locale == 'ru') return nameRu.isNotEmpty ? nameRu : (nameEn.isNotEmpty ? nameEn : key);
    return nameEn.isNotEmpty ? nameEn : (nameRu.isNotEmpty ? nameRu : key);
  }
}
