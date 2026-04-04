enum AppEnv { dev, staging, prod }

extension AppEnvX on AppEnv {
  String get name => switch (this) {
    AppEnv.dev => 'dev',
    AppEnv.staging => 'staging',
    AppEnv.prod => 'prod',
  };
}
