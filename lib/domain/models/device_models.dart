enum DeviceKind { simulator, ble }

enum Transport { simulator, bluetooth }

/// Coarse demo bands. They are not personalised training zones.
enum HeartRateZone { resting, easy, moderate, hard, peak }

enum ActivityProfile { rest, walk, run }

enum RadioStatus { unknown, on, off, unauthorized, unsupported }

final class HeartRateDevice {
  const HeartRateDevice({
    required this.id,
    required this.name,
    required this.kind,
    this.rssi,
  });

  final String id;
  final String name;
  final DeviceKind kind;
  final int? rssi;
}

sealed class LinkStatus {
  const LinkStatus();
}

final class LinkIdle extends LinkStatus {
  const LinkIdle();
}

final class LinkConnecting extends LinkStatus {
  const LinkConnecting();
}

final class LinkLive extends LinkStatus {
  const LinkLive();
}

final class LinkDisconnected extends LinkStatus {
  const LinkDisconnected();
}

final class LinkFailed extends LinkStatus {
  const LinkFailed(this.message);

  final String message;
}
