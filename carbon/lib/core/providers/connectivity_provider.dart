import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

final connectivityProvider = StateProvider<ConnectivityStatus>((ref) {
  // Placeholder foundation; wire to connectivity_plus stream in functional phase.
  return ConnectivityStatus.online;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == ConnectivityStatus.online;
});
