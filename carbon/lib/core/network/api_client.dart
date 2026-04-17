import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/interceptors.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({
    String? Function()? tokenProvider,
    Future<String?> Function()? refreshToken,
    Future<void> Function()? onAuthExpired,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: ApiConfig.baseUrl,
           connectTimeout: ApiConfig.connectTimeout,
           receiveTimeout: ApiConfig.receiveTimeout,
           headers: <String, dynamic>{'Content-Type': 'application/json'},
         ),
       ) {
    dio.interceptors.addAll(
      buildInterceptors(
        dio: dio,
        tokenProvider: tokenProvider ?? (() => null),
        refreshToken: refreshToken,
        onAuthExpired: onAuthExpired,
      ),
    );
  }

  final Dio dio;
}
