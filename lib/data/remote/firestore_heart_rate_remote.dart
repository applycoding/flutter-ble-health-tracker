import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/heart_rate_reading.dart';
import '../../domain/ports.dart';
import 'batch_chunks.dart';

/// Pushes readings with merge writes so a retry cannot duplicate a document.
final class FirestoreHeartRateRemote implements HeartRateRemote {
  FirestoreHeartRateRemote(this._firestore);

  final FirebaseFirestore _firestore;

  static const collectionName = 'heart_rate_readings';

  /// Firestore allows 500 writes per batch. Leave headroom.
  static const batchLimit = 400;

  @override
  bool get isConfigured => true;

  @override
  String get statusDetail => 'Firestore collection $collectionName';

  @override
  Future<void> push(List<HeartRateReading> readings) async {
    for (final chunk in chunksOf(readings, batchLimit)) {
      final batch = _firestore.batch();
      for (final reading in chunk) {
        batch.set(
          _firestore.collection(collectionName).doc(reading.id),
          _document(reading),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Map<String, Object?> _document(HeartRateReading reading) {
    return {
      'bpm': reading.bpm,
      'recordedAt': Timestamp.fromDate(reading.recordedAt.toUtc()),
      'sourceId': reading.sourceId,
      'sourceName': reading.sourceName,
      'sensorContact': reading.sensorContact.name,
      'energyExpended': reading.energyExpended,
      'rrIntervalsMs': reading.rrIntervalsMs,
      'demo': true,
    };
  }
}
