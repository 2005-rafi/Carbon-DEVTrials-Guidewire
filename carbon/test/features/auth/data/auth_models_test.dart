import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenResponse.fromDynamic', () {
    test('parses direct access and refresh tokens', () {
      final response = TokenResponse.fromDynamic(<String, dynamic>{
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'user_id': 'user-1',
        'token_type': 'bearer',
      });

      expect(response.accessToken, 'access-1');
      expect(response.refreshToken, 'refresh-1');
      expect(response.userId, 'user-1');
      expect(response.tokenType, 'bearer');
      expect(response.isValid, isTrue);
      expect(response.hasVerificationToken, isFalse);
    });

    test('parses verification token from nested data.token', () {
      final response = TokenResponse.fromDynamic(<String, dynamic>{
        'status': 'success',
        'data': <String, dynamic>{
          'verified': true,
          'token': 'verification-123',
        },
      });

      expect(response.verificationToken, 'verification-123');
      expect(response.hasVerificationToken, isTrue);
      expect(response.isValid, isFalse);
    });

    test('parses token payload from nested token map', () {
      final response = TokenResponse.fromDynamic(<String, dynamic>{
        'token': <String, dynamic>{
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'user_id': 'user-2',
          'token_type': 'bearer',
        },
      });

      expect(response.accessToken, 'access-2');
      expect(response.refreshToken, 'refresh-2');
      expect(response.userId, 'user-2');
      expect(response.isValid, isTrue);
    });

    test('parses new_access_token compatibility payload', () {
      final response = TokenResponse.fromDynamic(<String, dynamic>{
        'status': 'success',
        'data': <String, dynamic>{
          'new_access_token': 'access-compat',
          'refresh_token': 'refresh-compat',
          'user_id': 'user-compat',
        },
      });

      expect(response.accessToken, 'access-compat');
      expect(response.refreshToken, 'refresh-compat');
      expect(response.userId, 'user-compat');
      expect(response.isValid, isTrue);
    });

    test('returns empty for non-map payload', () {
      final response = TokenResponse.fromDynamic('invalid');

      expect(response, TokenResponse.empty);
    });
  });

  group('ValidateSessionResponse.fromDynamic', () {
    test('parses top-level valid status response', () {
      final response = ValidateSessionResponse.fromDynamic(<String, dynamic>{
        'status': 'valid',
        'scope': 'auth',
      });

      expect(response.isValid, isTrue);
      expect(response.scope, 'auth');
    });

    test('parses data.is_valid true envelope response', () {
      final response = ValidateSessionResponse.fromDynamic(<String, dynamic>{
        'status': 'success',
        'data': <String, dynamic>{'is_valid': true, 'user_id': 'user-3'},
      });

      expect(response.isValid, isTrue);
      expect(response.status, 'success');
      expect(response.userId, 'user-3');
    });

    test('honors explicit false validity from nested data', () {
      final response = ValidateSessionResponse.fromDynamic(<String, dynamic>{
        'status': 'success',
        'data': <String, dynamic>{'is_valid': false},
      });

      expect(response.isValid, isFalse);
    });

    test('parses string validity value from data', () {
      final response = ValidateSessionResponse.fromDynamic(<String, dynamic>{
        'data': <String, dynamic>{'valid': 'true'},
      });

      expect(response.isValid, isTrue);
    });
  });
}
