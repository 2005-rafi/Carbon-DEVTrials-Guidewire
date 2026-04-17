import 'package:carbon/core/network/api_client.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/features/auth/data/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<Dio>((ref) {
  Future<String?> refreshToken() async {
    return ref.read(authServiceProvider).refreshAccessToken();
  }

  Future<void> clearExpiredSession() async {
    await ref.read(authServiceProvider).clearSessionState(clearPersisted: true);
  }

  return ApiClient(
    tokenProvider: () => ref.read(authTokenProvider),
    refreshToken: refreshToken,
    onAuthExpired: clearExpiredSession,
  ).dio;
});
