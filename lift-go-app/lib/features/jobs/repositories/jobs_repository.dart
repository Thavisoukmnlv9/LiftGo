import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/job_model.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.read(dioClientProvider));
});

class JobsRepository {
  final DioClient _client;
  JobsRepository(this._client);

  Future<List<JobModel>> getJobs({int page = 1, int limit = 20}) async {
    final data = await _client.get(
      ApiConstants.jobs,
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = _extractList(data);
    return items.map((e) => JobModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JobModel> getJob(String id) async {
    final data = await _client.get('${ApiConstants.jobs}/$id');
    final item = _extractData(data);
    return JobModel.fromJson(item as Map<String, dynamic>);
  }

  Future<List<MilestoneLog>> getMilestones(String jobId) async {
    final data = await _client.get('${ApiConstants.jobs}/$jobId/milestones');
    final items = _extractList(data);
    return items.map((e) => MilestoneLog.fromJson(e as Map<String, dynamic>)).toList();
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
