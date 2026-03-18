class MilestoneLog {
  final String id;
  final String milestone;
  final String createdAt;
  final String? note;

  const MilestoneLog({
    required this.id,
    required this.milestone,
    required this.createdAt,
    this.note,
  });

  factory MilestoneLog.fromJson(Map<String, dynamic> json) => MilestoneLog(
        id: json['id']?.toString() ?? '',
        milestone: json['milestone']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        note: json['note']?.toString(),
      );

  String get formattedMilestone {
    return milestone
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class JobModel {
  final String id;
  final String status;
  final String createdAt;
  final String? moveType;
  final String? originAddress;
  final String? destinationAddress;
  final String? scheduledPacking;
  final String? scheduledPickup;
  final String? scheduledDelivery;
  final List<MilestoneLog> milestoneLogs;

  const JobModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.moveType,
    this.originAddress,
    this.destinationAddress,
    this.scheduledPacking,
    this.scheduledPickup,
    this.scheduledDelivery,
    required this.milestoneLogs,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final logsRaw = json['milestone_logs'] as List<dynamic>? ?? [];
    return JobModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      moveType: json['move_type']?.toString(),
      originAddress: json['origin_address']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      scheduledPacking: json['scheduled_packing']?.toString(),
      scheduledPickup: json['scheduled_pickup']?.toString(),
      scheduledDelivery: json['scheduled_delivery']?.toString(),
      milestoneLogs: logsRaw
          .map((e) => MilestoneLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isActive =>
      !['completed', 'cancelled', 'delivered'].contains(status.toLowerCase());
}

// Ordered list of all 12 milestones for timeline display
const kAllMilestones = [
  'lead_created',
  'survey_scheduled',
  'survey_completed',
  'quote_sent',
  'quote_approved',
  'booking_confirmed',
  'packing_started',
  'packing_completed',
  'pickup_started',
  'in_transit',
  'delivery_started',
  'delivered',
];
