import '../../shop/models/shop_item_model.dart';

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.acquiredAt,
    required this.item,
  });

  final String id;
  final String itemId;
  final int quantity;
  final DateTime acquiredAt;
  final ShopItemModel item;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];

    return InventoryItemModel(
      id: (json['id'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
      acquiredAt: DateTime.tryParse((json['acquiredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      item: rawItem is Map
          ? ShopItemModel.fromJson(Map<String, dynamic>.from(rawItem))
          : ShopItemModel.fromJson(const <String, dynamic>{}),
    );
  }
}
