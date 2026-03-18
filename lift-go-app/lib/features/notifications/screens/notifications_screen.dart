import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notifications_repository.dart';
import '../models/notification_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';

final _notificationsProvider =
    StateNotifierProvider<_NotificationsNotifier, AsyncValue<List<NotificationModel>>>(
  (ref) => _NotificationsNotifier(ref.read(notificationsRepositoryProvider)),
);

class _NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationsRepository _repo;

  _NotificationsNotifier(this._repo) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      final items = await _repo.getNotifications();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    state = state.whenData((items) =>
        items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList());
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    state = state.whenData(
        (items) => items.map((n) => n.copyWith(isRead: true)).toList());
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(_notificationsProvider.notifier)
                    .markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All notifications marked as read')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () =>
              ref.read(_notificationsProvider.notifier).refresh(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(_notificationsProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationTile(
                notification: notifications[i],
                onTap: () async {
                  if (!notifications[i].isRead) {
                    await ref
                        .read(_notificationsProvider.notifier)
                        .markRead(notifications[i].id);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRead = notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : colorScheme.primaryContainer.withOpacity(0.15),
          border: isRead
              ? null
              : Border(
                  left: BorderSide(color: colorScheme.primary, width: 3),
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer,
              ),
              child: Icon(
                _iconForType(notification.type),
                size: 20,
                color: isRead ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'job_update':
      case 'job':
        return Icons.local_shipping_outlined;
      case 'invoice':
      case 'payment':
        return Icons.receipt_outlined;
      case 'quote':
        return Icons.request_quote_outlined;
      case 'support':
      case 'ticket':
        return Icons.support_agent_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inDays > 30) return '${(diff.inDays / 30).round()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
