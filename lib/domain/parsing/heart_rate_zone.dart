import '../models/device_models.dart';

/// Fixed demo bands. A real training app would use age or a measured max HR.
HeartRateZone zoneFor(int bpm) {
  if (bpm < 90) return HeartRateZone.resting;
  if (bpm < 110) return HeartRateZone.easy;
  if (bpm < 140) return HeartRateZone.moderate;
  if (bpm < 170) return HeartRateZone.hard;
  return HeartRateZone.peak;
}

String zoneLabel(HeartRateZone zone) {
  switch (zone) {
    case HeartRateZone.resting:
      return 'Resting';
    case HeartRateZone.easy:
      return 'Easy';
    case HeartRateZone.moderate:
      return 'Moderate';
    case HeartRateZone.hard:
      return 'Hard';
    case HeartRateZone.peak:
      return 'Peak';
  }
}
