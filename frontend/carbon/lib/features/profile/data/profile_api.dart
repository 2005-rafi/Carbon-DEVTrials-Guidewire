import 'package:dio/dio.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <String, dynamic>{
      'name': 'Avery Johnson',
      'phone': '+91 90000 00000',
      'city': 'Bengaluru',
      'source': _dio.options.baseUrl,
    };
  }
}
