import 'package:carbon/core/config/app_config.dart';
import 'package:carbon/core/constants/app_constants.dart';

class ApiConfig {
  static const bool gatewayOnlyMode = true;

  static String get baseUrl => _normalizeBaseUrl(AppConfig.baseUrl);
  static String get gatewayBaseUrl => _withPort(8001);
  static String get authGatewayBaseUrl => '$gatewayBaseUrl/api/v1';
  static String get identityServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8005);
  static String get policyServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8004);
  static String get aiRiskServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8003);
  static String get triggerServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8008);
  static String get claimsServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8009);
  static String get fraudServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8010);
  static String get payoutServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8007);
  static String get notificationServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8006);
  static String get analyticsServiceBaseUrl =>
    gatewayOnlyMode ? gatewayBaseUrl : _withPort(8011);

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

  static String _withPort(int port) {
    final normalized = baseUrl;
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return normalized;
    }

    final withPort = uri.replace(
      port: port,
      path: '',
      queryParameters: null,
      fragment: null,
    );
    final asString = withPort.toString();
    if (asString.endsWith('/')) {
      return asString.substring(0, asString.length - 1);
    }

    return asString;
  }
}
