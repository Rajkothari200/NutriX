import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

// ==========================
// Barcode Scanning & Lookup State
// ==========================
class BarcodeState {
  final bool isLoading;
  final bool isLogging;
  final Map<String, dynamic>? productData;
  final List<dynamic>? alternatives;
  final String? error;
  final String? logSuccessMessage;

  BarcodeState({
    this.isLoading = false,
    this.isLogging = false,
    this.productData,
    this.alternatives,
    this.error,
    this.logSuccessMessage,
  });

  BarcodeState copyWith({
    bool? isLoading,
    bool? isLogging,
    Map<String, dynamic>? productData,
    List<dynamic>? alternatives,
    String? error,
    String? logSuccessMessage,
  }) {
    return BarcodeState(
      isLoading: isLoading ?? this.isLoading,
      isLogging: isLogging ?? this.isLogging,
      productData: productData ?? this.productData,
      alternatives: alternatives ?? this.alternatives,
      error: error,
      logSuccessMessage: logSuccessMessage,
    );
  }
}

class BarcodeNotifier extends StateNotifier<BarcodeState> {
  final Ref ref;

  BarcodeNotifier(this.ref) : super(BarcodeState());

  Future<void> lookupBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    state = BarcodeState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get(ApiEndpoints.barcodeScan(barcode));
      state = BarcodeState(productData: response.data);
    } on DioException catch (e) {
      state = BarcodeState(
        error: e.response?.data?['detail']?.toString() ?? 'Product lookup failed.',
      );
    } catch (e) {
      state = BarcodeState(error: e.toString());
    }
  }

  Future<void> logScannedMeal({
    required int userId,
    required String mealType,
    required String productName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    state = state.copyWith(isLogging: true, error: null, logSuccessMessage: null);
    try {
      final apiClient = ApiClient();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      
      // 1. Log Meal to `/api/meal-logs`
      final logBody = {
        'user_id': userId,
        'log_date': todayStr,
        'meal_type': mealType,
        'food_name': productName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logBody);

      // 2. Fetch alternatives from `/api/barcode/alternatives`
      List<dynamic> alternativesList = [];
      try {
        final altResponse = await apiClient.dio.post(
          ApiEndpoints.barcodeAlternatives,
          data: {
            'product_name': productName,
            'meal_type': mealType,
            'protein_g': protein,
            'energy_kcal': calories,
            'sugar_g': 0.0,
            'fat_g': fat,
            'estimated_price': 20.0,
          },
        );
        if (altResponse.data != null && altResponse.data['alternatives'] != null) {
          alternativesList = altResponse.data['alternatives'];
        }
      } catch (e) {
        // Keep alternatives empty if call fails
      }

      state = state.copyWith(
        isLogging: false,
        logSuccessMessage: 'Successfully logged as $mealType!',
        alternatives: alternativesList,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLogging: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to log scanned meal.',
      );
    } catch (e) {
      state = state.copyWith(isLogging: false, error: e.toString());
    }
  }

  Future<void> submitManualBarcode({
    required String barcode,
    required String productName,
    required String brand,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    state = BarcodeState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final body = {
        'barcode': barcode,
        'product_name': productName,
        'brand': brand,
        'ingredients_text': 'Manually entered product',
        'energy_kcal': calories,
        'protein_g': protein,
        'carb_g': carbs,
        'fat_g': fat,
        'fibre_g': 0.0,
        'sodium_mg': 0.0,
        'sugar_g': 0.0,
        'saturated_fat_g': 0.0,
      };

      final response = await apiClient.dio.post(ApiEndpoints.barcodeManual, data: body);
      state = BarcodeState(productData: response.data);
    } on DioException catch (e) {
      state = BarcodeState(
        error: e.response?.data?['detail']?.toString() ?? 'Failed to submit manual barcode.',
      );
    } catch (e) {
      state = BarcodeState(error: e.toString());
    }
  }

  void clear() {
    state = BarcodeState();
  }
}

final barcodeProvider = StateNotifierProvider<BarcodeNotifier, BarcodeState>((ref) {
  return BarcodeNotifier(ref);
});

// ==========================
// Dietary Classifier State
// ==========================
class ClassificationState {
  final bool isLoading;
  final Map<String, dynamic>? classificationData;
  final String? error;

  ClassificationState({this.isLoading = false, this.classificationData, this.error});

  ClassificationState copyWith({bool? isLoading, Map<String, dynamic>? classificationData, String? error}) {
    return ClassificationState(
      isLoading: isLoading ?? this.isLoading,
      classificationData: classificationData ?? this.classificationData,
      error: error,
    );
  }
}

class ClassificationNotifier extends StateNotifier<ClassificationState> {
  final Ref ref;

  ClassificationNotifier(this.ref) : super(ClassificationState());

  Future<void> classifyIngredients(String ingredients) async {
    if (ingredients.isEmpty) return;

    final ingredientsList = ingredients.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ingredientsList.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        ApiEndpoints.classify,
        data: {'ingredients': ingredientsList},
      );
      state = state.copyWith(isLoading: false, classificationData: response.data);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Classification failed.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = ClassificationState();
  }
}

final classificationProvider = StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
  return ClassificationNotifier(ref);
});

// ==========================
// OCR Scanner State
// ==========================
class OcrState {
  final bool isLoading;
  final Map<String, dynamic>? ocrData;
  final String? error;

  OcrState({this.isLoading = false, this.ocrData, this.error});

  OcrState copyWith({bool? isLoading, Map<String, dynamic>? ocrData, String? error}) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      ocrData: ocrData ?? this.ocrData,
      error: error,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  final Ref ref;

  OcrNotifier(this.ref) : super(OcrState());

  Future<void> uploadOcrImage({
    required String filePath,
    required String fileName,
    required String mealType,
    required String foodName,
    required int userId,
  }) async {
    state = OcrState(isLoading: true);
    try {
      final apiClient = ApiClient();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'user_id': userId,
        'meal_type': mealType,
        'food_name': foodName.isEmpty ? fileName : foodName,
      });

      final response = await apiClient.dio.post(
        ApiEndpoints.ocr,
        data: formData,
      );

      state = OcrState(ocrData: response.data);
    } on DioException catch (e) {
      state = OcrState(
        error: e.response?.data?['detail']?.toString() ?? 'OCR scan failed.',
      );
    } catch (e) {
      state = OcrState(error: e.toString());
    }
  }

  void clear() {
    state = OcrState();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(ref);
});

// ==========================
// Analytics State
// ==========================
class AnalyticsState {
  final bool isLoading;
  final Map<String, dynamic>? summaryData;
  final List<dynamic>? historyData;
  final String? error;

  AnalyticsState({this.isLoading = false, this.summaryData, this.historyData, this.error});

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? summaryData,
    List<dynamic>? historyData,
    String? error,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      summaryData: summaryData ?? this.summaryData,
      historyData: historyData ?? this.historyData,
      error: error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref ref;

  AnalyticsNotifier(this.ref) : super(AnalyticsState());

  Future<void> fetchAnalytics(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ApiClient();
      
      // 1. Fetch summary averages from `/api/analytics/{user_id}`
      final summaryRes = await apiClient.dio.get(ApiEndpoints.analytics(userId));
      
      // 2. Fetch history logs from `/api/analytics/{user_id}/history`
      final historyRes = await apiClient.dio.get(ApiEndpoints.analyticsHistory(userId));

      state = AnalyticsState(
        summaryData: summaryRes.data,
        historyData: historyRes.data is List ? historyRes.data : [],
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Failed to load analytics.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});
