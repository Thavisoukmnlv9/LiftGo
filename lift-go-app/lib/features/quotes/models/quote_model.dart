class QuoteLineItem {
  final String id;
  final String description;
  final String itemType;
  final int quantity;
  final double? unitPrice;
  final double? total;

  const QuoteLineItem({
    required this.id,
    required this.description,
    required this.itemType,
    required this.quantity,
    this.unitPrice,
    this.total,
  });

  factory QuoteLineItem.fromJson(Map<String, dynamic> json) => QuoteLineItem(
        id: json['id']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        itemType: json['item_type']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
        total: (json['total'] as num?)?.toDouble(),
      );
}

class QuoteModel {
  final String id;
  final String status;
  final String currency;
  final int version;
  final double? totalAmount;
  final List<QuoteLineItem> lineItems;
  final String? notes;
  final String? insuranceOption;
  final String? storageOption;
  final String? validUntil;
  final String? sentAt;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;

  const QuoteModel({
    required this.id,
    required this.status,
    required this.currency,
    required this.version,
    this.totalAmount,
    required this.lineItems,
    this.notes,
    this.insuranceOption,
    this.storageOption,
    this.validUntil,
    this.sentAt,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    final lineItemsRaw = json['line_items'] as List<dynamic>? ?? [];
    return QuoteModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      currency: json['currency']?.toString() ?? 'USD',
      version: (json['version'] as num?)?.toInt() ?? 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      lineItems: lineItemsRaw
          .map((e) => QuoteLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes']?.toString(),
      insuranceOption: json['insurance_option']?.toString(),
      storageOption: json['storage_option']?.toString(),
      validUntil: json['valid_until']?.toString(),
      sentAt: json['sent_at']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
