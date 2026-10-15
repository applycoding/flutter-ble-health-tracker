import '../../domain/models/heart_rate_reading.dart';
import '../../domain/ports.dart';

final class UnconfiguredHeartRateRemote implements HeartRateRemote {
  const UnconfiguredHeartRateRemote({required this.statusDetail});

  @override
  final String statusDetail;

  @override
  bool get isConfigured => false;

  @override
  Future<void> push(List<HeartRateReading> readings) async {}
}
