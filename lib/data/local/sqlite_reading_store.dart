import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/heart_rate_measurement.dart';
import '../../domain/models/heart_rate_reading.dart';
import '../../domain/ports.dart';

/// Offline store. [HeartRateReading.synced] is the queue flag for Firestore.
final class SqliteReadingStore implements ReadingStore {
  SqliteReadingStore._(this._db)
    : _changes = StreamController<void>.broadcast();

  final Database _db;
  final StreamController<void> _changes;

  static Future<SqliteReadingStore> openDefault() async {
    final directory = await getApplicationDocumentsDirectory();
    return SqliteReadingStore.open(
      factory: databaseFactory,
      path: p.join(directory.path, 'pulsekeep_readings.db'),
    );
  }

  static Future<SqliteReadingStore> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: path != inMemoryDatabasePath,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE readings (
              id TEXT PRIMARY KEY,
              bpm INTEGER NOT NULL,
              recorded_at_ms INTEGER NOT NULL,
              source_id TEXT NOT NULL,
              source_name TEXT NOT NULL,
              synced INTEGER NOT NULL,
              sensor_contact TEXT NOT NULL,
              energy_expended INTEGER,
              rr_intervals_ms TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_readings_time ON readings(recorded_at_ms DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_readings_synced ON readings(synced, recorded_at_ms)',
          );
        },
      ),
    );
    return SqliteReadingStore._(db);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> insert(HeartRateReading reading) async {
    await _db.insert('readings', {
      'id': reading.id,
      'bpm': reading.bpm,
      'recorded_at_ms': reading.recordedAt.toUtc().millisecondsSinceEpoch,
      'source_id': reading.sourceId,
      'source_name': reading.sourceName,
      'synced': reading.synced ? 1 : 0,
      'sensor_contact': reading.sensorContact.name,
      'energy_expended': reading.energyExpended,
      'rr_intervals_ms': reading.rrIntervalsMs.isEmpty
          ? null
          : jsonEncode(reading.rrIntervalsMs),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
    _notify();
  }

  @override
  Future<List<HeartRateReading>> recent({int limit = 200}) async {
    final rows = await _db.query(
      'readings',
      orderBy: 'recorded_at_ms DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<HeartRateReading>> pending({int limit = 400}) async {
    final rows = await _db.query(
      'readings',
      where: 'synced = 0',
      orderBy: 'recorded_at_ms ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> markSynced(Iterable<String> ids) async {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return;
    const batchSize = 200;
    await _db.transaction((txn) async {
      for (var start = 0; start < list.length; start += batchSize) {
        final end = start + batchSize > list.length
            ? list.length
            : start + batchSize;
        final chunk = list.sublist(start, end);
        final placeholders = List.filled(chunk.length, '?').join(',');
        await txn.rawUpdate(
          'UPDATE readings SET synced = 1 WHERE id IN ($placeholders)',
          chunk,
        );
      }
    });
    _notify();
  }

  @override
  Future<ReadingStats> stats() async {
    final rows = await _db.rawQuery('''
      SELECT
        COUNT(*) AS count,
        MIN(bpm) AS min_bpm,
        MAX(bpm) AS max_bpm,
        AVG(bpm) AS avg_bpm,
        SUM(CASE WHEN synced = 0 THEN 1 ELSE 0 END) AS pending
      FROM readings
    ''');
    final row = rows.first;
    final count = _asInt(row['count']);
    if (count == 0) return ReadingStats.empty;
    return ReadingStats(
      count: count,
      pending: _asInt(row['pending']),
      minBpm: _asInt(row['min_bpm']),
      maxBpm: _asInt(row['max_bpm']),
      averageBpm: (row['avg_bpm'] as num).round(),
    );
  }

  @override
  Future<void> close() async {
    await _db.close();
    await _changes.close();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  HeartRateReading _fromRow(Map<String, Object?> row) {
    final rrRaw = row['rr_intervals_ms'] as String?;
    final rr = rrRaw == null
        ? const <int>[]
        : (jsonDecode(rrRaw) as List<Object?>)
              .map((value) => value as int)
              .toList();
    return HeartRateReading(
      id: row['id']! as String,
      bpm: _asInt(row['bpm']),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(row['recorded_at_ms']),
        isUtc: true,
      ),
      sourceId: row['source_id']! as String,
      sourceName: row['source_name']! as String,
      synced: _asInt(row['synced']) == 1,
      sensorContact: SensorContact.values.byName(
        row['sensor_contact']! as String,
      ),
      energyExpended: row['energy_expended'] as int?,
      rrIntervalsMs: rr,
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected an integer column, got $value');
  }
}
