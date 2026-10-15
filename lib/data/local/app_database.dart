import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('PulseSampleRow')
class PulseSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bpm => integer()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get source => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
  IntColumn get energyExpendedKj => integer().nullable()();
  TextColumn get rrIntervalsMs => text().withDefault(const Constant(''))();
  BoolColumn get sensorContactSupported => boolean()();
  BoolColumn get sensorContactDetected => boolean()();
}

@DriftDatabase(tables: [PulseSamples])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'pulse_ledger'));

  @override
  int get schemaVersion => 1;

  Stream<List<PulseSampleRow>> watchRecent({int limit = 300}) {
    final query = select(pulseSamples)
      ..orderBy([
        (row) => OrderingTerm.desc(row.recordedAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit);
    return query.watch();
  }

  Future<int> insertSample(PulseSamplesCompanion row) {
    return into(pulseSamples).insert(row);
  }

  Future<List<PulseSampleRow>> pendingRows({required int limit}) {
    final query = select(pulseSamples)
      ..where((row) => row.synced.equals(false))
      ..orderBy([
        (row) => OrderingTerm.asc(row.recordedAt),
        (row) => OrderingTerm.asc(row.id),
      ])
      ..limit(limit);
    return query.get();
  }

  Stream<int> watchPendingCount() {
    final count = countAll();
    final query = selectOnly(pulseSamples)
      ..addColumns([count])
      ..where(pulseSamples.synced.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> markSynced(List<({int id, String remoteId})> updates) {
    return transaction(() async {
      for (final update in updates) {
        await (this.update(pulseSamples)..where((row) => row.id.equals(update.id))).write(
          PulseSamplesCompanion(
            synced: const Value(true),
            remoteId: Value(update.remoteId),
          ),
        );
      }
    });
  }
}
