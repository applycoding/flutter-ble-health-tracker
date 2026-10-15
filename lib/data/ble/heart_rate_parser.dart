import '../../domain/models.dart';

/// Parses and encodes the Bluetooth Heart Rate Measurement characteristic
/// (UUID 0x2A37). Flags follow the GATT specification:
/// bit 0 value format, bits 1–2 sensor contact, bit 3 energy expended, bit 4 RR.
HeartRateMeasurement parseHeartRateMeasurement(List<int> bytes) {
  if (bytes.isEmpty) {
    throw const FormatException('Heart Rate Measurement is empty.');
  }
  final flags = _byte(bytes, 0, 'flags');
  final wide = flags & 0x01 != 0;
  final contactSupported = flags & 0x02 != 0;
  final contactDetected = contactSupported && flags & 0x04 != 0;
  final hasEnergy = flags & 0x08 != 0;
  final hasRr = flags & 0x10 != 0;

  var index = 1;
  final bpm = wide ? _uint16(bytes, index, 'heart rate') : _byte(bytes, index, 'heart rate');
  index += wide ? 2 : 1;

  int? energy;
  if (hasEnergy) {
    energy = _uint16(bytes, index, 'energy expended');
    index += 2;
  }

  final rrIntervalsMs = <double>[];
  if (hasRr) {
    final remaining = bytes.length - index;
    if (remaining.isOdd) {
      throw const FormatException('RR-interval list is truncated.');
    }
    while (index < bytes.length) {
      final raw = _uint16(bytes, index, 'RR interval');
      rrIntervalsMs.add(raw * 1000 / 1024);
      index += 2;
    }
  } else if (index != bytes.length) {
    throw const FormatException('Unexpected trailing bytes in Heart Rate Measurement.');
  }

  return HeartRateMeasurement(
    bpm: bpm,
    sensorContactSupported: contactSupported,
    sensorContactDetected: contactDetected,
    energyExpendedKj: energy,
    rrIntervalsMs: rrIntervalsMs,
  );
}

List<int> encodeHeartRateMeasurement({
  required int bpm,
  bool sensorContactSupported = false,
  bool sensorContactDetected = false,
  int? energyExpendedKj,
  List<double> rrIntervalsMs = const [],
}) {
  if (bpm < 0 || bpm > 65535) {
    throw ArgumentError.value(bpm, 'bpm', 'must fit in uint16');
  }
  final wide = bpm > 255;
  var flags = 0;
  if (wide) flags |= 0x01;
  if (sensorContactSupported) {
    flags |= 0x02;
    if (sensorContactDetected) flags |= 0x04;
  }
  if (energyExpendedKj != null) {
    if (energyExpendedKj < 0 || energyExpendedKj > 65535) {
      throw ArgumentError.value(energyExpendedKj, 'energyExpendedKj', 'must fit in uint16');
    }
    flags |= 0x08;
  }
  if (rrIntervalsMs.isNotEmpty) flags |= 0x10;

  final bytes = <int>[flags];
  if (wide) {
    bytes
      ..add(bpm & 0xff)
      ..add((bpm >> 8) & 0xff);
  } else {
    bytes.add(bpm);
  }
  final energy = energyExpendedKj;
  if (energy != null) {
    bytes
      ..add(energy & 0xff)
      ..add((energy >> 8) & 0xff);
  }
  for (final intervalMs in rrIntervalsMs) {
    final raw = (intervalMs / 1000 * 1024).round();
    if (raw < 0 || raw > 65535) {
      throw ArgumentError.value(intervalMs, 'rrIntervalsMs', 'must fit in uint16');
    }
    bytes
      ..add(raw & 0xff)
      ..add((raw >> 8) & 0xff);
  }
  return bytes;
}

int _byte(List<int> bytes, int index, String field) {
  if (index >= bytes.length) {
    throw FormatException('Heart Rate Measurement is missing $field.');
  }
  final value = bytes[index];
  if (value < 0 || value > 255) {
    throw FormatException('Byte out of range in $field.');
  }
  return value;
}

int _uint16(List<int> bytes, int index, String field) {
  final low = _byte(bytes, index, field);
  final high = _byte(bytes, index + 1, field);
  return low | (high << 8);
}
