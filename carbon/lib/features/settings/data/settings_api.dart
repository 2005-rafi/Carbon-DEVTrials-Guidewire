import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/features/worker/data/worker_api.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsData {
  const SettingsData({
    required this.profileName,
    required this.email,
    required this.phone,
    required this.notificationsEnabled,
    required this.darkTheme,
    required this.autoSync,
    required this.language,
    required this.themePreference,
    required this.appVersion,
  });

  final String profileName;
  final String email;
  final String phone;
  final bool notificationsEnabled;
  final bool darkTheme;
  final bool autoSync;
  final String language;
  final String themePreference;
  final String appVersion;

  factory SettingsData.fromMap(Map<String, dynamic> map) {
    return SettingsData(
      profileName: _readString(map, <String>[
        'name',
        'profile_name',
        'full_name',
      ], fallback: 'Carbon User'),
      email: _readString(map, <String>[
        'email',
        'mail',
      ], fallback: 'user@carbon.app'),
      phone: _readString(map, <String>[
        'phone',
        'mobile',
        'phone_number',
      ], fallback: '+91 90000 00000'),
      notificationsEnabled: _readBool(map, <String>[
        'notificationsEnabled',
        'notifications_enabled',
      ], fallback: true),
      darkTheme: _readBool(map, <String>[
        'darkTheme',
        'dark_theme',
      ], fallback: false),
      autoSync: _readBool(map, <String>[
        'autoSync',
        'auto_sync',
      ], fallback: true),
      language: _readString(map, <String>[
        'language',
        'locale',
      ], fallback: 'English'),
      themePreference: _readString(map, <String>[
        'themePreference',
        'theme_preference',
      ], fallback: 'System'),
      appVersion: _readString(map, <String>[
        'version',
        'app_version',
      ], fallback: '0.1.0'),
    );
  }

  static SettingsData fallback() {
    return const SettingsData(
      profileName: 'Carbon User',
      email: 'user@carbon.app',
      phone: '+91 90000 00000',
      notificationsEnabled: true,
      darkTheme: false,
      autoSync: true,
      language: 'English',
      themePreference: 'System',
      appVersion: '0.1.0',
    );
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'name': profileName,
      'email': email,
      'phone': phone,
      'notifications_enabled': notificationsEnabled,
      'dark_theme': darkTheme,
      'auto_sync': autoSync,
      'language': language,
      'theme_preference': themePreference,
    };
  }

  static bool _readBool(
    Map<String, dynamic> source,
    List<String> keys, {
    required bool fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final cleaned = value.trim().toLowerCase();
        if (cleaned == 'true' || cleaned == '1') {
          return true;
        }
        if (cleaned == 'false' || cleaned == '0') {
          return false;
        }
      }
      if (value is num) {
        return value != 0;
      }
    }
    return fallback;
  }

  static String _readString(
    Map<String, dynamic> source,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }
}

class SettingsApi {
  SettingsApi(this._workerApi, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final WorkerApi _workerApi;
  final String? Function()? _userIdProvider;

  Future<SettingsData> fetchSettings() async {
    try {
      final profile = await _workerApi.fetchProfile();
      return SettingsData(
        profileName: profile.name.trim().isEmpty ? 'Carbon User' : profile.name,
        email: profile.email.trim().isEmpty ? 'user@carbon.app' : profile.email,
        phone: profile.phone.trim().isEmpty ? '+91 90000 00000' : profile.phone,
        notificationsEnabled: true,
        darkTheme: false,
        autoSync: true,
        language: 'English',
        themePreference: 'System',
        appVersion: '0.1.0',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load settings right now.',
      );
    }
  }

  Future<void> updateSettings(SettingsData data) async {
    final userId = _requireUserId();

    try {
      final currentProfile = await _workerApi.fetchProfile();
      final request = WorkerProfileUpdateRequest.fromRaw(
        userId: userId,
        name: data.profileName,
        phone: data.phone,
        zone: currentProfile.zone,
        email: data.email,
      );

      await _workerApi.updateProfile(request: request);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to save settings right now.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchUserSettings() async {
    final data = await fetchSettings();
    return data.toPayload();
  }

  String _requireUserId() {
    final candidate = _userIdProvider?.call()?.trim();
    if (candidate == null || candidate.isEmpty) {
      throw const ApiException(
        'User identity is missing. Please sign in again.',
        statusCode: HttpStatus.unauthorized,
      );
    }
    return candidate;
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in to access settings.',
      validationMessage:
          'Some settings values are invalid. Please review and retry.',
    );
  }
}

final settingsApiProvider = Provider<SettingsApi>((ref) {
  return SettingsApi(
    ref.read(workerApiProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
