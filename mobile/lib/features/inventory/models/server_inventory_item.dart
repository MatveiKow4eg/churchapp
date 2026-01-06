class ServerInventoryItem {
  const ServerInventoryItem({
    required this.id,
    required this.itemKey,
    required this.acquiredAt,
    required this.quantity,
  });

  final String id;
  final String itemKey;
  final DateTime acquiredAt;
  final int quantity;

  factory ServerInventoryItem.fromJson(Map<String, dynamic> json) {
    return ServerInventoryItem(
      id: (json['id'] ?? '').toString(),
      itemKey: (json['itemKey'] ?? '').toString(),
      acquiredAt: DateTime.tryParse((json['acquiredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
    );
  }
}
