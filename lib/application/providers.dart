import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../data/ble/flutter_blue_wearable_client.dart';
import '../data/ble/mock_wearable_client.dart';
import '../data/heart_rate_repository_impl.dart';
import '../data/local/app_database.dart';
import '../data/manual_network_gate.dart';
import '../data/remote/sync_client_factory.dart';
import '../domain/models.dart';
import '../domain/ports.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.environment);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final networkGateProvider = Provider<NetworkGate>((ref) => ManualNetworkGate());

final syncClientProvider = Provider<HeartRateSyncClient>((ref) {
  return createSyncClient(
    config: ref.watch(appConfigProvider),
    httpClient: ref.watch(httpClientProvider),
  );
});

final heartRateRepositoryProvider = Provider<HeartRateRepository>((ref) {
  return HeartRateRepositoryImpl(
    database: ref.watch(databaseProvider),
    syncClient: ref.watch(syncClientProvider),
    network: ref.watch(networkGateProvider),
  );
});

final wearableFactoryProvider = Provider<WearableClientFactory>((ref) {
  final demo = MockWearableClient();
  final live = FlutterBlueWearableClient();
  ref.onDispose(() {
    unawaited(demo.stop());
    unawaited(live.stop());
  });
  return WearableClientFactory(demo: demo, live: live);
});

final readingsProvider = StreamProvider<List<HeartRateReading>>((ref) {
  return ref.watch(heartRateRepositoryProvider).watchAll();
});

class WearableClientFactory {
  const WearableClientFactory({required this.demo, required this.live});

  final WearableClient demo;
  final WearableClient live;

  WearableClient clientFor(bool demoMode) => demoMode ? demo : live;
}
