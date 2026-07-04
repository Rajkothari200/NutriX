import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// ==========================
// Homely Builder Defaults State
// ==========================
class HomelyBuilderState {
  final bool isLoading;
  final Map<String, dynamic>? defaults;
  final String? error;

  HomelyBuilderState({this.isLoading = false, this.defaults, this.error});

  HomelyBuilderState copyWith({bool? isLoading, Map<String, dynamic>? defaults, String? error}) {
    return HomelyBuilderState(
      isLoading: isLoading ?? this.isLoading,
      defaults: defaults ?? this.defaults,
      error: error,
    );
  }
}

class HomelyBuilderNotifier extends StateNotifier<HomelyBuilderState> {
  final Ref ref;

  HomelyBuilderNotifier(this.ref) : super(HomelyBuilderState());

  Future<void> fetchDefaults() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.homelyBuilderDefaults);
      state = HomelyBuilderState(defaults: response.data);
    } on DioException catch (e) {
      state = HomelyBuilderState(
        error: e.response?.data?['detail']?.toString() ?? 'Failed to load homely builder defaults.',
      );
    } catch (e) {
      state = HomelyBuilderState(error: e.toString());
    }
  }
}

final homelyBuilderProvider = StateNotifierProvider<HomelyBuilderNotifier, HomelyBuilderState>((ref) {
  return HomelyBuilderNotifier(ref);
});

// ==========================
// Custom Meal Calculator & Creator State
// ==========================
class HomelyCustomMealState {
  final bool isLoading;
  final bool isSaving;
  final Map<String, dynamic>? calculatedMacros;
  final String? successMessage;
  final String? error;

  HomelyCustomMealState({
    this.isLoading = false,
    this.isSaving = false,
    this.calculatedMacros,
    this.successMessage,
    this.error,
  });

  HomelyCustomMealState copyWith({
    bool? isLoading,
    bool? isSaving,
    Map<String, dynamic>? calculatedMacros,
    String? successMessage,
    String? error,
  }) {
    return HomelyCustomMealState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      calculatedMacros: calculatedMacros ?? this.calculatedMacros,
      successMessage: successMessage,
      error: error,
    );
  }
}

class HomelyCustomMealNotifier extends StateNotifier<HomelyCustomMealState> {
  final Ref ref;

  HomelyCustomMealNotifier(this.ref) : super(HomelyCustomMealState());

  Future<void> calculateMacros(List<Map<String, dynamic>> ingredients) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.homelyCalculate,
        data: {'ingredients': ingredients},
      );
      state = state.copyWith(isLoading: false, calculatedMacros: response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to calculate macros.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createCustomMeal({
    required String name,
    required String cuisine,
    required String region,
    required bool isCommunity,
    required List<Map<String, dynamic>> ingredients,
    required int userId,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final apiClient = ApiClient();
      final payload = {
        'name': name,
        'creator_id': userId,
        'is_community': isCommunity,
        'cuisine': cuisine,
        'region': region.isEmpty ? null : region,
        'ingredients': ingredients,
      };

      await apiClient.dio.post(
        ApiEndpoints.homelyCreate,
        data: payload,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Custom homely meal created successfully!',
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to create homely meal.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void clear() {
    state = HomelyCustomMealState();
  }
}

final homelyCustomMealProvider = StateNotifierProvider<HomelyCustomMealNotifier, HomelyCustomMealState>((ref) {
  return HomelyCustomMealNotifier(ref);
});

// ==========================
// Community Kitchen & Moderation State
// ==========================
class HomelyCommunityState {
  final bool isLoading;
  final List<dynamic> communityMeals;
  final List<dynamic> pendingReviews;
  final String? error;

  HomelyCommunityState({
    this.isLoading = false,
    this.communityMeals = const [],
    this.pendingReviews = const [],
    this.error,
  });

  HomelyCommunityState copyWith({
    bool? isLoading,
    List<dynamic>? communityMeals,
    List<dynamic>? pendingReviews,
    String? error,
  }) {
    return HomelyCommunityState(
      isLoading: isLoading ?? this.isLoading,
      communityMeals: communityMeals ?? this.communityMeals,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      error: error,
    );
  }
}

class HomelyCommunityNotifier extends StateNotifier<HomelyCommunityState> {
  final Ref ref;

  HomelyCommunityNotifier(this.ref) : super(HomelyCommunityState());

  Future<void> searchMeals(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        ApiEndpoints.homelySearch,
        queryParameters: {'q': query},
      );
      state = state.copyWith(
        isLoading: false,
        communityMeals: response.data is List ? response.data : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to search community meals.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchPending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.homelyPending);
      state = state.copyWith(
        isLoading: false,
        pendingReviews: response.data is List ? response.data : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to fetch pending reviews.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> moderateMeal({
    required int mealId,
    required String status,
    required int userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post(
        '/api/homely-meals/review/$mealId',
        data: {
          'status': status,
          'reviewer_id': userId,
          'comment': '${status.toUpperCase()} during moderation in app.',
        },
      );
      // Reload lists
      await fetchPending();
      await searchMeals('');
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Moderation action failed.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final homelyCommunityProvider = StateNotifierProvider<HomelyCommunityNotifier, HomelyCommunityState>((ref) {
  return HomelyCommunityNotifier(ref);
});
