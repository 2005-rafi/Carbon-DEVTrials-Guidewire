import 'package:flutter_riverpod/flutter_riverpod.dart';

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
final authTokenProvider = StateProvider<String?>((ref) => null);
final refreshTokenProvider = StateProvider<String?>((ref) => null);
final authUserIdProvider = StateProvider<String?>((ref) => null);
final authVerificationTokenProvider = StateProvider<String?>((ref) => null);
final authPendingPhoneProvider = StateProvider<String?>((ref) => null);
final authPendingRegistrationAccessTokenProvider = StateProvider<String?>(
  (ref) => null,
);
final authPendingRegistrationRefreshTokenProvider = StateProvider<String?>(
  (ref) => null,
);
final authPendingRegistrationUserIdProvider = StateProvider<String?>(
  (ref) => null,
);
final authPendingRegistrationTokenTypeProvider = StateProvider<String?>(
  (ref) => null,
);

final pendingRegistrationSessionReadyProvider = Provider<bool>((ref) {
  final access = (ref.watch(authPendingRegistrationAccessTokenProvider) ?? '')
      .trim();
  final refresh = (ref.watch(authPendingRegistrationRefreshTokenProvider) ?? '')
      .trim();
  final userId = (ref.watch(authPendingRegistrationUserIdProvider) ?? '')
      .trim();
  return access.isNotEmpty && refresh.isNotEmpty && userId.isNotEmpty;
});

final profileFinalizationEligibleProvider = Provider<bool>((ref) {
  final verificationToken = (ref.watch(authVerificationTokenProvider) ?? '')
      .trim();
  final pendingPhone = (ref.watch(authPendingPhoneProvider) ?? '').trim();
  final verificationHandshakeReady =
      verificationToken.isNotEmpty && pendingPhone.isNotEmpty;
  final pendingSessionReady =
      ref.watch(pendingRegistrationSessionReadyProvider) &&
      pendingPhone.isNotEmpty;
  return verificationHandshakeReady || pendingSessionReady;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final raw = ref.watch(authUserIdProvider);
  final candidate = raw?.trim() ?? '';
  if (candidate.isEmpty) {
    return null;
  }

  const strictUserIdFormat = bool.fromEnvironment(
    'STRICT_AUTH_USER_ID_FORMAT',
    defaultValue: false,
  );
  if (strictUserIdFormat &&
      !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(candidate)) {
    return null;
  }

  return candidate;
});
