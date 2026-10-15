import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/domain/models/device_models.dart';
import 'package:pulsekeep/domain/parsing/heart_rate_zone.dart';

void main() {
  test('uses fixed demo bands', () {
    expect(zoneFor(89), HeartRateZone.resting);
    expect(zoneFor(90), HeartRateZone.easy);
    expect(zoneFor(109), HeartRateZone.easy);
    expect(zoneFor(110), HeartRateZone.moderate);
    expect(zoneFor(139), HeartRateZone.moderate);
    expect(zoneFor(140), HeartRateZone.hard);
    expect(zoneFor(169), HeartRateZone.hard);
    expect(zoneFor(170), HeartRateZone.peak);
    expect(zoneLabel(HeartRateZone.peak), 'Peak');
  });
}
