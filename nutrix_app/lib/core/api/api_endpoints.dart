class ApiEndpoints {
  // Base URL - change this to your live backend or update at runtime
  static String baseUrl = 'http://192.168.1.11:8000';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google';
  static const String me = '/api/auth/me';
  static const String resetPassword = '/api/auth/reset-password';

  // Profile & Targets
  static const String calculateProfile = '/calculate-profile';
  static String userTargets(int id) => '/users/$id/targets';
  static String userByEmail(String email) => '/users/$email';

  // Recommendations
  static const String recommendFoods = '/recommend-foods';

  // Meal Plan
  static const String generateMealPlan = '/generate-meal-plan';
  static String mealPlanHistory(int id) => '/users/$id/meal-plans';

  // Weight
  static const String trackWeight = '/track-weight';
  static String weightHistory(int id) => '/users/$id/weight-history';

  // Meal Logs
  static const String mealLogs = '/api/meal-logs';

  // Recipes
  static const String topRecipes = '/recipes/top';
  static const String searchRecipes = '/recipes/search';
  static String recipeDetail(String code) => '/recipes/$code';
  static const String recommendRecipes = '/recipes/recommend';
  static const String filterRecipes = '/recipes/filter';
  static const String generateInstructions = '/api/recipes/generate-instructions';

  // Barcode
  static String barcodeScan(String barcode) => '/api/barcode/$barcode';
  static const String barcodeManual = '/api/barcode/manual';
  static const String barcodeAlternatives = '/api/barcode/alternatives';

  // OCR
  static const String ocr = '/api/ocr';

  // Classify
  static const String classify = '/api/classify';

  // Analytics
  static String analytics(int id) => '/api/analytics/$id';
  static String analyticsHistory(int id) => '/api/analytics/$id/history';

  // Homely Meals
  static const String homelyCalculate = '/api/homely-meals/calculate';
  static const String homelyCreate = '/api/homely-meals/create';
  static const String homelySearch = '/api/homely-meals/search';
  static const String homelyPending = '/api/homely-meals/pending';
  static const String homelyBuilderDefaults = '/api/homely/builder-defaults';
  static String homelyDetail(int id) => '/api/homely-meals/$id';
  static String homelyReview(int mealId) => '/api/homely-meals/$mealId/review';

  // AI
  static const String aiCoach = '/api/ai/coach';
  static const String aiDietPlan = '/api/ai/diet-plan';
  static const String aiRecipeGenerator = '/api/ai/recipe-generator';

  // Search History
  static const String searchHistory = '/api/search-history';

  // Settings
  static const String settings = '/api/settings';

  // Health
  static const String health = '/api/health';
}
