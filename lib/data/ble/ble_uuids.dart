import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Standard Heart Rate Service identifiers (16-bit UUID form).
class BleUuids {
  static final heartRateService = Guid('180D');
  static final heartRateMeasurement = Guid('2A37');
}
