import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/quotes_repository.dart';
import '../models/quote_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/info_row.dart';
import '../../../shared/widgets/section_header.dart';

final _quoteDetailProvider =
    FutureProvider.family<QuoteModel, String>((ref, id) async {
  return ref.read(quotesRepositoryProvider).getQuote(id);
});

class QuoteDetailScreen extends ConsumerWidget {
  final String quoteId;
  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(_quoteDetailProvider(quoteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quote Details')),
      body: quoteAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () => ref.invalidate(_quoteDetailProvider(quoteId)),
        ),
        data: (quote) => _QuoteDetailBody(
          quote: quote,
          onAccept: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Accept Quote'),
                content: const Text(
                    'Are you sure you want to accept this quote? This will confirm your move booking.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              try {
                await ref.read(quotesRepositoryProvider).acceptQuote(quoteId);
                ref.invalidate(_quoteDetailProvider(quoteId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quote accepted successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }
}

class _QuoteDetailBody extends StatelessWidget {
  final QuoteModel quote;
  final VoidCallback onAccept;

  const _QuoteDetailBody({required this.quote, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isApproved = quote.status.toLowerCase() == 'approved';
    final isSent = quote.status.toLowerCase() == 'sent';

    String? validUntilFormatted;
    final vd = DateTime.tryParse(quote.validUntil ?? '');
    if (vd != null) validUntilFormatted = DateFormat('dd MMM yyyy').format(vd);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Approved banner
          if (isApproved)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF166534)),
                  SizedBox(width: 8),
                  Text(
                    'Quote Approved',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: quote.status),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Version ${quote.version}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (quote.totalAmount != null) ...[
                    Text(
                      '${quote.currency} ${quote.totalAmount!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                    ),
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (validUntilFormatted != null)
                    InfoRow(label: 'Valid Until', value: validUntilFormatted),
                  if (quote.insuranceOption != null) ...[
                    const SizedBox(height: 4),
                    InfoRow(label: 'Insurance', value: quote.insuranceOption!),
                  ],
                  if (quote.storageOption != null) ...[
                    const SizedBox(height: 4),
                    InfoRow(label: 'Storage', value: quote.storageOption!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line items
          if (quote.lineItems.isNotEmpty) ...[
            const SectionHeader(title: 'Line Items'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ...quote.lineItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        if (idx > 0) const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    if (item.itemType.isNotEmpty)
                                      Text(
                                        item.itemType,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (item.unitPrice != null)
                                    Text(
                                      '${item.quantity} × ${item.unitPrice!.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (item.total != null)
                                    Text(
                                      item.total!.toStringAsFixed(2),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  if (quote.totalAmount != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${quote.currency} ${quote.totalAmount!.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (quote.notes != null && quote.notes!.isNotEmpty) ...[
            const SectionHeader(title: 'Notes'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(quote.notes!),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Accept button
          if (isSent) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
