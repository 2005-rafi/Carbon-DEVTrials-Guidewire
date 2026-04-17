import 'dart:async';
import 'dart:developer' as developer;

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/auth_session_storage.dart';
import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthEnvironmentMode { real, systemNotificationDev }

final authEnvironmentModeProvider = Provider<AuthEnvironmentMode>((ref) {
  const notificationsEnabled = bool.fromEnvironment(
    'ENABLE_OTP_SYSTEM_NOTIFICATIONS',
    defaultValue: true,
  );

  if (notificationsEnabled) {
    return AuthEnvironmentMode.systemNotificationDev;
  }
  return AuthEnvironmentMode.real;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref,
    environmentMode: ref.read(authEnvironmentModeProvider),
  );
});

class AuthService {
  AuthService(this._ref, {required this.environmentMode});

  final Ref _ref;
  final AuthEnvironmentMode environmentMode;

  static const String _pendingPhoneKey = 'auth.pending_phone_number';
  Future<String?>? _activeRefresh;

  bool get shouldEnableSystemOtpNotification =>
      environmentMode == AuthEnvironmentMode.systemNotificationDev;

  Future<void> persistPendingPhone(String phoneNumber) async {
    final normalized = _normalizePhone(phoneNumber);
    _ref.read(authPendingPhoneProvider.notifier).state = normalized;
    if (normalized.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPhoneKey, normalized);
  }

  Future<String?> readPendingPhone() async {
    final inMemory = (_ref.read(authPendingPhoneProvider) ?? '').trim();
    if (inMemory.isNotEmpty) {
      return inMemory;
    }

    final prefs = await SharedPreferences.getInstance();
    final persisted = _normalizePhone(prefs.getString(_pendingPhoneKey) ?? '');
    if (persisted.isEmpty) {
      return null;
    }

    _ref.read(authPendingPhoneProvider.notifier).state = persisted;
    return persisted;
  }

  Future<void> clearPendingPhone() async {
    _ref.read(authPendingPhoneProvider.notifier).state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPhoneKey);
  }

  Future<void> applyVerificationHandshake({
    required String phoneNumber,
    required String verificationToken,
  }) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    final normalizedToken = verificationToken.trim();
    if (normalizedPhone.isEmpty || normalizedToken.isEmpty) {
      throw const FormatException(
        'Verification handshake is missing a phone number or token.',
      );
    }

    await persistPendingPhone(normalizedPhone);
    await clearPendingRegistrationSession();
    _ref.read(authVerificationTokenProvider.notifier).state = normalizedToken;
  }

  String? readVerificationToken() {
    final token = (_ref.read(authVerificationTokenProvider) ?? '').trim();
    if (token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> clearVerificationHandshake() async {
    _ref.read(authVerificationTokenProvider.notifier).state = null;
  }

  Future<void> applyPendingRegistrationSession({
    required String phoneNumber,
    required TokenResponse token,
  }) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    final access = token.accessToken.trim();
    final refresh = token.refreshToken.trim();
    final userId = token.userId.trim();
    final tokenType = token.tokenType.trim().isEmpty
        ? 'bearer'
        : token.tokenType.trim();

    if (normalizedPhone.isEmpty ||
        access.isEmpty ||
        refresh.isEmpty ||
        userId.isEmpty) {
      throw const FormatException(
        'Pending registration session is missing required token fields.',
      );
    }

    await persistPendingPhone(normalizedPhone);
    await clearVerificationHandshake();
    _ref.read(authPendingRegistrationAccessTokenProvider.notifier).state =
        access;
    _ref.read(authPendingRegistrationRefreshTokenProvider.notifier).state =
        refresh;
    _ref.read(authPendingRegistrationUserIdProvider.notifier).state = userId;
    _ref.read(authPendingRegistrationTokenTypeProvider.notifier).state =
        tokenType;
  }

  TokenResponse? readPendingRegistrationSession() {
    final access = (_ref.read(authPendingRegistrationAccessTokenProvider) ?? '')
        .trim();
    final refresh =
        (_ref.read(authPendingRegistrationRefreshTokenProvider) ?? '').trim();
    final userId = (_ref.read(authPendingRegistrationUserIdProvider) ?? '')
        .trim();
    final tokenType =
        (_ref.read(authPendingRegistrationTokenTypeProvider) ?? 'bearer')
            .trim();

    if (access.isEmpty || refresh.isEmpty || userId.isEmpty) {
      return null;
    }

    return TokenResponse(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      tokenType: tokenType.isEmpty ? 'bearer' : tokenType,
    );
  }

  Future<void> clearPendingRegistrationSession() async {
    _ref.read(authPendingRegistrationAccessTokenProvider.notifier).state = null;
    _ref.read(authPendingRegistrationRefreshTokenProvider.notifier).state =
        null;
    _ref.read(authPendingRegistrationUserIdProvider.notifier).state = null;
    _ref.read(authPendingRegistrationTokenTypeProvider.notifier).state = null;
  }

  Future<void> applyToken(TokenResponse token) async {
    final existingUserId = (_ref.read(authUserIdProvider) ?? '').trim();
    final resolvedUserId = token.userId.trim().isNotEmpty
        ? token.userId.trim()
        : existingUserId;

    if (resolvedUserId.isEmpty || token.accessToken.trim().isEmpty) {
      throw const FormatException(
        'Session response is missing required identity or access token.',
      );
    }

    final hydratedToken = TokenResponse(
      accessToken: token.accessToken.trim(),
      refreshToken: token.refreshToken.trim(),
      userId: resolvedUserId,
      tokenType: token.tokenType,
    );

    _ref.read(authTokenProvider.notifier).state = hydratedToken.accessToken;
    _ref.read(refreshTokenProvider.notifier).state = hydratedToken.refreshToken;
    _ref.read(authUserIdProvider.notifier).state = hydratedToken.userId;
    _ref.read(isAuthenticatedProvider.notifier).state = true;
    await clearPendingRegistrationSession();
    await clearVerificationHandshake();
    await clearPendingPhone();

    await _ref
        .read(authSessionStorageProvider)
        .save(
          AuthSessionData(
            accessToken: hydratedToken.accessToken,
            refreshToken: hydratedToken.refreshToken,
            userId: hydratedToken.userId,
          ),
        );
  }

  Future<void> clearSessionState({required bool clearPersisted}) async {
    _ref.read(isAuthenticatedProvider.notifier).state = false;
    _ref.read(authTokenProvider.notifier).state = null;
    _ref.read(refreshTokenProvider.notifier).state = null;
    _ref.read(authUserIdProvider.notifier).state = null;
    await clearPendingRegistrationSession();
    await clearVerificationHandshake();
    await clearPendingPhone();

    if (!clearPersisted) {
      return;
    }

    try {
      await _ref.read(authSessionStorageProvider).clear();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to clear persisted auth session: $error',
        name: 'AuthService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> refreshAccessToken() {
    if (_activeRefresh != null) {
      return _activeRefresh!;
    }

    _activeRefresh = _refreshAccessTokenInternal();
    return _activeRefresh!.whenComplete(() => _activeRefresh = null);
  }

  Future<String?> _refreshAccessTokenInternal() async {
    final refreshToken = (_ref.read(refreshTokenProvider) ?? '').trim();
    if (refreshToken.isEmpty) {
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: <String, dynamic>{'Content-Type': 'application/json'},
      ),
    );

    try {
      final response = await refreshDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(
          headers: <String, dynamic>{
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      final parsed = TokenResponse.fromDynamic(response.data);
      final existingUserId = (_ref.read(authUserIdProvider) ?? '').trim();
      final hydrated = TokenResponse(
        accessToken: parsed.accessToken,
        refreshToken: parsed.refreshToken.trim().isNotEmpty
            ? parsed.refreshToken.trim()
            : refreshToken,
        userId: parsed.userId.trim().isNotEmpty
            ? parsed.userId.trim()
            : existingUserId,
        tokenType: parsed.tokenType,
      );

      if (!hydrated.isValid || hydrated.userId.trim().isEmpty) {
        return null;
      }

      await applyToken(hydrated);
      return hydrated.accessToken;
    } on DioException catch (error, stackTrace) {
      developer.log(
        'Session refresh failed: ${error.message}',
        name: 'AuthService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected refresh failure: $error',
        name: 'AuthService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '').trim();
  }
}
