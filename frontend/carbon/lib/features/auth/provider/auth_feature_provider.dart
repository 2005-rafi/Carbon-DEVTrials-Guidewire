import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/auth/data/auth_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLoadingProvider = StateProvider<bool>((ref) => false);

final authErrorProvider = StateProvider<String?>((ref) => null);

final authActionProvider = Provider<AuthAction>((ref) {
  return AuthAction(ref);
});

class AuthAction {
  AuthAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }

  Future<bool> login(String phoneNumber, String password) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref
          .read(authApiProvider)
          .login(phoneNumber: phoneNumber, password: password);
      return true;
    } on ApiException catch (error) {
      developer.log('Login failed: ${error.toString()}', name: 'AuthAction');
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.login,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Sign-in is temporarily unavailable. Please try again in a moment.';
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref
          .read(authApiProvider)
          .register(
            fullName: fullName,
            phoneNumber: phoneNumber,
            password: password,
          );
      return true;
    } on ApiException catch (error) {
      developer.log(
        'Registration failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.register,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Account creation is temporarily unavailable. Please try again shortly.';
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref.read(authApiProvider).verifyOtp(otp: otp);
      return true;
    } on ApiException catch (error) {
      developer.log(
        'OTP verification failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'OTP verification failed. Please try again.';
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> resendOtp() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;
    try {
      await _ref.read(authApiProvider).resendOtp();
      return true;
    } on ApiException catch (error) {
      developer.log(
        'Resend OTP failed: ${error.toString()}',
        name: 'AuthAction',
      );
      _ref.read(authErrorProvider.notifier).state = _mapAuthErrorForUi(
        error,
        flow: _AuthFlow.otp,
      );
      return false;
    } catch (_) {
      _ref.read(authErrorProvider.notifier).state =
          'Unable to resend OTP right now. Please try again.';
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  String _mapAuthErrorForUi(ApiException error, {required _AuthFlow flow}) {
    final normalizedMessage = error.message.trim().toLowerCase();
    final code = error.statusCode;

    if (code == 401) {
      if (flow == _AuthFlow.login) {
        return 'Incorrect mobile number or password. Please try again.';
      }
      return 'Your session expired. Please sign in again to continue.';
    }

    if (code == 409) {
      return 'An account with this mobile number already exists. Please sign in instead.';
    }

    if (code == 429) {
      return 'Too many attempts detected. Please wait a minute and try again.';
    }

    if (code == 400 || code == 422) {
      if (normalizedMessage.contains('phone') ||
          normalizedMessage.contains('mobile')) {
        return 'Please enter a valid Indian mobile number in +91 format.';
      }
      if (normalizedMessage.contains('password')) {
        if (flow == _AuthFlow.register) {
          return 'Password is too weak. Use at least 6 characters with a strong mix.';
        }
        return 'Please check your password and try again.';
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
      return 'Incorrect mobile number or password. Please try again.';
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
}

enum _AuthFlow { login, register, otp }
