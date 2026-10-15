import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/app_failure.dart';
import '../../domain/models/device_models.dart';
import '../../domain/models/heart_rate_measurement.dart';
import '../../domain/models/sync_models.dart';
import '../../domain/parsing/heart_rate_zone.dart';
import '../../domain/ports.dart';
import '../providers.dart';

final monitorControllerProvider =
    NotifierProvider<MonitorController, MonitorState>(MonitorController.new);

final class BpmSample {
  const BpmSample({required this.bpm, required this.at});

  final int bpm;
  final DateTime at;
}

final class MonitorState {
  const MonitorState({
    required this.device,
    required this.link,
    required this.window,
    required this.canChangeActivity,
    required this.activity,
    required this.sync,
    this.bpm,
    this.zone,
    this.sensorContact,
    this.savedCount = 0,
    this.warning,
  });

  final HeartRateDevice? device;
  final LinkStatus link;
  final List<BpmSample> window;
  final bool canChangeActivity;
  final ActivityProfile activity;
  final SyncOutcome sync;
  final int? bpm;
  final HeartRateZone? zone;
  final SensorContact? sensorContact;
  final int savedCount;
  final String? warning;

  factory MonitorState.initial({
    required HeartRateDevice? device,
    required bool canChangeActivity,
  }) {
    return MonitorState(
      device: device,
      link: device == null ? const LinkIdle() : const LinkConnecting(),
      window: const [],
      canChangeActivity: canChangeActivity,
      activity: ActivityProfile.rest,
      sync: const SyncOutcome(phase: SyncPhase.localOnly, pending: 0),
    );
  }

  MonitorState copyWith({
    LinkStatus? link,
    List<BpmSample>? window,
    ActivityProfile? activity,
    SyncOutcome? sync,
    int? bpm,
    HeartRateZone? zone,
    SensorContact? sensorContact,
    int? savedCount,
    String? warning,
    bool clearWarning = false,
  }) {
    return MonitorState(
      device: device,
      link: link ?? this.link,
      window: window ?? this.window,
      canChangeActivity: canChangeActivity,
      activity: activity ?? this.activity,
      sync: sync ?? this.sync,
      bpm: bpm ?? this.bpm,
      zone: zone ?? this.zone,
      sensorContact: sensorContact ?? this.sensorContact,
      savedCount: savedCount ?? this.savedCount,
      warning: clearWarning ? null : warning ?? this.warning,
    );
  }
}

final class MonitorController extends Notifier<MonitorState> {
  static const persistInterval = Duration(seconds: 1);
  static const windowSize = 60;

  StreamSubscription<HeartRateMeasurement>? _measurements;
  StreamSubscription<LinkStatus>? _link;
  StreamSubscription<String>? _warnings;
  DateTime? _lastPersistedAt;
  var _started = false;
  var _generation = 0;

  @override
  MonitorState build() {
    ref.onDispose(() {
      _generation += 1;
      _cancel();
    });
    return MonitorState.initial(
      device: ref.read(selectedDeviceProvider),
      canChangeActivity: ref.read(activeGatewayProvider).canChangeActivity,
    );
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final device = ref.read(selectedDeviceProvider);
    final gateway = ref.read(activeGatewayProvider);
    final generation = ++_generation;
    state = MonitorState.initial(
      device: device,
      canChangeActivity: gateway.canChangeActivity,
    );
    if (device == null) {
      state = state.copyWith(
        link: const LinkFailed('Choose a monitor on the previous screen.'),
      );
      return;
    }

    _listen(gateway, device, generation);
    try {
      await gateway.connect(device);
    } on AppFailure catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(link: LinkFailed(error.message));
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(link: const LinkFailed('Could not connect.'));
    }
  }

  void setActivity(ActivityProfile profile) {
    final gateway = ref.read(activeGatewayProvider);
    if (!gateway.canChangeActivity) return;
    gateway.setActivity(profile);
    state = state.copyWith(activity: profile);
  }

  Future<void> leave() async {
    _generation += 1;
    _started = false;
    _cancel();
    await ref.read(activeGatewayProvider).disconnect();
  }

  void _listen(
    HeartRateGateway gateway,
    HeartRateDevice device,
    int generation,
  ) {
    _cancel();
    _link = gateway.watchLink().listen((status) {
      if (generation != _generation) return;
      state = state.copyWith(link: status);
    });
    _warnings = gateway.watchWarnings().listen((warning) {
      if (generation != _generation) return;
      state = state.copyWith(warning: warning);
    });
    _measurements = gateway.watchMeasurements().listen((measurement) {
      if (generation != _generation) return;
      unawaited(_onMeasurement(measurement, device, generation));
    });
  }

  Future<void> _onMeasurement(
    HeartRateMeasurement measurement,
    HeartRateDevice device,
    int generation,
  ) async {
    final clock = ref.read(clockProvider);
    final now = clock.now();
    final window = [...state.window, BpmSample(bpm: measurement.bpm, at: now)];
    final trimmed = window.length > windowSize
        ? window.sublist(window.length - windowSize)
        : window;
    state = state.copyWith(
      bpm: measurement.bpm,
      zone: zoneFor(measurement.bpm),
      sensorContact: measurement.sensorContact,
      window: trimmed,
      clearWarning: true,
    );

    if (_lastPersistedAt != null &&
        now.difference(_lastPersistedAt!) < persistInterval) {
      return;
    }
    _lastPersistedAt = now;
    final repository = ref.read(heartRateRepositoryProvider);
    try {
      await repository.record(measurement: measurement, device: device);
      final outcome = await repository.syncPending();
      if (generation != _generation) return;
      state = state.copyWith(savedCount: state.savedCount + 1, sync: outcome);
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(
        sync: SyncOutcome(
          phase: SyncPhase.failed,
          pending: state.sync.pending,
          detail: 'Could not save this reading on the device.',
        ),
      );
    }
  }

  void _cancel() {
    _measurements?.cancel();
    _link?.cancel();
    _warnings?.cancel();
    _measurements = null;
    _link = null;
    _warnings = null;
  }
}
