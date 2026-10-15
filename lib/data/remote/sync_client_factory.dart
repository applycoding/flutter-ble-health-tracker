import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../../domain/ports.dart';
import 'firestore_sync_client.dart';
import 'mock_sync_client.dart';

HeartRateSyncClient createSyncClient({
  required AppConfig config,
  required http.Client httpClient,
}) {
  if (config.firebaseConfigured) {
    return FirestoreSyncClient(
      projectId: config.firebaseProjectId,
      apiKey: config.firebaseApiKey,
      httpClient: httpClient,
    );
  }
  return MockSyncClient();
}
