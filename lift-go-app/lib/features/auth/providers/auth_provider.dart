import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Auth State
// ---------------------------------------------------------------------------

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Check if we have a stored access token and user
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return const AuthState();
    }

    final userJson = await storage.getUser();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final user = UserModel.fromJsonString(userJson);
        return AuthState(user: user);
      } catch (_) {
        await storage.clear();
        return const AuthState();
      }
    }

    // Try fetching session from server
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getSession();
      if (user != null) {
        await storage.saveUser(user.toJsonString());
        return AuthState(user: user);
      }
    } catch (_) {
      await storage.clear();
    }

    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, clearError: true));
    try {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final result = await repo.login(email, password);
      await storage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await storage.saveUser(result.user.toJsonString());
      state = AsyncData(AuthState(user: result.user));
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = AsyncData(state.value!.copyWith(isLoading: true, clearError: true));
    try {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final result = await repo.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
      await storage.saveTokens(
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
      );
      await storage.saveUser(result.user.toJsonString());
      state = AsyncData(AuthState(user: result.user));
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);
    await repo.logout();
    await storage.clear();
    state = const AsyncData(AuthState());
  }

  Future<void> checkAuth() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final user = await repo.getSession();
      if (user != null) {
        await storage.saveUser(user.toJsonString());
        state = AsyncData(AuthState(user: user));
      } else {
        await storage.clear();
        state = const AsyncData(AuthState());
      }
    } catch (e) {
      state = const AsyncData(AuthState());
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Convenience provider — returns the current user or null
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value?.user;
});

/// Returns true when the user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value?.isAuthenticated ?? false;
});
