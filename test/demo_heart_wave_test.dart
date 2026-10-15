import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/data/ble/demo_heart_wave.dart';
import 'package:pulse_ledger/data/ble/mock_wearable_client.dart';
import 'package:pulse_ledger/domain/models.dart';

void main() {
  test('demo packets stay inside a wearable range and carry RR data', () {
    final wave = DemoHeartWave(seed: 4);
    final beats = [for (var i = 0; i < 24; i++) wave.next()];
    expect(beats.map((beat) => beat.bpm), everyElement(inInclusiveRange(54, 156)));
    expect(beats.first.sensorContactDetected, isTrue);
    expect(beats.first.rrIntervalsMs, hasLength(2));
    expect(beats.first.energyExpendedKj, isNotNull);
  });

  test('mock strap emits parsed demo measurements and stops cleanly', () async {
    final client = MockWearableClient(interval: const Duration(milliseconds: 30), seed: 2);
    final samples = <HeartRateSample>[];
    final subscription = client.samples.listen(samples.add);
    await client.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await client.stop();
    final count = samples.length;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();

    expect(count, greaterThan(1));
    expect(samples, hasLength(count));
    expect(samples.first.deviceId, MockWearableClient.deviceId);
    expect(samples.first.deviceName, MockWearableClient.deviceName);
    expect(samples.first.source, ReadingSource.demo);
    expect(samples.first.bpm, inInclusiveRange(54, 156));
  });
}
