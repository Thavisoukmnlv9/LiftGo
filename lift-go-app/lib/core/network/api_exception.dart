import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final String msg;
    if (data is Map) {
      msg = (data['error'] is Map
              ? data['error']['message']
              : null) ??
          data['message'] ??
          e.message ??
          'Network error';
    } else {
      msg = e.message ?? 'Network error';
    }
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
