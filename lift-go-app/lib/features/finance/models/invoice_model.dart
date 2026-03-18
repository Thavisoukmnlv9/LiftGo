class PaymentRecord {
  final String id;
  final String paymentMethod;
  final String paidAt;
  final double amount;
  final String? reference;

  const PaymentRecord({
    required this.id,
    required this.paymentMethod,
    required this.paidAt,
    required this.amount,
    this.reference,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id']?.toString() ?? '',
        paymentMethod: json['payment_method']?.toString() ?? '',
        paidAt: json['paid_at']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        reference: json['reference']?.toString(),
      );
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String status;
  final String currency;
  final String createdAt;
  final double amount;
  final double depositAmount;
  final double paidAmount;
  final List<PaymentRecord> payments;
  final String? dueDate;
  final String? notes;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.createdAt,
    required this.amount,
    required this.depositAmount,
    required this.paidAmount,
    required this.payments,
    this.dueDate,
    this.notes,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final paymentsRaw = json['payments'] as List<dynamic>? ?? [];
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unpaid',
      currency: json['currency']?.toString() ?? 'USD',
      createdAt: json['created_at']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      payments: paymentsRaw
          .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      dueDate: json['due_date']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  double get balance => amount - paidAmount;

  double get paymentProgress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
}
