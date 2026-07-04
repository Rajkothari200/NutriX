import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();

  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      try {
        final response = await _api.dio.get(ApiEndpoints.me);
        final user = User.fromJson(response.data);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          token: await _api.getToken(),
        );
      } catch (_) {
        await _api.clearToken();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _api.saveToken(authResponse.accessToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        token: authResponse.accessToken,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed. Please try again.';
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message.toString(),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required String goal,
    List<Map<String, String>>? preferences,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = {
        'name': name,
        'email': email,
        'password': password,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'goal': goal,
        if (preferences != null)
          'preferences': preferences
              .map((p) => {
                    'preference_type': p['type'],
                    'value': p['value'],
                  })
              .toList(),
      };
      final response = await _api.dio.post(ApiEndpoints.register, data: data);
      final authResponse = AuthResponse.fromJson(response.data);
      await _api.saveToken(authResponse.accessToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        token: authResponse.accessToken,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed.';
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message.toString(),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
