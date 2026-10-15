import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models.dart';
import '../../domain/ports.dart';

/// Firestore writes over the REST API.
///
/// Production mobile apps often use `cloud_firestore` behind [HeartRateSyncClient].
/// This client stays in pure Dart so the demo builds on desktop and CI without
/// a `google-services` file. It does nothing until a project id and API key are
/// supplied. An API key is not an auth boundary; real rules should require auth.
class FirestoreSyncClient implements HeartRateSyncClient {
  FirestoreSyncClient({
    required this.projectId,
    required this.apiKey,
    required this.httpClient,
    this.databaseId = '(default)',
    Uri? endpoint,
  }) : endpoint = endpoint ?? Uri.parse('https://firestore.googleapis.com');

  final String projectId;
  final String apiKey;
  final http.Client httpClient;
  final String databaseId;
  final Uri endpoint;

  bool get isConfigured => projectId.isNotEmpty && apiKey.isNotEmpty;

  @override
  String get targetLabel => 'Firestore ($projectId)';

  @override
  Future<List<String>> upload(List<HeartRateReading> readings) async {
    if (!isConfigured) {
      throw const SyncNotConfiguredException(
        'Set FIREBASE_PROJECT_ID and FIREBASE_API_KEY to sync to Firestore.',
      );
    }
    if (readings.isEmpty) return const [];

    final documentIds = [for (final reading in readings) documentIdFor(reading)];
    final uri = endpoint.replace(
      path: '/v1/projects/$projectId/databases/$databaseId/documents:commit',
      queryParameters: {'key': apiKey},
    );
    final body = jsonEncode(
      firestoreCommitBody(
        projectId: projectId,
        databaseId: databaseId,
        readings: readings,
      ),
    );

    http.Response response;
    try {
      response = await httpClient.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: body,
      );
    } on http.ClientException catch (error) {
      throw SyncTransportException('Could not reach Firestore. ${error.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncTransportException(
        'Firestore returned ${response.statusCode}: ${_snippet(response.body)}',
      );
    }
    return [for (final id in documentIds) 'heartRateReadings/$id'];
  }
}

String documentIdFor(HeartRateReading reading) {
  final localId = reading.id;
  if (localId != null) return 'hr_$localId';
  return 'hr_${reading.recordedAt.toUtc().microsecondsSinceEpoch}';
}

Map<String, Object?> firestoreCommitBody({
  required String projectId,
  required String databaseId,
  required List<HeartRateReading> readings,
}) {
  return {
    'writes': [
      for (final reading in readings)
        {
          'update': {
            'name':
                'projects/$projectId/databases/$databaseId/documents/heartRateReadings/${documentIdFor(reading)}',
            'fields': firestoreFieldsFor(reading),
          },
        },
    ],
  };
}

Map<String, Object?> firestoreFieldsFor(HeartRateReading reading) {
  final fields = <String, Object?>{
    'bpm': {'integerValue': '${reading.bpm}'},
    'recordedAt': {'timestampValue': reading.recordedAt.toUtc().toIso8601String()},
    'deviceId': {'stringValue': reading.deviceId},
    'deviceName': {'stringValue': reading.deviceName},
    'source': {'stringValue': reading.source.name},
    'sensorContactSupported': {'booleanValue': reading.sensorContactSupported},
    'sensorContactDetected': {'booleanValue': reading.sensorContactDetected},
    'rrIntervalsMs': {
      'arrayValue': {
        'values': [
          for (final interval in reading.rrIntervalsMs) {'doubleValue': interval},
        ],
      },
    },
  };
  final energy = reading.energyExpendedKj;
  if (energy != null) {
    fields['energyExpendedKj'] = {'integerValue': '$energy'};
  }
  return fields;
}

String _snippet(String body) {
  final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 160) return compact;
  return '${compact.substring(0, 160)}…';
}
