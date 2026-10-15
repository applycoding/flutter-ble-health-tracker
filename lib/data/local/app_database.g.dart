// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PulseSamplesTable extends PulseSamples
    with TableInfo<$PulseSamplesTable, PulseSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PulseSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyExpendedKjMeta = const VerificationMeta(
    'energyExpendedKj',
  );
  @override
  late final GeneratedColumn<int> energyExpendedKj = GeneratedColumn<int>(
    'energy_expended_kj',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rrIntervalsMsMeta = const VerificationMeta(
    'rrIntervalsMs',
  );
  @override
  late final GeneratedColumn<String> rrIntervalsMs = GeneratedColumn<String>(
    'rr_intervals_ms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sensorContactSupportedMeta =
      const VerificationMeta('sensorContactSupported');
  @override
  late final GeneratedColumn<bool> sensorContactSupported =
      GeneratedColumn<bool>(
        'sensor_contact_supported',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sensor_contact_supported" IN (0, 1))',
        ),
      );
  static const VerificationMeta _sensorContactDetectedMeta =
      const VerificationMeta('sensorContactDetected');
  @override
  late final GeneratedColumn<bool> sensorContactDetected =
      GeneratedColumn<bool>(
        'sensor_contact_detected',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sensor_contact_detected" IN (0, 1))',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bpm,
    recordedAt,
    deviceId,
    deviceName,
    source,
    synced,
    remoteId,
    energyExpendedKj,
    rrIntervalsMs,
    sensorContactSupported,
    sensorContactDetected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pulse_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<PulseSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('energy_expended_kj')) {
      context.handle(
        _energyExpendedKjMeta,
        energyExpendedKj.isAcceptableOrUnknown(
          data['energy_expended_kj']!,
          _energyExpendedKjMeta,
        ),
      );
    }
    if (data.containsKey('rr_intervals_ms')) {
      context.handle(
        _rrIntervalsMsMeta,
        rrIntervalsMs.isAcceptableOrUnknown(
          data['rr_intervals_ms']!,
          _rrIntervalsMsMeta,
        ),
      );
    }
    if (data.containsKey('sensor_contact_supported')) {
      context.handle(
        _sensorContactSupportedMeta,
        sensorContactSupported.isAcceptableOrUnknown(
          data['sensor_contact_supported']!,
          _sensorContactSupportedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensorContactSupportedMeta);
    }
    if (data.containsKey('sensor_contact_detected')) {
      context.handle(
        _sensorContactDetectedMeta,
        sensorContactDetected.isAcceptableOrUnknown(
          data['sensor_contact_detected']!,
          _sensorContactDetectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensorContactDetectedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PulseSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PulseSampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      energyExpendedKj: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy_expended_kj'],
      ),
      rrIntervalsMs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rr_intervals_ms'],
      )!,
      sensorContactSupported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sensor_contact_supported'],
      )!,
      sensorContactDetected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sensor_contact_detected'],
      )!,
    );
  }

  @override
  $PulseSamplesTable createAlias(String alias) {
    return $PulseSamplesTable(attachedDatabase, alias);
  }
}

class PulseSampleRow extends DataClass implements Insertable<PulseSampleRow> {
  final int id;
  final int bpm;
  final DateTime recordedAt;
  final String deviceId;
  final String deviceName;
  final String source;
  final bool synced;
  final String? remoteId;
  final int? energyExpendedKj;
  final String rrIntervalsMs;
  final bool sensorContactSupported;
  final bool sensorContactDetected;
  const PulseSampleRow({
    required this.id,
    required this.bpm,
    required this.recordedAt,
    required this.deviceId,
    required this.deviceName,
    required this.source,
    required this.synced,
    this.remoteId,
    this.energyExpendedKj,
    required this.rrIntervalsMs,
    required this.sensorContactSupported,
    required this.sensorContactDetected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bpm'] = Variable<int>(bpm);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['source'] = Variable<String>(source);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || energyExpendedKj != null) {
      map['energy_expended_kj'] = Variable<int>(energyExpendedKj);
    }
    map['rr_intervals_ms'] = Variable<String>(rrIntervalsMs);
    map['sensor_contact_supported'] = Variable<bool>(sensorContactSupported);
    map['sensor_contact_detected'] = Variable<bool>(sensorContactDetected);
    return map;
  }

  PulseSamplesCompanion toCompanion(bool nullToAbsent) {
    return PulseSamplesCompanion(
      id: Value(id),
      bpm: Value(bpm),
      recordedAt: Value(recordedAt),
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      source: Value(source),
      synced: Value(synced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      energyExpendedKj: energyExpendedKj == null && nullToAbsent
          ? const Value.absent()
          : Value(energyExpendedKj),
      rrIntervalsMs: Value(rrIntervalsMs),
      sensorContactSupported: Value(sensorContactSupported),
      sensorContactDetected: Value(sensorContactDetected),
    );
  }

  factory PulseSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PulseSampleRow(
      id: serializer.fromJson<int>(json['id']),
      bpm: serializer.fromJson<int>(json['bpm']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      source: serializer.fromJson<String>(json['source']),
      synced: serializer.fromJson<bool>(json['synced']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      energyExpendedKj: serializer.fromJson<int?>(json['energyExpendedKj']),
      rrIntervalsMs: serializer.fromJson<String>(json['rrIntervalsMs']),
      sensorContactSupported: serializer.fromJson<bool>(
        json['sensorContactSupported'],
      ),
      sensorContactDetected: serializer.fromJson<bool>(
        json['sensorContactDetected'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bpm': serializer.toJson<int>(bpm),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'source': serializer.toJson<String>(source),
      'synced': serializer.toJson<bool>(synced),
      'remoteId': serializer.toJson<String?>(remoteId),
      'energyExpendedKj': serializer.toJson<int?>(energyExpendedKj),
      'rrIntervalsMs': serializer.toJson<String>(rrIntervalsMs),
      'sensorContactSupported': serializer.toJson<bool>(sensorContactSupported),
      'sensorContactDetected': serializer.toJson<bool>(sensorContactDetected),
    };
  }

  PulseSampleRow copyWith({
    int? id,
    int? bpm,
    DateTime? recordedAt,
    String? deviceId,
    String? deviceName,
    String? source,
    bool? synced,
    Value<String?> remoteId = const Value.absent(),
    Value<int?> energyExpendedKj = const Value.absent(),
    String? rrIntervalsMs,
    bool? sensorContactSupported,
    bool? sensorContactDetected,
  }) => PulseSampleRow(
    id: id ?? this.id,
    bpm: bpm ?? this.bpm,
    recordedAt: recordedAt ?? this.recordedAt,
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName ?? this.deviceName,
    source: source ?? this.source,
    synced: synced ?? this.synced,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    energyExpendedKj: energyExpendedKj.present
        ? energyExpendedKj.value
        : this.energyExpendedKj,
    rrIntervalsMs: rrIntervalsMs ?? this.rrIntervalsMs,
    sensorContactSupported:
        sensorContactSupported ?? this.sensorContactSupported,
    sensorContactDetected: sensorContactDetected ?? this.sensorContactDetected,
  );
  PulseSampleRow copyWithCompanion(PulseSamplesCompanion data) {
    return PulseSampleRow(
      id: data.id.present ? data.id.value : this.id,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      source: data.source.present ? data.source.value : this.source,
      synced: data.synced.present ? data.synced.value : this.synced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      energyExpendedKj: data.energyExpendedKj.present
          ? data.energyExpendedKj.value
          : this.energyExpendedKj,
      rrIntervalsMs: data.rrIntervalsMs.present
          ? data.rrIntervalsMs.value
          : this.rrIntervalsMs,
      sensorContactSupported: data.sensorContactSupported.present
          ? data.sensorContactSupported.value
          : this.sensorContactSupported,
      sensorContactDetected: data.sensorContactDetected.present
          ? data.sensorContactDetected.value
          : this.sensorContactDetected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PulseSampleRow(')
          ..write('id: $id, ')
          ..write('bpm: $bpm, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('source: $source, ')
          ..write('synced: $synced, ')
          ..write('remoteId: $remoteId, ')
          ..write('energyExpendedKj: $energyExpendedKj, ')
          ..write('rrIntervalsMs: $rrIntervalsMs, ')
          ..write('sensorContactSupported: $sensorContactSupported, ')
          ..write('sensorContactDetected: $sensorContactDetected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bpm,
    recordedAt,
    deviceId,
    deviceName,
    source,
    synced,
    remoteId,
    energyExpendedKj,
    rrIntervalsMs,
    sensorContactSupported,
    sensorContactDetected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PulseSampleRow &&
          other.id == this.id &&
          other.bpm == this.bpm &&
          other.recordedAt == this.recordedAt &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.source == this.source &&
          other.synced == this.synced &&
          other.remoteId == this.remoteId &&
          other.energyExpendedKj == this.energyExpendedKj &&
          other.rrIntervalsMs == this.rrIntervalsMs &&
          other.sensorContactSupported == this.sensorContactSupported &&
          other.sensorContactDetected == this.sensorContactDetected);
}

class PulseSamplesCompanion extends UpdateCompanion<PulseSampleRow> {
  final Value<int> id;
  final Value<int> bpm;
  final Value<DateTime> recordedAt;
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> source;
  final Value<bool> synced;
  final Value<String?> remoteId;
  final Value<int?> energyExpendedKj;
  final Value<String> rrIntervalsMs;
  final Value<bool> sensorContactSupported;
  final Value<bool> sensorContactDetected;
  const PulseSamplesCompanion({
    this.id = const Value.absent(),
    this.bpm = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.source = const Value.absent(),
    this.synced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.energyExpendedKj = const Value.absent(),
    this.rrIntervalsMs = const Value.absent(),
    this.sensorContactSupported = const Value.absent(),
    this.sensorContactDetected = const Value.absent(),
  });
  PulseSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int bpm,
    required DateTime recordedAt,
    required String deviceId,
    required String deviceName,
    required String source,
    this.synced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.energyExpendedKj = const Value.absent(),
    this.rrIntervalsMs = const Value.absent(),
    required bool sensorContactSupported,
    required bool sensorContactDetected,
  }) : bpm = Value(bpm),
       recordedAt = Value(recordedAt),
       deviceId = Value(deviceId),
       deviceName = Value(deviceName),
       source = Value(source),
       sensorContactSupported = Value(sensorContactSupported),
       sensorContactDetected = Value(sensorContactDetected);
  static Insertable<PulseSampleRow> custom({
    Expression<int>? id,
    Expression<int>? bpm,
    Expression<DateTime>? recordedAt,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? source,
    Expression<bool>? synced,
    Expression<String>? remoteId,
    Expression<int>? energyExpendedKj,
    Expression<String>? rrIntervalsMs,
    Expression<bool>? sensorContactSupported,
    Expression<bool>? sensorContactDetected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bpm != null) 'bpm': bpm,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (source != null) 'source': source,
      if (synced != null) 'synced': synced,
      if (remoteId != null) 'remote_id': remoteId,
      if (energyExpendedKj != null) 'energy_expended_kj': energyExpendedKj,
      if (rrIntervalsMs != null) 'rr_intervals_ms': rrIntervalsMs,
      if (sensorContactSupported != null)
        'sensor_contact_supported': sensorContactSupported,
      if (sensorContactDetected != null)
        'sensor_contact_detected': sensorContactDetected,
    });
  }

  PulseSamplesCompanion copyWith({
    Value<int>? id,
    Value<int>? bpm,
    Value<DateTime>? recordedAt,
    Value<String>? deviceId,
    Value<String>? deviceName,
    Value<String>? source,
    Value<bool>? synced,
    Value<String?>? remoteId,
    Value<int?>? energyExpendedKj,
    Value<String>? rrIntervalsMs,
    Value<bool>? sensorContactSupported,
    Value<bool>? sensorContactDetected,
  }) {
    return PulseSamplesCompanion(
      id: id ?? this.id,
      bpm: bpm ?? this.bpm,
      recordedAt: recordedAt ?? this.recordedAt,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      source: source ?? this.source,
      synced: synced ?? this.synced,
      remoteId: remoteId ?? this.remoteId,
      energyExpendedKj: energyExpendedKj ?? this.energyExpendedKj,
      rrIntervalsMs: rrIntervalsMs ?? this.rrIntervalsMs,
      sensorContactSupported:
          sensorContactSupported ?? this.sensorContactSupported,
      sensorContactDetected:
          sensorContactDetected ?? this.sensorContactDetected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (energyExpendedKj.present) {
      map['energy_expended_kj'] = Variable<int>(energyExpendedKj.value);
    }
    if (rrIntervalsMs.present) {
      map['rr_intervals_ms'] = Variable<String>(rrIntervalsMs.value);
    }
    if (sensorContactSupported.present) {
      map['sensor_contact_supported'] = Variable<bool>(
        sensorContactSupported.value,
      );
    }
    if (sensorContactDetected.present) {
      map['sensor_contact_detected'] = Variable<bool>(
        sensorContactDetected.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PulseSamplesCompanion(')
          ..write('id: $id, ')
          ..write('bpm: $bpm, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('source: $source, ')
          ..write('synced: $synced, ')
          ..write('remoteId: $remoteId, ')
          ..write('energyExpendedKj: $energyExpendedKj, ')
          ..write('rrIntervalsMs: $rrIntervalsMs, ')
          ..write('sensorContactSupported: $sensorContactSupported, ')
          ..write('sensorContactDetected: $sensorContactDetected')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PulseSamplesTable pulseSamples = $PulseSamplesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [pulseSamples];
}

typedef $$PulseSamplesTableCreateCompanionBuilder =
    PulseSamplesCompanion Function({
      Value<int> id,
      required int bpm,
      required DateTime recordedAt,
      required String deviceId,
      required String deviceName,
      required String source,
      Value<bool> synced,
      Value<String?> remoteId,
      Value<int?> energyExpendedKj,
      Value<String> rrIntervalsMs,
      required bool sensorContactSupported,
      required bool sensorContactDetected,
    });
typedef $$PulseSamplesTableUpdateCompanionBuilder =
    PulseSamplesCompanion Function({
      Value<int> id,
      Value<int> bpm,
      Value<DateTime> recordedAt,
      Value<String> deviceId,
      Value<String> deviceName,
      Value<String> source,
      Value<bool> synced,
      Value<String?> remoteId,
      Value<int?> energyExpendedKj,
      Value<String> rrIntervalsMs,
      Value<bool> sensorContactSupported,
      Value<bool> sensorContactDetected,
    });

class $$PulseSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $PulseSamplesTable> {
  $$PulseSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energyExpendedKj => $composableBuilder(
    column: $table.energyExpendedKj,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrIntervalsMs => $composableBuilder(
    column: $table.rrIntervalsMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensorContactSupported => $composableBuilder(
    column: $table.sensorContactSupported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensorContactDetected => $composableBuilder(
    column: $table.sensorContactDetected,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PulseSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $PulseSamplesTable> {
  $$PulseSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energyExpendedKj => $composableBuilder(
    column: $table.energyExpendedKj,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrIntervalsMs => $composableBuilder(
    column: $table.rrIntervalsMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensorContactSupported => $composableBuilder(
    column: $table.sensorContactSupported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensorContactDetected => $composableBuilder(
    column: $table.sensorContactDetected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PulseSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PulseSamplesTable> {
  $$PulseSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get energyExpendedKj => $composableBuilder(
    column: $table.energyExpendedKj,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrIntervalsMs => $composableBuilder(
    column: $table.rrIntervalsMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sensorContactSupported => $composableBuilder(
    column: $table.sensorContactSupported,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sensorContactDetected => $composableBuilder(
    column: $table.sensorContactDetected,
    builder: (column) => column,
  );
}

class $$PulseSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PulseSamplesTable,
          PulseSampleRow,
          $$PulseSamplesTableFilterComposer,
          $$PulseSamplesTableOrderingComposer,
          $$PulseSamplesTableAnnotationComposer,
          $$PulseSamplesTableCreateCompanionBuilder,
          $$PulseSamplesTableUpdateCompanionBuilder,
          (
            PulseSampleRow,
            BaseReferences<_$AppDatabase, $PulseSamplesTable, PulseSampleRow>,
          ),
          PulseSampleRow,
          PrefetchHooks Function()
        > {
  $$PulseSamplesTableTableManager(_$AppDatabase db, $PulseSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PulseSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PulseSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PulseSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int?> energyExpendedKj = const Value.absent(),
                Value<String> rrIntervalsMs = const Value.absent(),
                Value<bool> sensorContactSupported = const Value.absent(),
                Value<bool> sensorContactDetected = const Value.absent(),
              }) => PulseSamplesCompanion(
                id: id,
                bpm: bpm,
                recordedAt: recordedAt,
                deviceId: deviceId,
                deviceName: deviceName,
                source: source,
                synced: synced,
                remoteId: remoteId,
                energyExpendedKj: energyExpendedKj,
                rrIntervalsMs: rrIntervalsMs,
                sensorContactSupported: sensorContactSupported,
                sensorContactDetected: sensorContactDetected,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bpm,
                required DateTime recordedAt,
                required String deviceId,
                required String deviceName,
                required String source,
                Value<bool> synced = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int?> energyExpendedKj = const Value.absent(),
                Value<String> rrIntervalsMs = const Value.absent(),
                required bool sensorContactSupported,
                required bool sensorContactDetected,
              }) => PulseSamplesCompanion.insert(
                id: id,
                bpm: bpm,
                recordedAt: recordedAt,
                deviceId: deviceId,
                deviceName: deviceName,
                source: source,
                synced: synced,
                remoteId: remoteId,
                energyExpendedKj: energyExpendedKj,
                rrIntervalsMs: rrIntervalsMs,
                sensorContactSupported: sensorContactSupported,
                sensorContactDetected: sensorContactDetected,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PulseSamplesTable, PulseSampleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PulseSamplesTable,
                    PulseSampleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PulseSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PulseSamplesTable,
      PulseSampleRow,
      $$PulseSamplesTableFilterComposer,
      $$PulseSamplesTableOrderingComposer,
      $$PulseSamplesTableAnnotationComposer,
      $$PulseSamplesTableCreateCompanionBuilder,
      $$PulseSamplesTableUpdateCompanionBuilder,
      (
        PulseSampleRow,
        BaseReferences<_$AppDatabase, $PulseSamplesTable, PulseSampleRow>,
      ),
      PulseSampleRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PulseSamplesTableTableManager get pulseSamples =>
      $$PulseSamplesTableTableManager(_db, _db.pulseSamples);
}
