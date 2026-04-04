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

List<Interceptor> buildInterceptors(String? Function() tokenProvider) {
  return <Interceptor>[
    BearerTokenInterceptor(tokenProvider),
    LogInterceptor(requestBody: true, responseBody: true),
  ];
}
