import 'models.dart';

/// BLE heart-rate source. Demo and live implementations share this port.
abstract class WearableClient {
  Stream<WearableStatus> get status;
  Stream<List<DiscoveredWearable>> get scanResults;
  Stream<HeartRateSample> get samples;

  Future<void> start();
  Future<void> stop();
  Future<void> connect(DiscoveredWearable device);
}

/// Cloud upload port. The app binds either Firestore or the in-memory mock.
abstract class HeartRateSyncClient {
  String get targetLabel;

  /// Returns one remote id per reading, in the same order.
  Future<List<String>> upload(List<HeartRateReading> readings);
}

abstract class HeartRateRepository {
  Stream<List<HeartRateReading>> watchAll({int limit = 300});
  Stream<int> watchPendingCount();
  Future<HeartRateReading> record(HeartRateSample sample);
  Future<SyncReport> syncPending();
}

/// Online/offline gate used by sync. Demo mode toggles this directly so the
/// queue can be shown without changing the host network.
abstract class NetworkGate {
  bool get isOnline;
  void setOnline(bool value);
}

/// Thrown when a sync client cannot upload. Subtypes stay inside the port
/// so the repository does not depend on HTTP or Firestore.
sealed class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class SyncNotConfiguredException extends SyncException {
  const SyncNotConfiguredException(super.message);
}

final class SyncTransportException extends SyncException {
  const SyncTransportException(super.message);
}
