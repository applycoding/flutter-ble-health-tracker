import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/domain/models/heart_rate_measurement.dart';
import 'package:pulsekeep/domain/parsing/heart_rate_measurement_parser.dart';

void main() {
  const parser = HeartRateMeasurementParser();

  test('parses an 8-bit heart rate', () {
    final measurement = parser.parse([0x00, 60]);
    expect(measurement.bpm, 60);
    expect(measurement.sensorContact, SensorContact.notSupported);
    expect(measurement.energyExpended, isNull);
    expect(measurement.rrIntervalsMs, isEmpty);
  });

  test('parses a 16-bit heart rate and sensor contact', () {
    // flags: UINT16 | contact supported | contact detected
    final measurement = parser.parse([0x07, 0x9C, 0x01]);
    expect(measurement.bpm, 412);
    expect(measurement.sensorContact, SensorContact.detected);
  });

  test('reports contact supported but not detected', () {
    final measurement = parser.parse([0x02, 70]);
    expect(measurement.sensorContact, SensorContact.notDetected);
    expect(measurement.bpm, 70);
  });

  test('parses energy expended and RR-intervals', () {
    // flags: energy | RR. bpm 80. energy 200. RR raw 1024 = 1000 ms, raw 512 = 500 ms.
    final measurement = parser.parse([
      0x18,
      80,
      0xC8,
      0x00,
      0x00,
      0x04,
      0x00,
      0x02,
    ]);
    expect(measurement.bpm, 80);
    expect(measurement.energyExpended, 200);
    expect(measurement.rrIntervalsMs, [1000, 500]);
  });

  test('rounds a 1/1024-second RR unit to the nearest millisecond', () {
    final measurement = parser.parse([0x10, 60, 0x01, 0x00]);
    expect(measurement.rrIntervalsMs, [1]);
  });

  test('ignores reserved flag bits', () {
    final measurement = parser.parse([0xE0, 55]);
    expect(measurement.bpm, 55);
  });

  test('rejects an empty packet', () {
    expect(() => parser.parse(const []), throwsFormatException);
  });

  test('rejects a truncated 16-bit heart rate', () {
    expect(() => parser.parse([0x01]), throwsFormatException);
  });

  test('rejects truncated energy expended', () {
    expect(() => parser.parse([0x08, 70, 0x01]), throwsFormatException);
  });

  test('rejects a dangling RR byte', () {
    expect(() => parser.parse([0x10, 70, 0x01]), throwsFormatException);
  });

  test('rejects unexpected trailing bytes', () {
    expect(() => parser.parse([0x00, 70, 0x00]), throwsFormatException);
  });
}
