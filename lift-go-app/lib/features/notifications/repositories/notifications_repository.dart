import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.read(dioClientProvider));
});

class NotificationsRepository {
  final DioClient _client;
  NotificationsRepository(this._client);

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _client.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _client.patch('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.post('${ApiConstants.notifications}/mark-all-read');
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
