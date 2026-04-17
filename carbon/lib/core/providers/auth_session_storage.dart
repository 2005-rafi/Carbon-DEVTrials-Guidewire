import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionData {
  const AuthSessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;

  bool get isValid =>
      accessToken.trim().isNotEmpty &&
      refreshToken.trim().isNotEmpty &&
      userId.trim().isNotEmpty;
}

class AuthSessionStorage {
  const AuthSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _userIdKey = 'auth.user_id';
  static const String _migratedFlagKey = 'auth.secure_storage_migrated';
  static bool _migrationCheckedInRuntime = false;

  Future<void> save(AuthSessionData session) async {
    await _migrateLegacySessionIfRequired();
    await Future.wait(<Future<void>>[
      _secureStorage.write(key: _accessTokenKey, value: session.accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: session.refreshToken),
      _secureStorage.write(key: _userIdKey, value: session.userId),
    ]);
  }

  Future<AuthSessionData?> read() async {
    await _migrateLegacySessionIfRequired();
    final accessToken =
        (await _secureStorage.read(key: _accessTokenKey))?.trim() ?? '';
    final refreshToken =
        (await _secureStorage.read(key: _refreshTokenKey))?.trim() ?? '';
    final userId = (await _secureStorage.read(key: _userIdKey))?.trim() ?? '';

    final session = AuthSessionData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );

    return session.isValid ? session : null;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<void>>[
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
    ]);

    await Future.wait(<Future<bool>>[
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userIdKey),
    ]);
  }

  Future<void> _migrateLegacySessionIfRequired() async {
    if (_migrationCheckedInRuntime) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_migratedFlagKey) ?? false;
    if (migrated) {
      _migrationCheckedInRuntime = true;
      return;
    }

    final legacyAccessToken = prefs.getString(_accessTokenKey)?.trim() ?? '';
    final legacyRefreshToken = prefs.getString(_refreshTokenKey)?.trim() ?? '';
    final legacyUserId = prefs.getString(_userIdKey)?.trim() ?? '';

    if (legacyAccessToken.isNotEmpty &&
        legacyRefreshToken.isNotEmpty &&
        legacyUserId.isNotEmpty) {
      await Future.wait(<Future<void>>[
        _secureStorage.write(key: _accessTokenKey, value: legacyAccessToken),
        _secureStorage.write(key: _refreshTokenKey, value: legacyRefreshToken),
        _secureStorage.write(key: _userIdKey, value: legacyUserId),
      ]);
    }

    await Future.wait(<Future<bool>>[
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userIdKey),
    ]);

    await prefs.setBool(_migratedFlagKey, true);
    _migrationCheckedInRuntime = true;
  }
}

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return const AuthSessionStorage();
});
