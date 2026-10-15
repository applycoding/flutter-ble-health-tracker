import 'dart:math';

import '../domain/ports.dart';

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class TimeReadingIdFactory implements ReadingIdFactory {
  TimeReadingIdFactory({Random? random}) : _random = random ?? Random();

  final Random _random;
  var _sequence = 0;

  @override
  String next() {
    _sequence += 1;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
      16,
    );
    final salt = _random.nextInt(1 << 32).toRadixString(16);
    return '$micros-$salt-$_sequence';
  }
}
