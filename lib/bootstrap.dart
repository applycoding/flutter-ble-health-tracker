import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/misc.dart';

import 'core/system_services.dart';
import 'data/local/sqlite_reading_store.dart';
import 'data/network/connectivity_network_status.dart';
import 'data/remote/firebase_project_config.dart';
import 'data/remote/firestore_heart_rate_remote.dart';
import 'data/remote/unconfigured_heart_rate_remote.dart';
import 'domain/ports.dart';
import 'domain/repositories/heart_rate_repository.dart';
import 'presentation/providers.dart';

/// Opens SQLite and, only when [FirebaseProjectConfig] has real values,
/// Firebase. Readings are stored locally either way.
Future<List<Override>> buildProductionOverrides() async {
  final store = await SqliteReadingStore.openDefault();
  final remote = await buildHeartRateRemote();
  final repository = HeartRateRepository(
    local: store,
    remote: remote,
    network: ConnectivityNetworkStatus(),
    ids: TimeReadingIdFactory(),
    clock: const SystemClock(),
  );
  return [heartRateRepositoryProvider.overrideWithValue(repository)];
}

Future<HeartRateRemote> buildHeartRateRemote() async {
  if (!FirebaseProjectConfig.isConfigured) {
    return const UnconfiguredHeartRateRemote(
      statusDetail: 'Firebase is not configured. Readings stay on this device.',
    );
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebaseProjectConfig.options);
    }
    return FirestoreHeartRateRemote(FirebaseFirestore.instance);
  } catch (error) {
    return UnconfiguredHeartRateRemote(
      statusDetail:
          'Firebase did not start ($error). Readings stay on this device.',
    );
  }
}
