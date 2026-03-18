import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/finance_repository.dart';
import '../models/invoice_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/info_row.dart';

final _invoiceDetailProvider =
    FutureProvider.family<InvoiceModel, String>((ref, id) async {
  return ref.read(financeRepositoryProvider).getInvoice(id);
});

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(_invoiceDetailProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: invoiceAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () => ref.invalidate(_invoiceDetailProvider(invoiceId)),
        ),
        data: (invoice) => _InvoiceDetailBody(invoice: invoice),
      ),
    );
  }
}

class _InvoiceDetailBody extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailBody({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String? dueDateFormatted;
    final dd = DateTime.tryParse(invoice.dueDate ?? '');
    if (dd != null) dueDateFormatted = DateFormat('dd MMM yyyy').format(dd);

    String? createdAtFormatted;
    final cd = DateTime.tryParse(invoice.createdAt);
    if (cd != null) createdAtFormatted = DateFormat('dd MMM yyyy').format(cd);

    Color statusColor;
    switch (invoice.status.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF059669);
        break;
      case 'partial':
        statusColor = const Color(0xFFD97706);
        break;
      default:
        statusColor = const Color(0xFFDC2626);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ),
                      StatusBadge(status: invoice.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amounts row
                  Row(
                    children: [
                      Expanded(
                        child: _AmountTile(
                          label: 'Total Amount',
                          amount:
                              '${invoice.currency} ${invoice.amount.toStringAsFixed(2)}',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: _AmountTile(
                          label: 'Amount Paid',
                          amount:
                              '${invoice.currency} ${invoice.paidAmount.toStringAsFixed(2)}',
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Expanded(
                        child: _AmountTile(
                          label: 'Balance',
                          amount:
                              '${invoice.currency} ${invoice.balance.toStringAsFixed(2)}',
                          color: invoice.balance > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: invoice.paymentProgress,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(invoice.paymentProgress * 100).round()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (dueDateFormatted != null)
                    InfoRow(label: 'Due Date', value: dueDateFormatted),
                  if (createdAtFormatted != null) ...[
                    const SizedBox(height: 4),
                    InfoRow(label: 'Issued On', value: createdAtFormatted),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payments
          if (invoice.payments.isNotEmpty) ...[
            const SectionHeader(title: 'Payment History'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: invoice.payments.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final payment = entry.value;
                  final dt = DateTime.tryParse(payment.paidAt);
                  final formatted = dt != null
                      ? DateFormat('dd MMM yyyy').format(dt)
                      : payment.paidAt;
                  return Column(
                    children: [
                      if (idx > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.payment_outlined,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.paymentMethod
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    formatted,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (payment.reference != null)
                                    Text(
                                      'Ref: ${payment.reference}',
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
                            Text(
                              '${invoice.currency} ${payment.amount.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SectionHeader(title: 'Notes'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(invoice.notes!),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AmountTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
