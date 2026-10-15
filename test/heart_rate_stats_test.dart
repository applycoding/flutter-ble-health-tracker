import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/domain/models.dart';

import 'support/samples.dart';

void main() {
  test('stats are empty until a reading exists', () {
    expect(HeartRateStats.from(const []), HeartRateStats.empty);
  });

  test('stats use the stored beats, not a live smoothing window', () {
    final stats = HeartRateStats.from([
      reading(bpm: 60),
      reading(bpm: 80),
      reading(bpm: 71),
    ]);
    expect(stats.min, 60);
    expect(stats.max, 80);
    expect(stats.average, 70);
    expect(stats.count, 3);
  });

  test('groups newest-first readings into local days', () {
    final groups = groupReadingsByDay([
      reading(bpm: 90, recordedAt: DateTime(2026, 10, 15, 17)),
      reading(bpm: 70, recordedAt: DateTime(2026, 10, 15, 8)),
      reading(bpm: 64, recordedAt: DateTime(2026, 10, 14, 21)),
    ]);
    expect(groups, hasLength(2));
    expect(groups.first.day, DateTime(2026, 10, 15));
    expect(groups.first.readings.map((item) => item.bpm), [90, 70]);
    expect(groups.last.day, DateTime(2026, 10, 14));
    expect(groups.last.readings.single.bpm, 64);
  });
}
