import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/support_repository.dart';

class NewClaimScreen extends ConsumerStatefulWidget {
  const NewClaimScreen({super.key});

  @override
  ConsumerState<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends ConsumerState<NewClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _claimType = 'damage';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _jobIdController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final amountText = _amountController.text.trim();
      final amount = amountText.isNotEmpty ? double.tryParse(amountText) : null;

      await ref.read(supportRepositoryProvider).createClaim(
            jobId: _jobIdController.text.trim(),
            claimType: _claimType,
            description: _descriptionController.text.trim(),
            amount: amount,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted successfully!')),
        );
        context.pop();
      }
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Claim'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'File a Claim',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please provide as much detail as possible to help us process your claim quickly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 28),

                // Job ID
                TextFormField(
                  controller: _jobIdController,
                  decoration: const InputDecoration(
                    labelText: 'Job ID / Reference',
                    hintText: 'Enter your job reference number',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Job ID is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Claim Type
                DropdownButtonFormField<String>(
                  value: _claimType,
                  decoration: const InputDecoration(
                    labelText: 'Claim Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'damage',
                      child: Text('Damage'),
                    ),
                    DropdownMenuItem(
                      value: 'loss',
                      child: Text('Loss'),
                    ),
                    DropdownMenuItem(
                      value: 'complaint',
                      child: Text('Complaint'),
                    ),
                  ],
                  onChanged: (v) =>
                      v != null ? setState(() => _claimType = v) : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the issue in detail',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 8,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Estimated amount (optional)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Claim'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
