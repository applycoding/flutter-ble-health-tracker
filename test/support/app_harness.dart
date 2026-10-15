import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ledger/application/providers.dart';
import 'package:pulse_ledger/core/app_config.dart';
import 'package:pulse_ledger/data/local/app_database.dart';
import 'package:pulse_ledger/data/manual_network_gate.dart';
import 'package:pulse_ledger/data/remote/mock_sync_client.dart';

import 'scripted_wearable_client.dart';

class AppHarness {
  AppHarness({
    MockSyncClient? sync,
    ScriptedWearableClient? wearable,
    bool online = true,
    AppConfig config = const AppConfig(),
  }) : sync = sync ?? MockSyncClient(latency: Duration.zero),
       wearable = wearable ?? ScriptedWearableClient() {
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        databaseProvider.overrideWith((ref) {
          final database = AppDatabase(NativeDatabase.memory());
          ref.onDispose(database.close);
          return database;
        }),
        networkGateProvider.overrideWithValue(ManualNetworkGate(online: online)),
        syncClientProvider.overrideWithValue(this.sync),
        wearableFactoryProvider.overrideWithValue(
          WearableClientFactory(demo: this.wearable, live: this.wearable),
        ),
      ],
    );
  }

  final MockSyncClient sync;
  final ScriptedWearableClient wearable;
  late final ProviderContainer container;

  void dispose() => container.dispose();
}
