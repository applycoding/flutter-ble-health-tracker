import '../../domain/models.dart';
import '../../domain/ports.dart';

/// In-memory stand-in for Firestore. Uploads live for the process only;
/// the on-device Drift log remains the source of truth.
class MockSyncClient implements HeartRateSyncClient {
  MockSyncClient({this.latency = const Duration(milliseconds: 180)});

  Duration latency;
  var failNext = false;
  final List<HeartRateReading> uploaded = [];

  @override
  String get targetLabel => 'mock cloud';

  @override
  Future<List<String>> upload(List<HeartRateReading> readings) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failNext) {
      failNext = false;
      throw const SyncTransportException('Mock sync rejected the batch.');
    }
    uploaded.addAll(readings);
    return [
      for (final reading in readings)
        'mock-${reading.id ?? reading.recordedAt.microsecondsSinceEpoch}',
    ];
  }
}
