import 'package:carbon/core/config/env.dart';

class AppConfig {
  static const AppEnv env = AppEnv.dev;
  static const String appName = 'Carbon';
  // Base API origin for all /api/v1 endpoints.
  // Note: backend docs are available at http://107.22.146.33:80/docs.
  static const String hostedBackendBaseUrl = 'http://107.22.146.33:80';

  static String get baseUrl {
    switch (env) {
      case AppEnv.dev:
        return hostedBackendBaseUrl;
      case AppEnv.staging:
        return hostedBackendBaseUrl;
      case AppEnv.prod:
        return hostedBackendBaseUrl;
    }
  }
}
