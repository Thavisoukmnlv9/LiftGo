import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/repositories/jobs_repository.dart';
import '../../jobs/models/job_model.dart';
import '../../notifications/repositories/notifications_repository.dart';
import '../../notifications/models/notification_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';

// ---------------------------------------------------------------------------
// Providers scoped for home screen
// ---------------------------------------------------------------------------

final _activeJobProvider = FutureProvider<JobModel?>((ref) async {
  final repo = ref.read(jobsRepositoryProvider);
  final result = await repo.getJobs(page: 1, limit: 5);
  if (result.isEmpty) return null;
  // Return first active job if available, otherwise first job
  try {
    return result.firstWhere(
      (j) => ![
        'completed',
        'cancelled',
        'delivered',
      ].contains(j.status.toLowerCase()),
    );
  } catch (_) {
    return result.first;
  }
});

final _recentNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final repo = ref.read(notificationsRepositoryProvider);
  return repo.getNotifications(page: 1, limit: 3);
});

// ---------------------------------------------------------------------------
// HomeTabBody
// ---------------------------------------------------------------------------

class HomeTabBody extends ConsumerWidget {
  const HomeTabBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeJobAsync = ref.watch(_activeJobProvider);
    final notificationsAsync = ref.watch(_recentNotificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${user?.firstName ?? 'there'}!',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_activeJobProvider);
          ref.invalidate(_recentNotificationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Move Card
              _ActiveMoveCard(activeJobAsync: activeJobAsync),
              const SizedBox(height: 20),

              // Quick Actions
              _QuickActionsGrid(),
              const SizedBox(height: 20),

              // Recent Notifications
              _RecentNotifications(notificationsAsync: notificationsAsync),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Move Card
// ---------------------------------------------------------------------------

class _ActiveMoveCard extends StatelessWidget {
  final AsyncValue<JobModel?> activeJobAsync;
  const _ActiveMoveCard({required this.activeJobAsync});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Move',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            activeJobAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => Text(
                'Could not load move status',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              data: (job) {
                if (job == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No active moves',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => context.push('/quote/new'),
                        child: const Text('Request a Quote'),
                      ),
                    ],
                  );
                }
                return _JobSummary(job: job);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JobSummary extends StatelessWidget {
  final JobModel job;
  const _JobSummary({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: job.status),
            const SizedBox(width: 8),
            if (job.moveType != null)
              Text(
                job.moveType!.replaceAll('_', ' ').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (job.originAddress != null || job.destinationAddress != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  job.originAddress ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: Text(
                  job.destinationAddress ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        // Progress indicator based on milestone logs
        if (job.milestoneLogs.isNotEmpty) ...[
          LinearProgressIndicator(
            value: _progressValue(job),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${job.milestoneLogs.length} milestones completed',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/jobs/${job.id}'),
            child: const Text('View Details'),
          ),
        ),
      ],
    );
  }

  double _progressValue(JobModel job) {
    const total = 12;
    return (job.milestoneLogs.length / total).clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Grid
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.request_quote_rounded,
        label: 'Get a Quote',
        color: const Color(0xFF2563EB),
        onTap: () => context.push('/quote/new'),
      ),
      _QuickAction(
        icon: Icons.local_shipping_rounded,
        label: 'Track My Move',
        color: const Color(0xFF059669),
        onTap: () => context.go('/jobs'),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'View Invoices',
        color: const Color(0xFFD97706),
        onTap: () => context.push('/invoices'),
      ),
      _QuickAction(
        icon: Icons.support_agent_rounded,
        label: 'Get Support',
        color: const Color(0xFF7C3AED),
        onTap: () => context.go('/support'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: actions.map((a) => _QuickActionCard(action: a)).toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(action.icon, color: action.color, size: 28),
            Text(
              action.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Notifications
// ---------------------------------------------------------------------------

class _RecentNotifications extends StatelessWidget {
  final AsyncValue<List<NotificationModel>> notificationsAsync;
  const _RecentNotifications({required this.notificationsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () => context.push('/notifications'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        notificationsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Text(
                'No recent notifications',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: notifications
                  .map((n) => _NotificationTile(notification: n))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? colorScheme.surfaceContainerLow
            : colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: notification.isRead
            ? null
            : Border(left: BorderSide(color: colorScheme.primary, width: 3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconForType(notification.type),
            size: 18,
            color: notification.isRead
                ? colorScheme.onSurfaceVariant
                : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(notification.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'job_update':
        return Icons.local_shipping_outlined;
      case 'invoice':
        return Icons.receipt_outlined;
      case 'quote':
        return Icons.request_quote_outlined;
      case 'support':
        return Icons.support_agent_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
