import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioClientProvider));
});

class AuthRepository {
  final DioClient _client;

  AuthRepository(this._client);

  Future<({AuthTokens tokens, UserModel user})> login(
    String email,
    String password,
  ) async {
    final data = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final tokens = AuthTokens.fromJson(data as Map<String, dynamic>);
    final userData = data['user'] as Map<String, dynamic>?;
    final user = userData != null
        ? UserModel.fromJson(userData)
        : UserModel(id: '', email: email, role: 'CUSTOMER');

    return (tokens: tokens, user: user);
  }

  Future<({AuthTokens tokens, UserModel user})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _client.post(
      ApiConstants.register,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone_number': phone,
      },
    );

    final tokens = AuthTokens.fromJson(data as Map<String, dynamic>);
    final userData = data['user'] as Map<String, dynamic>?;
    final user = userData != null
        ? UserModel.fromJson(userData)
        : UserModel(
            id: '',
            email: email,
            role: 'CUSTOMER',
            firstName: firstName,
            lastName: lastName,
          );

    return (tokens: tokens, user: user);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Ignore errors on logout — we clear tokens regardless
    }
  }

  Future<UserModel?> getSession() async {
    final data = await _client.get(ApiConstants.session);
    final userData = (data as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
    return userData != null ? UserModel.fromJson(userData) : null;
  }

  Future<void> forgotPassword(String email) async {
    await _client.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'password': newPassword},
    );
  }
}
