import 'package:carbon/features/profile/data/worker_models.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(workerFetchErrorProvider);
});

final profileActionErrorProvider = Provider<String?>((ref) {
  return ref.watch(workerActionErrorProvider);
});

final profileActionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(workerActionLoadingProvider);
});

class ProfileViewData {
  const ProfileViewData({
    required this.profile,
    required this.status,
    required this.isStale,
    required this.lastSyncedAt,
  });

  final WorkerProfile profile;
  final WorkerStatus status;
  final bool isStale;
  final DateTime? lastSyncedAt;

  const ProfileViewData.fallback()
    : profile = const WorkerProfile.empty(),
      status = const WorkerStatus.unknown(),
      isStale = true,
      lastSyncedAt = null;
}

final profileAsyncProvider = FutureProvider<ProfileViewData>((ref) async {
  final snapshot = await ref.watch(workerSnapshotAsyncProvider.future);
  return ProfileViewData(
    profile: snapshot.profile,
    status: snapshot.status,
    isStale: snapshot.isStale,
    lastSyncedAt: snapshot.lastSyncedAt,
  );
});

final profileProvider = Provider<ProfileViewData>((ref) {
  final cached = ref.watch(workerSnapshotProvider);

  return ref
      .watch(profileAsyncProvider)
      .maybeWhen(
        data: (profile) => profile,
        orElse: () => ProfileViewData(
          profile: cached.profile,
          status: cached.status,
          isStale: cached.isStale,
          lastSyncedAt: cached.lastSyncedAt,
        ),
      );
});

final profileActionProvider = Provider<ProfileAction>((ref) {
  return ProfileAction(ref);
});

class ProfileAction {
  ProfileAction(this._ref);

  final Ref _ref;

  Future<void> refreshProfile() async {
    await _ref.read(workerActionProvider).refresh();
  }

  void clearActionError() {
    _ref.read(workerActionProvider).clearActionError();
  }

  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String zone,
    String? email,
  }) async {
    return _ref
        .read(workerActionProvider)
        .updateProfile(name: name, phone: phone, zone: zone, email: email);
  }
}
