import '../domain/ports.dart';

class ManualNetworkGate implements NetworkGate {
  ManualNetworkGate({this._online = true});

  bool _online;

  @override
  bool get isOnline => _online;

  @override
  void setOnline(bool value) {
    _online = value;
  }
}
