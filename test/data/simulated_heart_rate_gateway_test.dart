import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/simulator/simulated_heart_rate_gateway.dart';
import 'package:pulsekeep/domain/models/device_models.dart';

void main() {
  test('emits a resting trace and eases toward a run', () async {
    final gateway = SimulatedHeartRateGateway(
      random: Random(1),
      interval: const Duration(milliseconds: 15),
      replayCount: 4,
    );
    final bpms = <int>[];
    final sub = gateway.watchMeasurements().listen((m) => bpms.add(m.bpm));
    final devices = gateway.watchDevices();

    expect(await devices.first, [SimulatedHeartRateGateway.device]);
    await gateway.connect(SimulatedHeartRateGateway.device);
    expect(bpms, hasLength(4));
    for (final bpm in bpms) {
      expect(bpm, inInclusiveRange(42, 196));
    }
    expect(bpms.last, lessThan(90));

    gateway.setActivity(ActivityProfile.run);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(bpms.last, greaterThan(130));

    await gateway.disconnect();
    final count = bpms.length;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(bpms, hasLength(count));
    await sub.cancel();
    await gateway.dispose();
  });
}
