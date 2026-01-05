class PurchaseResult {
  const PurchaseResult({
    required this.item,
    required this.balance,
    required this.inventory,
  });

  final PurchaseItem item;
  final int balance;
  final InventoryEntry inventory;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    final rawItem = json['item'];
    final rawInv = json['inventory'];

    return PurchaseResult(
      item: rawItem is Map
          ? PurchaseItem.fromJson(Map<String, dynamic>.from(rawItem))
          : const PurchaseItem(id: '', name: '', pricePoints: 0, type: ''),
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toInt()
          : int.tryParse((json['balance'] ?? '0').toString()) ?? 0,
      inventory: rawInv is Map
          ? InventoryEntry.fromJson(Map<String, dynamic>.from(rawInv))
          : InventoryEntry.empty(),
    );
  }
}

class PurchaseItem {
  const PurchaseItem({
    required this.id,
    required this.name,
    required this.pricePoints,
    required this.type,
  });

  final String id;
  final String name;
  final int pricePoints;
  final String type;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      pricePoints: (json['pricePoints'] is num)
          ? (json['pricePoints'] as num).toInt()
          : int.tryParse((json['pricePoints'] ?? '0').toString()) ?? 0,
      type: (json['type'] ?? '').toString(),
    );
  }
}

class InventoryEntry {
  const InventoryEntry({
    required this.id,
    required this.itemId,
    required this.acquiredAt,
    required this.quantity,
  });

  final String id;
  final String itemId;
  final DateTime acquiredAt;
  final int quantity;

  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    return InventoryEntry(
      id: (json['id'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      acquiredAt: DateTime.tryParse((json['acquiredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
    );
  }

  factory InventoryEntry.empty() => InventoryEntry(
        id: '',
        itemId: '',
        acquiredAt: DateTime.fromMillisecondsSinceEpoch(0),
        quantity: 0,
      );
}
