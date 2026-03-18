import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  static _BadgeStyle _styleForStatus(String status) {
    final lower = status.toLowerCase();

    // Green
    if ([
      'completed',
      'paid',
      'resolved',
      'won',
      'approved',
      'delivered',
    ].contains(lower)) {
      return _BadgeStyle(
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF166534),
      );
    }

    // Blue
    if (['new', 'scheduled', 'pending', 'sent', 'open'].contains(lower)) {
      return _BadgeStyle(
        bg: const Color(0xFFDBEAFE),
        fg: const Color(0xFF1E40AF),
      );
    }

    // Amber
    if ([
      'in_transit',
      'partial',
      'in_progress',
      'active',
      'processing',
    ].contains(lower)) {
      return _BadgeStyle(
        bg: const Color(0xFFFEF9C3),
        fg: const Color(0xFF92400E),
      );
    }

    // Red
    if ([
      'cancelled',
      'lost',
      'rejected',
      'overdue',
      'unpaid',
      'failed',
    ].contains(lower)) {
      return _BadgeStyle(
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFF991B1B),
      );
    }

    // Grey (default: draft, open, unknown)
    return _BadgeStyle(
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF475569),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(status);
    final label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: style.fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  const _BadgeStyle({required this.bg, required this.fg});
}
