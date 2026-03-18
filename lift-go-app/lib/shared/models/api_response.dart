class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}

class PaginatedData<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PaginatedData({required this.items, required this.pagination});
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        total: (json['total'] as num?)?.toInt() ?? 0,
        pages: (json['pages'] as num?)?.toInt() ?? 0,
        hasNext: json['has_next'] as bool? ?? false,
        hasPrev: json['has_prev'] as bool? ?? false,
      );
}
