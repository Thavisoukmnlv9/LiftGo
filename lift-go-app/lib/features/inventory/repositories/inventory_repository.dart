import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/inventory_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(dioClientProvider));
});

class InventoryRepository {
  final DioClient _client;
  InventoryRepository(this._client);

  Future<List<InventoryRoom>> getRoomsWithItems(String jobId) async {
    final data = await _client.get(
      '${ApiConstants.inventory}/jobs/$jobId/rooms',
    );
    final items = _extractList(data);
    return items
        .map((e) => InventoryRoom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateItemPackingStatus(String itemId, String status) async {
    await _client.patch(
      '${ApiConstants.inventory}/items/$itemId',
      data: {'packing_status': status},
    );
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
}
