import 'package:carbon/core/config/app_config.dart';
import 'package:carbon/core/constants/app_constants.dart';

class ApiConfig {
  static const String apiPrefix = '/api/v1';

  static String get baseUrl => _normalizeBaseUrl(AppConfig.baseUrl);

  static Duration get connectTimeout => AppConstants.networkTimeout;
  static Duration get receiveTimeout => AppConstants.networkTimeout;

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
