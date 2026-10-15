import '../models/heart_rate_measurement.dart';

/// Decodes the Bluetooth Heart Rate Measurement characteristic (0x2A37).
///
/// Layout, from the Heart Rate Service specification:
/// - byte 0 flags: bit0 UINT16 heart rate, bits1-2 sensor contact,
///   bit3 energy expended present, bit4 RR-interval present
/// - heart rate: 1 or 2 little-endian bytes
/// - optional UINT16 energy expended, in kilojoules
/// - optional UINT16 RR-intervals, in units of 1/1024 second
///
/// Packets with a truncated field, or with trailing bytes the flags do not
/// account for, throw [FormatException].
final class HeartRateMeasurementParser {
  const HeartRateMeasurementParser();

  static const int _formatUint16 = 0x01;
  static const int _contactSupported = 0x02;
  static const int _contactDetected = 0x04;
  static const int _energyPresent = 0x08;
  static const int _rrPresent = 0x10;

  HeartRateMeasurement parse(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Heart Rate Measurement is empty.');
    }

    final flags = bytes[0];
    var index = 1;
    final wide = flags & _formatUint16 != 0;
    final bpmWidth = wide ? 2 : 1;
    if (bytes.length < index + bpmWidth) {
      throw FormatException(
        'Heart Rate Measurement truncated before BPM (${bytes.length} bytes).',
      );
    }
    final bpm = wide ? _uint16(bytes, index) : _uint8(bytes[index]);
    index += bpmWidth;

    final SensorContact contact;
    if (flags & _contactSupported == 0) {
      contact = SensorContact.notSupported;
    } else if (flags & _contactDetected == 0) {
      contact = SensorContact.notDetected;
    } else {
      contact = SensorContact.detected;
    }

    int? energy;
    if (flags & _energyPresent != 0) {
      if (bytes.length < index + 2) {
        throw const FormatException(
          'Heart Rate Measurement truncated before energy expended.',
        );
      }
      energy = _uint16(bytes, index);
      index += 2;
    }

    final rr = <int>[];
    if (flags & _rrPresent != 0) {
      if ((bytes.length - index).isOdd) {
        throw const FormatException(
          'Heart Rate Measurement has a dangling RR-interval byte.',
        );
      }
      while (index + 1 < bytes.length) {
        final raw = _uint16(bytes, index);
        rr.add((raw * 1000 / 1024).round());
        index += 2;
      }
    }

    if (index != bytes.length) {
      throw FormatException(
        'Heart Rate Measurement has ${bytes.length - index} unexpected trailing bytes.',
      );
    }

    return HeartRateMeasurement(
      bpm: bpm,
      sensorContact: contact,
      energyExpended: energy,
      rrIntervalsMs: List.unmodifiable(rr),
    );
  }

  int _uint8(int value) {
    if (value < 0 || value > 0xff) {
      throw FormatException('Byte out of range: $value');
    }
    return value;
  }

  int _uint16(List<int> bytes, int index) {
    return _uint8(bytes[index]) | (_uint8(bytes[index + 1]) << 8);
  }
}
