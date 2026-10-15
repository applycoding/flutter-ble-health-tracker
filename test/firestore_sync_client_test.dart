import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_ledger/data/remote/firestore_sync_client.dart';
import 'package:pulse_ledger/domain/ports.dart';

import 'support/samples.dart';

void main() {
  test('commit body uses Firestore typed values', () {
    final body = firestoreCommitBody(
      projectId: 'pulse-demo',
      databaseId: '(default)',
      readings: [reading(id: 7, bpm: 72)],
    );
    final writes = body['writes']! as List<Object?>;
    final update = (writes.single! as Map<String, Object?>)['update']! as Map<String, Object?>;
    expect(
      update['name'],
      'projects/pulse-demo/databases/(default)/documents/heartRateReadings/hr_7',
    );
    final fields = update['fields']! as Map<String, Object?>;
    expect(fields['bpm'], {'integerValue': '72'});
    expect(fields['source'], {'stringValue': 'demo'});
    expect(fields['recordedAt'], {'timestampValue': '2026-10-15T12:00:00.000Z'});
  });

  test('posts a commit and returns document ids', () async {
    http.Request? seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response(
        jsonEncode(<String, Object?>{
          'writeResults': <Map<String, Object?>>[<String, Object?>{}],
        }),
        200,
      );
    });
    final sync = FirestoreSyncClient(
      projectId: 'pulse-demo',
      apiKey: 'test-key',
      httpClient: client,
      endpoint: Uri.parse('https://firestore.test'),
    );

    final ids = await sync.upload([reading(id: 7)]);

    expect(ids, ['heartRateReadings/hr_7']);
    final request = seen!;
    expect(request.method, 'POST');
    expect(request.url.path, '/v1/projects/pulse-demo/databases/(default)/documents:commit');
    expect(request.url.queryParameters['key'], 'test-key');
    final payload = jsonDecode(request.body) as Map<String, Object?>;
    expect(payload['writes'], isA<List<Object?>>());
  });

  test('missing credentials fail before any request', () async {
    var called = false;
    final sync = FirestoreSyncClient(
      projectId: '',
      apiKey: '',
      httpClient: MockClient((request) async {
        called = true;
        return http.Response('no', 500);
      }),
    );
    await expectLater(
      sync.upload([reading(id: 1)]),
      throwsA(isA<SyncNotConfiguredException>()),
    );
    expect(called, isFalse);
  });

  test('non-success responses become transport failures', () async {
    final sync = FirestoreSyncClient(
      projectId: 'pulse-demo',
      apiKey: 'test-key',
      httpClient: MockClient((request) async => http.Response('permission denied', 403)),
    );
    await expectLater(
      sync.upload([reading(id: 1)]),
      throwsA(
        isA<SyncTransportException>().having(
          (error) => error.message,
          'message',
          contains('403'),
        ),
      ),
    );
  });
}
