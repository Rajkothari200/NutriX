import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';

final apiConfigProvider = StateNotifierProvider<ApiConfigNotifier, String>((ref) {
  return ApiConfigNotifier();
});

class ApiConfigNotifier extends StateNotifier<String> {
  static const _key = 'api_base_url';
  // Default to emulator localhost alias if nothing is set
  static const _defaultUrl = 'http://10.0.2.2:8000';

  ApiConfigNotifier() : super(_defaultUrl) {
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_key);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      state = savedUrl;
      ApiEndpoints.baseUrl = savedUrl;
    }
  }

  Future<void> setBaseUrl(String newUrl) async {
    // Basic cleanup of URL
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http')) {
      cleanUrl = 'http://$cleanUrl';
    }
    
    state = cleanUrl;
    ApiEndpoints.baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, cleanUrl);
  }
}
