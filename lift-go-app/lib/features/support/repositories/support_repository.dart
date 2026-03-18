import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/ticket_model.dart';
import '../models/claim_model.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.read(dioClientProvider));
});

class SupportRepository {
  final DioClient _client;
  SupportRepository(this._client);

  Future<List<SupportTicket>> getTickets({int page = 1, int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.tickets,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items
        .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicket> getTicket(String id) async {
    final data = await _client.get('${ApiConstants.tickets}/$id');
    final item = _extractData(data);
    return SupportTicket.fromJson(item as Map<String, dynamic>);
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String priority,
    String? jobId,
  }) async {
    final data = await _client.post(
      ApiConstants.tickets,
      data: {
        'subject': subject,
        'priority': priority,
        if (jobId != null && jobId.isNotEmpty) 'job_id': jobId,
      },
    );
    final item = _extractData(data);
    return SupportTicket.fromJson(item as Map<String, dynamic>);
  }

  Future<TicketMessage> addMessage(String ticketId, String body) async {
    final data = await _client.post(
      '${ApiConstants.tickets}/$ticketId/messages',
      data: {'body': body},
    );
    final item = _extractData(data);
    return TicketMessage.fromJson(item as Map<String, dynamic>);
  }

  Future<List<ClaimModel>> getClaims({int page = 1, int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.claims,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items
        .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClaimModel> createClaim({
    required String jobId,
    required String claimType,
    required String description,
    double? amount,
  }) async {
    final data = await _client.post(
      ApiConstants.claims,
      data: {
        'job_id': jobId,
        'claim_type': claimType,
        'description': description,
        if (amount != null) 'amount': amount,
      },
    );
    final item = _extractData(data);
    return ClaimModel.fromJson(item as Map<String, dynamic>);
  }

  dynamic _extractList(dynamic data) {
    if (data is Map) {
      return data['data'] is List
          ? data['data']
          : data['items'] is List
              ? data['items']
              : [];
    }
    if (data is List) return data;
    return [];
  }

  dynamic _extractData(dynamic data) {
    if (data is Map && data['data'] != null) return data['data'];
    return data;
  }
}
