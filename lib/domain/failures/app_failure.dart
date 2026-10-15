/// Failures the UI can show without parsing plugin exceptions.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class BluetoothOffFailure extends AppFailure {
  const BluetoothOffFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

final class ConnectionFailure extends AppFailure {
  const ConnectionFailure(super.message);
}

/// The peripheral connected, but it does not expose Heart Rate Service 0x180D
/// or a notifiable Heart Rate Measurement characteristic (0x2A37).
final class HeartRateServiceMissing extends AppFailure {
  const HeartRateServiceMissing()
    : super(
        'This device does not expose a notifiable Heart Rate Measurement '
        'characteristic (0x2A37) on service 0x180D.',
      );
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}
