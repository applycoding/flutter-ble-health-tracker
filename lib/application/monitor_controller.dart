import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import 'monitor_state.dart';
import 'providers.dart';

class MonitorController extends Notifier<MonitorState> {
  StreamSubscription<WearableStatus>? _statusSub;
  StreamSubscription<HeartRateSample>? _sampleSub;
  StreamSubscription<List<DiscoveredWearable>>? _scanSub;
  StreamSubscription<List<HeartRateReading>>? _readingSub;
  StreamSubscription<int>? _pendingSub;
  Timer? _syncTimer;
  WearableClient? _active;
  var _closed = false;
  var _attachSerial = 0;

  @override
  MonitorState build() {
    _closed = false;
    final config = ref.read(appConfigProvider);
    final network = ref.read(networkGateProvider);
    final sync = ref.read(syncClientProvider);
    final repository = ref.read(heartRateRepositoryProvider);

    ref.onDispose(() {
      _closed = true;
      _attachSerial += 1;
      _syncTimer?.cancel();
      _statusSub?.cancel();
      _sampleSub?.cancel();
      _scanSub?.cancel();
      _readingSub?.cancel();
      _pendingSub?.cancel();
      final active = _active;
      _active = null;
      if (active != null) unawaited(active.stop());
    });

    _readingSub = repository.watchAll().listen((readings) {
      if (_closed) return;
      state = state.copyWith(recent: readings);
    });
    _pendingSub = repository.watchPendingCount().listen((count) {
      if (_closed) return;
      state = state.copyWith(pendingCount: count);
    });

    final initial = MonitorState.initial(
      demoMode: config.startInDemoMode,
      online: network.isOnline,
      syncTarget: sync.targetLabel,
      firebaseConfigured: config.firebaseConfigured,
    );

    unawaited(_boot(initial.demoMode));
    return initial;
  }

  Future<void> _boot(bool demoMode) async {
    await Future<void>.delayed(Duration.zero);
    if (_closed) return;
    await _attach(demoMode);
    if (_closed) return;
    await syncNow();
  }

  Future<void> setDemoMode(bool demoMode) async {
    if (_closed || state.demoMode == demoMode) return;
    state = state.copyWith(
      demoMode: demoMode,
      discovered: const [],
      bpm: state.bpm,
      deviceName: demoMode ? 'PulseBand Demo' : 'No wearable',
      phase: demoMode ? WearablePhase.idle : WearablePhase.scanning,
      statusMessage: demoMode
          ? 'Starting the simulated strap.'
          : 'Scanning for Heart Rate Service 0x180D.',
    );
    await _attach(demoMode);
  }

  void setOnline(bool online) {
    if (_closed) return;
    ref.read(networkGateProvider).setOnline(online);
    state = state.copyWith(online: online);
    if (online) {
      _scheduleSync();
      return;
    }
    _syncTimer?.cancel();
    state = state.copyWith(
      syncMessage: 'Offline. New readings stay on this device.',
      syncOutcome: SyncOutcome.offline,
    );
  }

  Future<void> setStreaming(bool streaming) async {
    final client = _active;
    if (_closed || client == null) return;
    if (streaming) {
      await client.start();
      return;
    }
    await client.stop();
  }

  Future<void> scanAgain() async {
    final client = _active;
    if (_closed || client == null || state.demoMode) return;
    await client.start();
  }

  Future<void> connect(DiscoveredWearable device) async {
    final client = _active;
    if (_closed || client == null) return;
    await client.connect(device);
  }

  Future<void> syncNow() async {
    if (_closed || state.syncing) return;
    state = state.copyWith(syncing: true);
    final report = await ref.read(heartRateRepositoryProvider).syncPending();
    if (_closed) return;
    state = state.copyWith(
      syncing: false,
      syncMessage: report.message,
      syncOutcome: report.outcome,
    );
    if (report.outcome == SyncOutcome.synced && report.pending > 0) {
      _scheduleSync();
    }
  }

  Future<void> _attach(bool demoMode) async {
    final serial = ++_attachSerial;
    await _statusSub?.cancel();
    await _sampleSub?.cancel();
    await _scanSub?.cancel();
    _statusSub = null;
    _sampleSub = null;
    _scanSub = null;
    final previous = _active;
    _active = null;
    if (previous != null) await previous.stop();
    if (_closed || serial != _attachSerial) return;

    final client = ref.read(wearableFactoryProvider).clientFor(demoMode);
    _active = client;
    _statusSub = client.status.listen((status) {
      if (_closed) return;
      state = state.copyWith(
        phase: status.phase,
        deviceName: status.deviceName ?? state.deviceName,
        statusMessage: status.message,
      );
    });
    _sampleSub = client.samples.listen(_onSample);
    _scanSub = client.scanResults.listen((devices) {
      if (_closed) return;
      state = state.copyWith(discovered: devices);
    });
    await client.start();
  }

  void _onSample(HeartRateSample sample) {
    if (_closed) return;
    final contactLost = sample.sensorContactSupported && !sample.sensorContactDetected;
    state = state.copyWith(
      bpm: sample.bpm,
      deviceName: sample.deviceName,
      phase: WearablePhase.streaming,
      statusMessage: contactLost
          ? 'Sensor contact lost. Readings are still stored locally.'
          : state.demoMode
              ? 'Simulated 0x2A37 notifications from PulseBand Demo.'
              : 'Live 0x2A37 notifications.',
    );
    unawaited(_persist(sample));
  }

  Future<void> _persist(HeartRateSample sample) async {
    try {
      await ref.read(heartRateRepositoryProvider).record(sample);
      if (_closed) return;
      _scheduleSync();
    } on Object {
      if (_closed) return;
      state = state.copyWith(statusMessage: 'Could not write the reading to the local log.');
    }
  }

  void _scheduleSync() {
    if (_closed) return;
    if (!state.online) {
      state = state.copyWith(
        syncMessage: 'Offline. New readings stay on this device.',
        syncOutcome: SyncOutcome.offline,
      );
      return;
    }
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(syncNow());
    });
  }
}

final monitorProvider = NotifierProvider<MonitorController, MonitorState>(MonitorController.new);
