import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkerApi {
  WorkerApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<WorkerProfile> fetchProfile() async {
    final userId = _requireUserId();

    final response = await _withRetry<dynamic>(
      actionName: 'fetch_profile',
      request: () {
        return _dio.get<dynamic>(
          ApiEndpoints.workerByUserId(userId),
          options: _requestOptions(actionName: 'fetch_profile'),
        );
      },
      genericMessage: 'Unable to load profile right now.',
    );

    final profile = WorkerProfile.fromMap(_extractDataMap(response.data));
    _logWorkerEvent('profile_fetch_success', <String, dynamic>{
      'user_id': userId,
      'has_identity': profile.hasIdentity,
      'is_incomplete': profile.isIncomplete,
    });
    return profile;
  }

  Future<WorkerStatus> fetchStatus() async {
    final userId = _requireUserId();

    final response = await _withRetry<dynamic>(
      actionName: 'fetch_status',
      request: () {
        return _dio.get<dynamic>(
          ApiEndpoints.workerStatusByUserId(userId),
          options: _requestOptions(actionName: 'fetch_status'),
        );
      },
      genericMessage: 'Unable to load worker status right now.',
    );

    final status = WorkerStatus.fromMap(_extractDataMap(response.data));
    _logWorkerEvent('status_fetch_success', <String, dynamic>{
      'user_id': userId,
      'is_active': status.isActive,
      'eligible_for_claim': status.eligibleForClaim,
    });
    return status;
  }

  Future<WorkerProfile> updateProfile({
    required WorkerProfileUpdateRequest request,
    String? accessToken,
  }) async {
    request.validate();

    final payloadVariants = request.toPayloadVariants();
    final headers = <String, dynamic>{
      Headers.contentTypeHeader: Headers.jsonContentType,
      if (accessToken != null && accessToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${accessToken.trim()}',
    };

    Response<dynamic>? updateResponse;
    ApiException? lastFriendly;

    for (var index = 0; index < payloadVariants.length; index++) {
      final payload = payloadVariants[index];
      final hasNext = index < payloadVariants.length - 1;

      try {
        updateResponse = await _withRetry<dynamic>(
          actionName: 'update_profile',
          request: () {
            return _dio.post<dynamic>(
              ApiEndpoints.workerProfile,
              data: payload,
              options: _requestOptions(
                actionName: 'update_profile',
                headers: headers,
              ),
            );
          },
          genericMessage: 'Unable to update profile right now.',
        );
        break;
      } on ApiException catch (error) {
        lastFriendly = error;
        if (hasNext && _shouldRetryWithPayloadVariant(error)) {
          developer.log(
            'Retrying worker profile update with compatibility payload variant.',
            name: 'WorkerApi',
          );
          continue;
        }
        rethrow;
      }
    }

    if (updateResponse == null) {
      throw lastFriendly ??
          const ApiException('Unable to update profile right now.');
    }

    final responseMap = _extractDataMap(updateResponse.data);
    final fromResponse = WorkerProfile.fromMap(responseMap);
    if (fromResponse.hasIdentity) {
      _logWorkerEvent('profile_update_success', <String, dynamic>{
        'user_id': request.userId,
      });
      return fromResponse;
    }

    // Reconcile using GET when update response is non-deterministic.
    final reconciled = await fetchProfile();
    _logWorkerEvent('profile_update_success', <String, dynamic>{
      'user_id': request.userId,
      'reconciled': true,
    });
    return reconciled;
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

  Future<Response<T>> _withRetry<T>({
    required String actionName,
    required Future<Response<T>> Function() request,
    required String genericMessage,
  }) async {
    const delays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
    ];

    DioException? lastError;
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return await request();
      } on DioException catch (error) {
        lastError = error;
        if (attempt >= delays.length || !_isTransient(error)) {
          _logWorkerApiFailure(actionName: actionName, error: error);
          throw _toFriendlyApiException(error, genericMessage: genericMessage);
        }

        await Future<void>.delayed(delays[attempt]);
      }
    }

    if (lastError != null) {
      _logWorkerApiFailure(actionName: actionName, error: lastError);
      throw _toFriendlyApiException(lastError, genericMessage: genericMessage);
    }

    throw ApiException(genericMessage);
  }

  bool _isTransient(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final status = error.response?.statusCode;
    return status == HttpStatus.requestTimeout ||
        status == HttpStatus.tooManyRequests ||
        status == HttpStatus.internalServerError ||
        status == HttpStatus.badGateway ||
        status == HttpStatus.serviceUnavailable ||
        status == HttpStatus.gatewayTimeout;
  }

  bool _shouldRetryWithPayloadVariant(ApiException error) {
    final code = error.statusCode;
    if (code != HttpStatus.badRequest &&
        code != HttpStatus.unprocessableEntity) {
      return false;
    }

    final message = error.message.trim().toLowerCase();
    if (message.isEmpty) {
      return true;
    }

    const hints = <String>[
      'field required',
      'missing',
      'validation',
      'phone',
      'phone_number',
      'full_name',
      'unexpected',
      'extra fields',
    ];

    return hints.any(message.contains);
  }

  Options _requestOptions({
    required String actionName,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      headers: <String, dynamic>{
        'X-Correlation-ID': _correlationId(actionName),
        ...?headers,
      },
    );
  }

  String _correlationId(String actionName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = Random().nextInt(0xFFFFFF).toRadixString(16);
    return 'worker-$actionName-$timestamp-$randomPart';
  }

  Map<String, dynamic> _extractDataMap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    final nestedValue = data['value'];
    if (nestedValue is Map<String, dynamic>) {
      return nestedValue;
    }

    return data;
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in again to continue.',
      forbiddenMessage: 'You are not allowed to access this worker profile.',
      notFoundMessage: 'Worker profile was not found for this account.',
      validationMessage:
          'Some profile fields are invalid. Please review and retry.',
      serverMessage:
          'Worker service is temporarily unavailable. Please retry shortly.',
    );
  }

  void _logWorkerApiFailure({
    required String actionName,
    required DioException error,
  }) {
    final status = error.response?.statusCode;
    _logWorkerEvent('worker_api_error', <String, dynamic>{
      'action': actionName,
      'status_code': status,
      'path': error.requestOptions.path,
    });
  }

  void _logWorkerEvent(String event, Map<String, dynamic> data) {
    final redacted = <String, dynamic>{...data};
    if (redacted.containsKey('phone')) {
      redacted['phone'] = '***';
    }
    if (redacted.containsKey('email')) {
      redacted['email'] = '***';
    }

    developer.log('event=$event payload=$redacted', name: 'WorkerApi');
  }
}

final workerApiProvider = Provider<WorkerApi>((ref) {
  return WorkerApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
