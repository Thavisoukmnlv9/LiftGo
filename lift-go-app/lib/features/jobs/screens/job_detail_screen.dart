import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../repositories/jobs_repository.dart';
import '../models/job_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/status_badge.dart';

final _jobDetailProvider =
    FutureProvider.family<JobModel, String>((ref, id) async {
  return ref.read(jobsRepositoryProvider).getJob(id);
});

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(_jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Job #${jobId.length > 8 ? jobId.substring(0, 8) : jobId}…',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
      body: jobAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () => ref.invalidate(_jobDetailProvider(jobId)),
        ),
        data: (job) => _JobDetailBody(job: job),
      ),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  final JobModel job;
  const _JobDetailBody({required this.job});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status
          Row(
            children: [
              StatusBadge(status: job.status, fontSize: 13),
              if (job.moveType != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(job.moveType!.replaceAll('_', ' ')),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Addresses
          if (job.originAddress != null || job.destinationAddress != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.originAddress ?? '—',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: colorScheme.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.destinationAddress ?? '—',
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Schedule tiles
          Row(
            children: [
              Expanded(
                child: _ScheduleTile(
                  label: 'Packing',
                  icon: Icons.inventory_2_outlined,
                  date: job.scheduledPacking,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScheduleTile(
                  label: 'Pickup',
                  icon: Icons.local_shipping_outlined,
                  date: job.scheduledPickup,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScheduleTile(
                  label: 'Delivery',
                  icon: Icons.home_outlined,
                  date: job.scheduledDelivery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Milestones timeline
          Text(
            'Move Timeline',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _MilestoneTimeline(job: job),
          const SizedBox(height: 24),

          // Quick links
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/jobs/${job.id}/inventory'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Inventory'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/invoices'),
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text('Invoices'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contact coordinator button
          ElevatedButton.icon(
            onPressed: () => _showContactOptions(context),
            icon: const Icon(Icons.headset_mic_outlined),
            label: const Text('Contact Coordinator'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Contact Coordinator',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Call Us'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Us'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Open Support Ticket'),
              onTap: () {
                Navigator.pop(context);
                context.go('/support');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? date;

  const _ScheduleTile({
    required this.label,
    required this.icon,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dt = DateTime.tryParse(date ?? '');
    final formatted = dt != null ? DateFormat('dd MMM').format(dt) : '—';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            formatted,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MilestoneTimeline extends StatelessWidget {
  final JobModel job;
  const _MilestoneTimeline({required this.job});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedMilestones =
        job.milestoneLogs.map((m) => m.milestone).toSet();

    // Build a map from milestone name → log for detail
    final logMap = {for (final log in job.milestoneLogs) log.milestone: log};

    return Column(
      children: kAllMilestones.asMap().entries.map((entry) {
        final idx = entry.key;
        final milestone = entry.value;
        final isCompleted = completedMilestones.contains(milestone);
        final log = logMap[milestone];
        final isLast = idx == kAllMilestones.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: isCompleted
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? colorScheme.primary.withOpacity(0.4)
                              : colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMilestone(milestone),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isCompleted
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (log != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(log.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        if (log.note != null && log.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            log.note!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatMilestone(String m) {
    return m
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }
}
