import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/quote_model.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository(ref.read(dioClientProvider));
});

class QuotesRepository {
  final DioClient _client;
  QuotesRepository(this._client);

  Future<List<QuoteModel>> getQuotes({int page = 1, int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.quotes,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items.map((e) => QuoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QuoteModel> getQuote(String id) async {
    final data = await _client.get('${ApiConstants.quotes}/$id');
    final item = _extractData(data);
    return QuoteModel.fromJson(item as Map<String, dynamic>);
  }

  Future<void> createQuoteRequest(Map<String, dynamic> leadData) async {
    await _client.post(ApiConstants.leads, data: leadData);
  }

  Future<QuoteModel> acceptQuote(String id) async {
    final data = await _client.patch(
      '${ApiConstants.quotes}/$id',
      data: {'status': 'approved'},
    );
    final item = _extractData(data);
    return QuoteModel.fromJson(item as Map<String, dynamic>);
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
