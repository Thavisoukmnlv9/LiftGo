import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/invoice_model.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.read(dioClientProvider));
});

class FinanceRepository {
  final DioClient _client;
  FinanceRepository(this._client);

  Future<List<InvoiceModel>> getInvoices({int page = 1, int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.invoices,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvoiceModel> getInvoice(String id) async {
    final data = await _client.get('${ApiConstants.invoices}/$id');
    final item = _extractData(data);
    return InvoiceModel.fromJson(item as Map<String, dynamic>);
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
