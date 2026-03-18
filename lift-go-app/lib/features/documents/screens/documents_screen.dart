import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/status_badge.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class DocumentModel {
  final String id;
  final String name;
  final String docType;
  final String createdAt;
  final String? fileUrl;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.docType,
    required this.createdAt,
    this.fileUrl,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: json['id']?.toString() ?? '',
    name:
        json['name']?.toString() ?? json['file_name']?.toString() ?? 'Document',
    docType:
        json['doc_type']?.toString() ??
        json['document_type']?.toString() ??
        'general',
    createdAt: json['created_at']?.toString() ?? '',
    fileUrl: json['file_url']?.toString(),
  );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _documentsProvider = FutureProvider.autoDispose<List<DocumentModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final client = ref.read(dioClientProvider);
  final data = await client.get(
    '${ApiConstants.documents}/${user.id}/documents',
  );
  final items = data is Map
      ? (data['data'] is List
            ? data['data']
            : data['items'] is List
            ? data['items']
            : [])
      : data is List
      ? data
      : [];
  return (items as List)
      .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(_documentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: docsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorMessage(
          message: e.toString(),
          onRetry: () => ref.invalidate(_documentsProvider),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents uploaded yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the + button to upload your first document.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_documentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DocumentCard(doc: docs[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadDocument(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
    );
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading "${file.name}"…'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final client = ref.read(dioClientProvider);
      await client.post(
        '${ApiConstants.documents}/${user.id}/documents',
        data: {'file_name': file.name, 'doc_type': 'general'},
      );

      ref.invalidate(_documentsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
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
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String? dateFormatted;
    final dt = DateTime.tryParse(doc.createdAt);
    if (dt != null) dateFormatted = DateFormat('dd MMM yyyy').format(dt);

    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _iconForDocType(doc.docType),
            color: colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          doc.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            StatusBadge(status: doc.docType, fontSize: 10),
            if (dateFormatted != null) ...[
              const SizedBox(width: 8),
              Text(
                dateFormatted,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  IconData _iconForDocType(String type) {
    switch (type.toLowerCase()) {
      case 'invoice':
      case 'receipt':
        return Icons.receipt_outlined;
      case 'contract':
        return Icons.description_outlined;
      case 'id':
      case 'passport':
        return Icons.badge_outlined;
      case 'insurance':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
