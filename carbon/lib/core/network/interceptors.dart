import 'package:dio/dio.dart';

class BearerTokenInterceptor extends Interceptor {
  BearerTokenInterceptor(this._tokenProvider);

  final String? Function() _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required this.dio,
    required this.refreshToken,
    required this.onAuthExpired,
  });

  final Dio dio;
  final Future<String?> Function()? refreshToken;
  final Future<void> Function()? onAuthExpired;

  Future<String?>? _activeRefresh;

  bool _isRetriable401(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 401) {
      return false;
    }

    final request = error.requestOptions;
    if (request.extra['_auth_retry'] == true) {
      return false;
    }

    final path = request.path.toLowerCase();
    const blockedAuthPaths = <String>[
      '/api/v1/auth/login',
      '/api/v1/auth/register',
      '/api/v1/auth/otp/',
      '/api/v1/auth/refresh',
      '/api/v1/auth/logout',
    ];

    return !blockedAuthPaths.any(path.contains);
  }

  Future<String?> _refreshAccessToken() async {
    if (refreshToken == null) {
      return null;
    }

    if (_activeRefresh != null) {
      return _activeRefresh;
    }

    _activeRefresh = refreshToken!.call();
    try {
      return await _activeRefresh;
    } finally {
      _activeRefresh = null;
    }
  }

  Future<void> _expireSession() async {
    if (onAuthExpired != null) {
      await onAuthExpired!.call();
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetriable401(err)) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null || newToken.trim().isEmpty) {
      await _expireSession();
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $newToken';

    final retryOptions = requestOptions.copyWith(
      headers: headers,
      extra: <String, dynamic>{...requestOptions.extra, '_auth_retry': true},
    );

    try {
      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      await _expireSession();
      handler.next(err);
    }
  }
}

List<Interceptor> buildInterceptors({
  required Dio dio,
  required String? Function() tokenProvider,
  Future<String?> Function()? refreshToken,
  Future<void> Function()? onAuthExpired,
}) {
  const simpleDemoSession = bool.fromEnvironment(
    'DEMO_SIMPLE_SESSION',
    defaultValue: false,
  );

  final interceptors = <Interceptor>[BearerTokenInterceptor(tokenProvider)];
  if (!simpleDemoSession) {
    interceptors.add(
      AuthRefreshInterceptor(
        dio: dio,
        refreshToken: refreshToken,
        onAuthExpired: onAuthExpired,
      ),
    );
  }

  const isProduction = bool.fromEnvironment('dart.vm.product');
  if (!isProduction) {
    interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  return interceptors;
}
