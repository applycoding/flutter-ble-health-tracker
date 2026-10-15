import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/ports.dart';

final class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    return _isOnline(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> watch() async* {
    yield await isOnline;
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
