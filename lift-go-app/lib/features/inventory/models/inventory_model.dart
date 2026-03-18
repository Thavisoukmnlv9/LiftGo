class InventoryItem {
  final String id;
  final String name;
  final String packingStatus;
  final int quantity;
  final bool isFragile;
  final bool isHighValue;
  final String? conditionNotes;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.packingStatus,
    required this.quantity,
    required this.isFragile,
    required this.isHighValue,
    this.conditionNotes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        packingStatus: json['packing_status']?.toString() ?? 'pending',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        isFragile: json['is_fragile'] as bool? ?? false,
        isHighValue: json['is_high_value'] as bool? ?? false,
        conditionNotes: json['condition_notes']?.toString(),
      );
}

class InventoryRoom {
  final String id;
  final String roomName;
  final List<InventoryItem> items;

  const InventoryRoom({
    required this.id,
    required this.roomName,
    required this.items,
  });

  factory InventoryRoom.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    return InventoryRoom(
      id: json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? 'Room',
      items: itemsRaw
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
