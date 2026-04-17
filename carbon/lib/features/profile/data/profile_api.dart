import 'package:carbon/features/worker/data/worker_api.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileApi {
  ProfileApi(this._workerApi);

  final WorkerApi _workerApi;

  Future<WorkerProfile> fetchProfile() async {
    return _workerApi.fetchProfile();
  }

  Future<WorkerStatus> fetchWorkerStatus() async {
    return _workerApi.fetchStatus();
  }
}

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.read(workerApiProvider));
});
