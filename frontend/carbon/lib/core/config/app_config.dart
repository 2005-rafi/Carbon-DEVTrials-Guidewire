import 'package:carbon/core/config/env.dart';

class AppConfig {
  static const AppEnv env = AppEnv.dev;
  static const String appName = 'Carbon';
  static const String hostedApiHost = 'http://107.21.121.84';
  static const String hostedGatewayBaseUrl = 'http://107.21.121.84:8001';

  static String get baseUrl {
    switch (env) {
      case AppEnv.dev:
        return hostedGatewayBaseUrl;
      case AppEnv.staging:
        return hostedGatewayBaseUrl;
      case AppEnv.prod:
        return hostedGatewayBaseUrl;
    }
  }
}
