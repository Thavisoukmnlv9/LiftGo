import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/support_repository.dart';
import '../models/ticket_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/status_badge.dart';

final _ticketDetailProvider =
    FutureProvider.family<SupportTicket, String>((ref, id) async {
  return ref.read(supportRepositoryProvider).getTicket(id);
});

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String ticketId) async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref.read(supportRepositoryProvider).addMessage(ticketId, body);
      _replyController.clear();
      ref.invalidate(_ticketDetailProvider(ticketId));
      // Scroll to bottom after refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(_ticketDetailProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: ticketAsync.when(
          loading: () => const Text('Ticket'),
          error: (_, __) => const Text('Ticket'),
          data: (ticket) => Text(
            '#${ticket.id.length > 8 ? ticket.id.substring(0, 8) : ticket.id}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
        actions: [
          ticketAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (ticket) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StatusBadge(status: ticket.status),
            ),
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(_ticketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) => Column(
          children: [
            // Subject header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Text(
                ticket.subject,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Messages
            Expanded(
              child: ticket.messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Send the first one!',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: ticket.messages.length,
                      itemBuilder: (context, i) =>
                          _MessageBubble(message: ticket.messages[i]),
                    ),
            ),

            // Reply input
            _ReplyBar(
              controller: _replyController,
              isSending: _isSending,
              onSend: () => _sendMessage(ticket.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Staff messages on left (blue), customer on right (grey)
    final isStaff = message.isStaff;

    String? timeFormatted;
    final dt = DateTime.tryParse(message.createdAt);
    if (dt != null) {
      timeFormatted = DateFormat('dd MMM, HH:mm').format(dt.toLocal());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isStaff ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isStaff) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.support_agent, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isStaff
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isStaff ? 4 : 16),
                  bottomRight: Radius.circular(isStaff ? 16 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: isStaff
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    isStaff ? 'Support Team' : 'You',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isStaff
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (timeFormatted != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeFormatted,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isStaff) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a reply…',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
