class ClaimModel {
  final String id;
  final String jobId;
  final String claimType;
  final String status;
  final String description;
  final double? amount;
  final String createdAt;

  const ClaimModel({
    required this.id,
    required this.jobId,
    required this.claimType,
    required this.status,
    required this.description,
    this.amount,
    required this.createdAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) => ClaimModel(
        id: json['id']?.toString() ?? '',
        jobId: json['job_id']?.toString() ?? '',
        claimType: json['claim_type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        description: json['description']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}
