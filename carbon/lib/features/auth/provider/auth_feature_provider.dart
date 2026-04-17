import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/auth_session_storage.dart';
import 'package:carbon/features/auth/data/auth_api.dart';
import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:carbon/features/auth/data/auth_service.dart';
import 'package:carbon/features/worker/data/worker_api.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);

final authBootstrapLoadingProvider = StateProvider<bool>((ref) => false);

final authErrorProvider = StateProvider<String?>((ref) => null);

final otpSendFeedbackProvider = StateProvider<OtpSendResponse?>((ref) => null);

final authToastTypeProvider = StateProvider<AppToastType>(
  (ref) => AppToastType.error,
);

final authActionProvider = Provider<AuthAction>((ref) {
  return AuthAction(ref);
});

class AuthAction {
  AuthAction(this._ref);

  final Ref _ref;
  Future<void>? _activeResumeSync;

  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
    _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
  }

  void markAuthenticated() {
    _ref.read(isAuthenticatedProvider.notifier).state = true;
  }

  void markLoggedOut() {
    unawaited(_clearSessionState(clearPersisted: true));
  }

  Future<void> _setPendingPhone(String phoneNumber) async {
    final cleaned = phoneNumber.trim();
    await _ref.read(authServiceProvider).persistPendingPhone(cleaned);
  }

  Future<void> _applyToken(TokenResponse token) async {
    await _ref.read(authServiceProvider).applyToken(token);
  }

  Future<void> _clearSessionState({required bool clearPersisted}) async {
    await _ref
        .read(authServiceProvider)
        .clearSessionState(clearPersisted: clearPersisted);
  }

  Future<void> _refreshWorkerAfterAuth() async {
    await _ref.read(workerActionProvider).refreshIfAuthenticated();
  }

  Future<void> _ensureRegisteredProfile() async {
    try {
      final profile = await _ref.read(workerApiProvider).fetchProfile();
      if (!profile.hasIdentity || profile.isIncomplete) {
        throw const ApiException(
          'Your account setup is incomplete. Please complete registration before signing in.',
          statusCode: 403,
        );
      }
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw const ApiException(
          'No account was found for this mobile number. Please create an account first.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  Future<bool> bootstrapSession() async {
    if (_ref.read(authBootstrapLoadingProvider)) {
      return _ref.read(isAuthenticatedProvider);
    }

    _ref.read(authBootstrapLoadingProvider.notifier).state = true;
    try {
      final cachedSession = await _ref.read(authSessionStorageProvider).read();
      if (cachedSession == null) {
        await _clearSessionState(clearPersisted: false);
        return false;
      }

      _ref.read(authTokenProvider.notifier).state = cachedSession.accessToken;
      _ref.read(refreshTokenProvider.notifier).state =
          cachedSession.refreshToken;
      _ref.read(authUserIdProvider.notifier).state = cachedSession.userId;
      _ref.read(isAuthenticatedProvider.notifier).state = true;

      final validSession = await _stabilizeSessionFromCache(cachedSession);
      if (!validSession) {
        await _clearSessionState(clearPersisted: true);
      }

      return validSession;
    } catch (error, stackTrace) {
      developer.log(
        'Session bootstrap failed: $error',
        name: 'AuthAction',
        error: error,
        stackTrace: stackTrace,
      );
      await _clearSessionState(clearPersisted: true);
      return false;
    } finally {
      _ref.read(authBootstrapLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> _stabilizeSessionFromCache(AuthSessionData session) async {
    final token = session.accessToken.trim();
    if (token.isEmpty) {
      return false;
    }

    if (_isLikelyExpiredJwt(token)) {
      final refreshedToken = await refreshSessionToken();
      if (refreshedToken == null) {
        return false;
      }
    }

    try {
      final validation = await _ref.read(authApiProvider).validate();
      return validation.isValid;
    } on ApiException {
      return (await refreshSessionToken()) != null;
    } catch (_) {
      return false;
    }
  }

  bool _isLikelyExpiredJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final exp = decoded['exp'];
      if (exp is! num) {
        return false;
      }

      final nowEpochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowEpochSeconds >= exp.toInt();
    } catch (_) {
      return false;
    }
  }

  Future<String?> refreshSessionToken() async {
    try {
      return await _ref.read(authServiceProvider).refreshAccessToken();
    } catch (error, stackTrace) {
      developer.log(
        'Session refresh failed: $error',
        name: 'AuthAction',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> handleAppResumed() async {
    if (_activeResumeSync != null) {
      await _activeResumeSync;
      return;
    }

    _activeResumeSync = _syncSessionOnResume();
    try {
      await _activeResumeSync;
    } finally {
      _activeResumeSync = null;
    }
  }

  Future<void> _syncSessionOnResume() async {
    if (_ref.read(authBootstrapLoadingProvider)) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }

    final token = (_ref.read(authTokenProvider) ?? '').trim();
    if (token.isEmpty) {
      await _clearSessionState(clearPersisted: true);
      return;
    }

    if (_isLikelyExpiredJwt(token)) {
      final refreshedToken = await refreshSessionToken();
      if (refreshedToken == null) {
        await _clearSessionState(clearPersisted: true);
      }
      return;
    }

    try {
      final validation = await _ref.read(authApiProvider).validate();
      if (!validation.isValid) {
        await _clearSessionState(clearPersisted: true);
      }
    } on ApiException catch (error, stackTrace) {
      developer.log(
        'Session validation on app resume failed: ${error.message}',
        name: 'AuthAction',
        error: error,
        stackTrace: stackTrace,
      );

      final statusCode = error.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _clearSessionState(clearPersisted: true);
        return;
      }

      final refreshedToken = await refreshSessionToken();
      if (refreshedToken == null && statusCode != null && statusCode < 500) {
        await _clearSessionState(clearPersisted: true);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Transient session validation failure on app resume: $error',
        name: 'AuthAction',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<TokenResponse> _ensureTokenHasUserId({
    required TokenResponse token,
    required String fallbackErrorMessage,
  }) async {
    if (token.userId.trim().isNotEmpty) {
      return token;
    }

    final candidateAccessToken = token.accessToken.trim().isNotEmpty
        ? token.accessToken.trim()
        : token.verificationToken.trim();
    if (candidateAccessToken.isEmpty) {
      throw ApiException(fallbackErrorMessage, statusCode: 401);
    }

    final validation = await _ref
        .read(authApiProvider)
        .validateWithToken(accessToken: candidateAccessToken);
    if (!validation.isValid || validation.userId.trim().isEmpty) {
      throw ApiException(fallbackErrorMessage, statusCode: 401);
    }

    return TokenResponse(
      accessToken: candidateAccessToken,
      refreshToken: token.refreshToken.trim().isNotEmpty
          ? token.refreshToken.trim()
          : candidateAccessToken,
      userId: validation.userId.trim(),
      tokenType: token.tokenType,
      verificationToken: token.verificationToken,
    );
  }

  Future<void> _createWorkerProfileAndApplySession({
    required String phone,
    required String fullName,
    required String email,
    required TokenResponse token,
  }) async {
    await _ref
        .read(authApiProvider)
        .createProfile(
          phone: phone,
          fullName: fullName,
          email: email,
          userId: token.userId,
          accessToken: token.accessToken,
        );
    await _applyToken(token);
    await _refreshWorkerAfterAuth();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref.read(authServiceProvider).clearPendingRegistrationSession();
      await _ref.read(authServiceProvider).clearVerificationHandshake();
      await _setPendingPhone(phoneNumber);
      final dispatchResult = await _ref
          .read(authApiProvider)
          .sendOtp(phone: phoneNumber);
      _ref.read(otpSendFeedbackProvider.notifier).state = dispatchResult;
      return true;
    } on ApiException catch (error) {
      developer.log('Send OTP failed: ${error.toString()}', name: 'AuthAction');
      _ref.read(otpSendFeedbackProvider.notifier).state = null;
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    } catch (_) {
      _ref.read(otpSendFeedbackProvider.notifier).state = null;
      _ref.read(authErrorProvider.notifier).state =
          'Unable to send OTP right now. Please try again.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> login(String phoneNumber, String otp) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _setPendingPhone(phoneNumber);
      final token = await _ref
          .read(authApiProvider)
          .login(phoneNumber: phoneNumber, otp: otp);
      final hydratedToken = await _ensureTokenHasUserId(
        token: token,
        fallbackErrorMessage:
            'Sign-in succeeded but account identity is missing. Please retry login.',
      );
      await _applyToken(hydratedToken);
      await _ensureRegisteredProfile();
      await _refreshWorkerAfterAuth();
      return true;
    } on ApiException catch (error) {
      developer.log('Login failed: ${error.toString()}', name: 'AuthAction');
      if (error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.statusCode == 404) {
        await _clearSessionState(clearPersisted: true);
      }
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.login,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.login,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Sign-in is temporarily unavailable. Please try again in a moment.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String email,
  }) async {
    final hasProfileDraft =
        fullName.trim().isNotEmpty || email.trim().isNotEmpty;
    if (hasProfileDraft) {
      developer.log(
        'OTP-first registration defers profile fields until finalization.',
        name: 'AuthAction.register',
      );
    }
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref.read(authServiceProvider).clearPendingRegistrationSession();
      await _ref.read(authServiceProvider).clearVerificationHandshake();
      await _setPendingPhone(phoneNumber);
      final dispatchResult = await _ref
          .read(authApiProvider)
          .sendOtp(phone: phoneNumber);
      _ref.read(otpSendFeedbackProvider.notifier).state = dispatchResult;
      return true;
    } on ApiException catch (error) {
      developer.log(
        'Registration failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(otpSendFeedbackProvider.notifier).state = null;
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.register,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.register,
      );
      return false;
    } catch (_) {
      _ref.read(otpSendFeedbackProvider.notifier).state = null;
      _ref.read(authErrorProvider.notifier).state =
          'Account creation is temporarily unavailable. Please try again shortly.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      final phone = await _ref.read(authServiceProvider).readPendingPhone();
      if (phone == null || phone.trim().isEmpty) {
        throw const ApiException(
          'Phone number context is missing. Please register or login again.',
        );
      }
      final token = await _ref
          .read(authApiProvider)
          .verifyOtp(phone: phone, otp: otp);
      if (token.isValid) {
        final hydratedToken = await _ensureTokenHasUserId(
          token: token,
          fallbackErrorMessage:
              'Verification succeeded but account identity is missing. Please try again.',
        );
        await _applyToken(hydratedToken);
        await _ensureRegisteredProfile();
        await _refreshWorkerAfterAuth();
        return true;
      }

      if (token.hasVerificationToken) {
        final loginToken = await _ref
            .read(authApiProvider)
            .login(phoneNumber: phone, otp: otp);
        final hydratedLoginToken = await _ensureTokenHasUserId(
          token: loginToken,
          fallbackErrorMessage:
              'Unable to establish your session. Please request a new OTP and try again.',
        );
        await _applyToken(hydratedLoginToken);
        await _ensureRegisteredProfile();
        await _refreshWorkerAfterAuth();
        return true;
      }

      throw const ApiException(
        'Verification succeeded but sign-in tokens were not provided.',
      );
    } on ApiException catch (error) {
      developer.log(
        'OTP verification failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'OTP verification failed. Please try again.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> verifyRegistrationOtp({required String otp}) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final phone = await _ref.read(authServiceProvider).readPendingPhone();
      if (phone == null || phone.trim().isEmpty) {
        throw const ApiException(
          'Phone number context is missing. Please register again.',
        );
      }

      final token = await _ref
          .read(authApiProvider)
          .verifyOtp(phone: phone, otp: otp);
      if (token.isValid) {
        final hydratedToken = await _ensureTokenHasUserId(
          token: token,
          fallbackErrorMessage:
              'Verification succeeded but account identity is missing. Please retry OTP verification.',
        );
        await _ref
            .read(authServiceProvider)
            .applyPendingRegistrationSession(
              phoneNumber: phone,
              token: hydratedToken,
            );
        return true;
      }

      if (token.hasVerificationToken) {
        try {
          final validation = await _ref
              .read(authApiProvider)
              .validateWithToken(accessToken: token.verificationToken);
          if (validation.isValid && validation.userId.trim().isNotEmpty) {
            final pendingToken = TokenResponse(
              accessToken: token.verificationToken,
              refreshToken: token.verificationToken,
              userId: validation.userId.trim(),
              tokenType: token.tokenType,
              verificationToken: token.verificationToken,
            );

            await _ref
                .read(authServiceProvider)
                .applyPendingRegistrationSession(
                  phoneNumber: phone,
                  token: pendingToken,
                );
            return true;
          }
        } on ApiException catch (error, stackTrace) {
          developer.log(
            'Registration OTP token validation fallback failed: ${error.message}',
            name: 'AuthAction',
            error: error,
            stackTrace: stackTrace,
          );
        }

        // Some backends return a token-only verify response. Try upgrading to a
        // full session via login so registration can finalize via workers/profile.
        try {
          final loginToken = await _ref
              .read(authApiProvider)
              .login(phoneNumber: phone, otp: otp);
          if (loginToken.isValid) {
            final hydratedLoginToken = await _ensureTokenHasUserId(
              token: loginToken,
              fallbackErrorMessage:
                  'Unable to establish a verified registration session. Please request a new OTP.',
            );
            await _ref
                .read(authServiceProvider)
                .applyPendingRegistrationSession(
                  phoneNumber: phone,
                  token: hydratedLoginToken,
                );
            return true;
          }
        } on ApiException catch (error, stackTrace) {
          developer.log(
            'Registration OTP session upgrade via login failed: ${error.message}',
            name: 'AuthAction',
            error: error,
            stackTrace: stackTrace,
          );
        }

        await _ref
            .read(authServiceProvider)
            .applyVerificationHandshake(
              phoneNumber: phone,
              verificationToken: token.verificationToken,
            );
        return true;
      }

      throw const ApiException(
        'Verification session expired. Please restart login and verify again.',
        statusCode: 401,
      );
    } on ApiException catch (error) {
      developer.log(
        'Registration OTP verification failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'OTP verification failed. Please try again.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> finalizeRegistrationProfile({
    required String fullName,
    required String email,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final phone = await _ref.read(authServiceProvider).readPendingPhone();
      final verificationToken = _ref
          .read(authServiceProvider)
          .readVerificationToken();
      final pendingRegistrationToken = _ref
          .read(authServiceProvider)
          .readPendingRegistrationSession();

      if (phone == null || phone.trim().isEmpty) {
        throw const ApiException(
          'Session expired. Please restart verification from login.',
          statusCode: 401,
        );
      }

      if (pendingRegistrationToken != null) {
        await _createWorkerProfileAndApplySession(
          phone: phone,
          fullName: fullName,
          email: email,
          token: pendingRegistrationToken,
        );
        return true;
      }

      if (verificationToken != null) {
        try {
          final token = await _ref
              .read(authApiProvider)
              .register(
                fullName: fullName,
                phoneNumber: phone,
                email: email,
                verificationToken: verificationToken,
              );
          final hydratedToken = await _ensureTokenHasUserId(
            token: token,
            fallbackErrorMessage:
                'Unable to establish a registration session. Please request a new OTP.',
          );
          await _applyToken(hydratedToken);
          await _refreshWorkerAfterAuth();
          return true;
        } on ApiException catch (registerError) {
          if (!_shouldFallbackToWorkerProfile(registerError)) {
            rethrow;
          }

          developer.log(
            'Auth register endpoint unavailable, falling back to workers/profile finalization.',
            name: 'AuthAction',
          );

          final validation = await _ref
              .read(authApiProvider)
              .validateWithToken(accessToken: verificationToken);
          if (!validation.isValid || validation.userId.trim().isEmpty) {
            throw const ApiException(
              'Session expired. Please restart verification from login.',
              statusCode: 401,
            );
          }

          final fallbackToken = TokenResponse(
            accessToken: verificationToken,
            refreshToken: verificationToken,
            userId: validation.userId.trim(),
            tokenType: 'bearer',
            verificationToken: verificationToken,
          );

          await _createWorkerProfileAndApplySession(
            phone: phone,
            fullName: fullName,
            email: email,
            token: fallbackToken,
          );
          return true;
        }
      }

      throw const ApiException(
        'Session expired. Please restart verification from login.',
        statusCode: 401,
      );
    } on ApiException catch (error, stackTrace) {
      developer.log(
        'Profile finalization failed: ${error.toString()}',
        name: 'AuthAction',
        error: error,
        stackTrace: stackTrace,
      );

      if (error.statusCode == 401 || error.statusCode == 403) {
        await _ref.read(authServiceProvider).clearPendingRegistrationSession();
        await _ref.read(authServiceProvider).clearVerificationHandshake();
        await _ref.read(authServiceProvider).clearPendingPhone();
      }

      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.register,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.register,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Unable to complete your profile right now. Please try again.';
      _ref.read(authToastTypeProvider.notifier).state = AppToastType.error;
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  bool _shouldFallbackToWorkerProfile(ApiException error) {
    final code = error.statusCode;
    if (code == 404 || code == 405 || code == 410 || code == 501) {
      return true;
    }

    final message = error.message.trim().toLowerCase();
    if (message.isEmpty) {
      return false;
    }

    return message.contains('not found') ||
        message.contains('not implemented') ||
        message.contains('route not found');
  }

  Future<bool> resendOtp() async {
    try {
      final phone = await _ref.read(authServiceProvider).readPendingPhone();
      if (phone == null || phone.trim().isEmpty) {
        throw const ApiException(
          'Session expired. Please restart login to request a new OTP.',
          statusCode: 401,
        );
      }
      return sendOtp(phone);
    } on ApiException catch (error) {
      developer.log(
        'Resend OTP failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      _ref.read(authToastTypeProvider.notifier).state = _mapToastTypeForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    }
  }

  Future<void> logout({bool notifyBackend = true}) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    try {
      if (notifyBackend) {
        try {
          await _ref.read(authApiProvider).logout();
        } catch (error, stackTrace) {
          developer.log(
            'Backend logout call failed: $error',
            name: 'AuthAction',
            error: error,
            stackTrace: stackTrace,
          );
          // Local logout should still proceed even if backend is temporarily down.
        }
      }
    } finally {
      await _clearSessionState(clearPersisted: true);
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  String _mapAuthErrorForUi(ApiException error, {required _AuthFlow flow}) {
    final normalizedMessage = error.message.trim().toLowerCase();
    final code = error.statusCode;

    if (flow == _AuthFlow.otp &&
        (normalizedMessage.contains('expired') ||
            normalizedMessage.contains('timeout'))) {
      return 'OTP expired. Request a new OTP and try again.';
    }

    if (flow == _AuthFlow.otp &&
        normalizedMessage.contains('session expired')) {
      return 'Session expired. Please restart login to continue.';
    }

    if (flow == _AuthFlow.otp &&
        normalizedMessage.contains('context is missing')) {
      return 'Session expired. Please restart login to continue.';
    }

    if (code == 401) {
      if (flow == _AuthFlow.login) {
        return 'Incorrect mobile number or OTP. Please try again.';
      }
      if (flow == _AuthFlow.otp) {
        return 'Invalid OTP. Please check the code and try again.';
      }
      return 'Your session expired. Please sign in again to continue.';
    }

    if (flow == _AuthFlow.login && code == 403) {
      return 'Your account setup is incomplete. Please complete registration before signing in.';
    }

    if (flow == _AuthFlow.login && code == 404) {
      return 'No account found for this mobile number. Please create an account first.';
    }

    if (code == 409) {
      return 'An account with this mobile number already exists. Please sign in instead.';
    }

    if (code == 429) {
      return 'Too many attempts detected. Please wait a minute and try again.';
    }

    if (code == 400 || code == 422) {
      if (normalizedMessage.contains('email')) {
        return 'Please enter a valid email address.';
      }
      if (normalizedMessage.contains('phone') ||
          normalizedMessage.contains('mobile')) {
        return 'Please enter a valid 10-digit mobile number.';
      }
      if (normalizedMessage.contains('password')) {
        return 'Please check OTP details and try again.';
      }
      return flow == _AuthFlow.register
          ? 'Some registration details are invalid. Please review your information.'
          : 'Some sign-in details are invalid. Please review and try again.';
    }

    if (code != null && code >= 500) {
      return 'Our servers are busy right now. Please try again in a few moments.';
    }

    if (normalizedMessage.contains('timed out') ||
        normalizedMessage.contains('network') ||
        normalizedMessage.contains('connection') ||
        normalizedMessage.contains('internet') ||
        normalizedMessage.contains('reach the server')) {
      return 'No stable internet connection detected. Please check your network and retry.';
    }

    if (normalizedMessage.contains('already exists')) {
      return 'An account with this mobile number already exists. Please sign in instead.';
    }

    if (normalizedMessage.contains('invalid') &&
        normalizedMessage.contains('credential')) {
      return 'Incorrect mobile number or OTP. Please try again.';
    }

    switch (flow) {
      case _AuthFlow.login:
        return 'Unable to sign you in at the moment. Please try again shortly.';
      case _AuthFlow.register:
        return 'Unable to create your account right now. Please try again shortly.';
      case _AuthFlow.otp:
        return 'Unable to verify your OTP right now. Please try again.';
    }
  }

  AppToastType _mapToastTypeForUi(
    ApiException error, {
    required _AuthFlow flow,
  }) {
    final code = error.statusCode;
    if (code == 429) {
      return AppToastType.rateLimit;
    }

    if (flow == _AuthFlow.otp && code == 401) {
      return AppToastType.invalidOtp;
    }

    if (code != null && code >= 500) {
      return AppToastType.warning;
    }

    return AppToastType.error;
  }
}

enum _AuthFlow { login, register, otp }
