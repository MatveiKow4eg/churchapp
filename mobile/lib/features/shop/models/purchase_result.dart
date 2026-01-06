import '../../inventory/models/server_inventory_item.dart';

class PurchaseResult {
  const PurchaseResult({
    required this.itemKey,
    required this.pricePoints,
    required this.balance,
    required this.inventory,
  });

  final String itemKey;
  final int pricePoints;
  final int balance;
  final ServerInventoryItem inventory;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    final rawInv = json['inventory'];

    return PurchaseResult(
      itemKey: (json['itemKey'] ?? '').toString(),
      pricePoints: (json['pricePoints'] is num)
          ? (json['pricePoints'] as num).toInt()
          : int.tryParse((json['pricePoints'] ?? '0').toString()) ?? 0,
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toInt()
          : int.tryParse((json['balance'] ?? '0').toString()) ?? 0,
      inventory: rawInv is Map
          ? ServerInventoryItem.fromJson(Map<String, dynamic>.from(rawInv))
          : ServerInventoryItem(
              id: '',
              itemKey: '',
              acquiredAt: DateTime.fromMillisecondsSinceEpoch(0),
              quantity: 0,
            ),
    );
  }
}
