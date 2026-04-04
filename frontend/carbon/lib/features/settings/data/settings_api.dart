import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
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
  SettingsApi(this._dio);

  final Dio _dio;

  static const List<String> _settingsEndpointVariants = <String>[
    '/user/preferences',
    '/identity-service/user/preferences',
    '/notification-service/user/preferences',
  ];

  static const List<String> _updateSettingsEndpointVariants = <String>[
    '/user/update-settings',
    '/identity-service/user/update-settings',
    '/notification-service/user/update-settings',
  ];

  Future<SettingsData> fetchSettings() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _settingsEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.identityServiceBaseUrl,
          ApiConfig.notificationServiceBaseUrl,
        ],
      );

      final map = _extractSettingsMap(raw);
      if (map.isEmpty) {
        return SettingsData.fallback();
      }

      return SettingsData.fromMap(map);
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load settings right now.',
      );
    }
  }

  Future<void> updateSettings(SettingsData data) async {
    try {
      await _postWithFallback(
        endpointVariants: _updateSettingsEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.identityServiceBaseUrl,
          ApiConfig.notificationServiceBaseUrl,
        ],
        payload: data.toPayload(),
      );
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

  Future<dynamic> _getWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<dynamic> attempt(String url) async {
      if (attempted.contains(url)) {
        return null;
      }
      attempted.add(url);

      try {
        final response = await _dio.get<dynamic>(url);
        return response.data;
      } on DioException catch (error) {
        lastError = error;
        return null;
      }
    }

    for (final endpoint in endpointVariants) {
      final result = await attempt(endpoint);
      if (result != null) {
        return result;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        final result = await attempt('$baseUrl$endpoint');
        if (result != null) {
          return result;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to fetch settings.');
  }

  Future<void> _postWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
    required Map<String, dynamic> payload,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<bool> attempt(String url) async {
      if (attempted.contains(url)) {
        return false;
      }
      attempted.add(url);

      try {
        await _dio.post<dynamic>(url, data: payload);
        return true;
      } on DioException catch (error) {
        lastError = error;
        return false;
      }
    }

    for (final endpoint in endpointVariants) {
      if (await attempt(endpoint)) {
        return;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        if (await attempt('$baseUrl$endpoint')) {
          return;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to save settings.');
  }

  Map<String, dynamic> _extractSettingsMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final candidates = <dynamic>[
        raw['data'],
        raw['settings'],
        raw['preferences'],
      ];
      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }
      return raw;
    }

    return <String, dynamic>{};
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    final serverMessage = _extractServerMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Settings request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to backend. Check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to access settings.',
            statusCode: HttpStatus.unauthorized,
          );
        }
        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Settings request canceled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(serverMessage ?? genericMessage);
    }
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final candidates = <dynamic>[
      responseData['message'],
      responseData['detail'],
      responseData['description'],
      responseData['error'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      if (candidate is Map<String, dynamic>) {
        final nested = candidate['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }

    return null;
  }
}

final settingsApiProvider = Provider<SettingsApi>((ref) {
  return SettingsApi(ref.read(apiClientProvider));
});
