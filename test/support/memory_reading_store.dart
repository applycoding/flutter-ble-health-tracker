import 'dart:async';

import 'package:pulsekeep/domain/models/heart_rate_reading.dart';
import 'package:pulsekeep/domain/ports.dart';

final class MemoryReadingStore implements ReadingStore {
  final Map<String, HeartRateReading> _rows = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> insert(HeartRateReading reading) async {
    _rows[reading.id] = reading;
    _changes.add(null);
  }

  @override
  Future<List<HeartRateReading>> recent({int limit = 200}) async {
    final rows = _rows.values.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (rows.length <= limit) return rows;
    return rows.sublist(0, limit);
  }

  @override
  Future<List<HeartRateReading>> pending({int limit = 400}) async {
    final rows = _rows.values.where((reading) => !reading.synced).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (rows.length <= limit) return rows;
    return rows.sublist(0, limit);
  }

  @override
  Future<void> markSynced(Iterable<String> ids) async {
    for (final id in ids) {
      final row = _rows[id];
      if (row != null) _rows[id] = row.copyWith(synced: true);
    }
    _changes.add(null);
  }

  @override
  Future<ReadingStats> stats() async {
    if (_rows.isEmpty) return ReadingStats.empty;
    final values = _rows.values.toList();
    final bpms = values.map((reading) => reading.bpm);
    final sum = bpms.reduce((a, b) => a + b);
    return ReadingStats(
      count: values.length,
      pending: values.where((reading) => !reading.synced).length,
      minBpm: bpms.reduce((a, b) => a < b ? a : b),
      maxBpm: bpms.reduce((a, b) => a > b ? a : b),
      averageBpm: (sum / values.length).round(),
    );
  }

  @override
  Future<void> close() async {
    await _changes.close();
  }
}
