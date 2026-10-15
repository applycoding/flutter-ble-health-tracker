import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/data/ble/heart_rate_parser.dart';

void main() {
  test('parses an 8-bit heart rate', () {
    final measurement = parseHeartRateMeasurement([0x00, 72]);
    expect(measurement.bpm, 72);
    expect(measurement.sensorContactSupported, isFalse);
    expect(measurement.sensorContactDetected, isFalse);
    expect(measurement.energyExpendedKj, isNull);
    expect(measurement.rrIntervalsMs, isEmpty);
  });

  test('parses sensor contact only when the feature is supported', () {
    final supported = parseHeartRateMeasurement([0x06, 60]);
    expect(supported.sensorContactSupported, isTrue);
    expect(supported.sensorContactDetected, isTrue);
    expect(supported.bpm, 60);

    final reserved = parseHeartRateMeasurement([0x04, 50]);
    expect(reserved.sensorContactSupported, isFalse);
    expect(reserved.sensorContactDetected, isFalse);
    expect(reserved.bpm, 50);
  });

  test('parses a 16-bit heart rate', () {
    final measurement = parseHeartRateMeasurement([0x01, 0x2C, 0x01]);
    expect(measurement.bpm, 300);
  });

  test('parses energy expended in kilojoules', () {
    final measurement = parseHeartRateMeasurement([0x08, 80, 0x01, 0x02]);
    expect(measurement.bpm, 80);
    expect(measurement.energyExpendedKj, 513);
  });

  test('converts RR intervals from 1/1024 second units', () {
    final measurement = parseHeartRateMeasurement([0x10, 60, 0x00, 0x04]);
    expect(measurement.bpm, 60);
    expect(measurement.rrIntervalsMs, hasLength(1));
    expect(measurement.rrIntervalsMs.single, closeTo(1000, 0.001));
  });

  test('parses contact, energy, and RR together', () {
    final measurement = parseHeartRateMeasurement([0x1E, 70, 0x01, 0x00, 0x00, 0x04]);
    expect(measurement.bpm, 70);
    expect(measurement.sensorContactDetected, isTrue);
    expect(measurement.energyExpendedKj, 1);
    expect(measurement.rrIntervalsMs.single, closeTo(1000, 0.001));
  });

  test('rejects malformed packets', () {
    expect(() => parseHeartRateMeasurement(const []), throwsFormatException);
    expect(() => parseHeartRateMeasurement([0x01, 0x2C]), throwsFormatException);
    expect(() => parseHeartRateMeasurement([0x10, 60, 0x00]), throwsFormatException);
    expect(() => parseHeartRateMeasurement([0x00, 60, 0x01]), throwsFormatException);
  });

  test('round-trips a wide measurement through the encoder', () {
    final bytes = encodeHeartRateMeasurement(
      bpm: 280,
      sensorContactSupported: true,
      sensorContactDetected: true,
      energyExpendedKj: 12,
      rrIntervalsMs: const [800, 812.5],
    );
    final measurement = parseHeartRateMeasurement(bytes);
    expect(measurement.bpm, 280);
    expect(measurement.sensorContactSupported, isTrue);
    expect(measurement.sensorContactDetected, isTrue);
    expect(measurement.energyExpendedKj, 12);
    expect(measurement.rrIntervalsMs[0], closeTo(800, 1));
    expect(measurement.rrIntervalsMs[1], closeTo(812.5, 1));
  });
}
