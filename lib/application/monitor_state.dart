import '../domain/models.dart';

class MonitorState {
  const MonitorState({
    required this.demoMode,
    required this.phase,
    required this.deviceName,
    required this.statusMessage,
    required this.bpm,
    required this.recent,
    required this.pendingCount,
    required this.online,
    required this.syncing,
    required this.syncTarget,
    required this.syncMessage,
    required this.syncOutcome,
    required this.discovered,
    required this.firebaseConfigured,
  });

  factory MonitorState.initial({
    required bool demoMode,
    required bool online,
    required String syncTarget,
    required bool firebaseConfigured,
  }) {
    return MonitorState(
      demoMode: demoMode,
      phase: WearablePhase.idle,
      deviceName: demoMode ? 'PulseBand Demo' : 'No wearable',
      statusMessage: demoMode
          ? 'Starting the simulated strap.'
          : 'Ready to scan for a heart-rate monitor.',
      bpm: null,
      recent: const [],
      pendingCount: 0,
      online: online,
      syncing: false,
      syncTarget: syncTarget,
      syncMessage: firebaseConfigured
          ? 'Firestore REST is configured.'
          : 'No Firebase credentials. Sync uses the in-memory mock.',
      syncOutcome: null,
      discovered: const [],
      firebaseConfigured: firebaseConfigured,
    );
  }

  final bool demoMode;
  final WearablePhase phase;
  final String deviceName;
  final String statusMessage;
  final int? bpm;
  final List<HeartRateReading> recent;
  final int pendingCount;
  final bool online;
  final bool syncing;
  final String syncTarget;
  final String syncMessage;
  final SyncOutcome? syncOutcome;
  final List<DiscoveredWearable> discovered;
  final bool firebaseConfigured;

  HeartRateStats get stats => HeartRateStats.from(recent);

  List<HeartRateReading> get trace {
    final window = recent.take(60).toList();
    return window.reversed.toList(growable: false);
  }

  MonitorState copyWith({
    bool? demoMode,
    WearablePhase? phase,
    String? deviceName,
    String? statusMessage,
    int? bpm,
    List<HeartRateReading>? recent,
    int? pendingCount,
    bool? online,
    bool? syncing,
    String? syncTarget,
    String? syncMessage,
    SyncOutcome? syncOutcome,
    List<DiscoveredWearable>? discovered,
    bool? firebaseConfigured,
  }) {
    return MonitorState(
      demoMode: demoMode ?? this.demoMode,
      phase: phase ?? this.phase,
      deviceName: deviceName ?? this.deviceName,
      statusMessage: statusMessage ?? this.statusMessage,
      bpm: bpm ?? this.bpm,
      recent: recent ?? this.recent,
      pendingCount: pendingCount ?? this.pendingCount,
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      syncTarget: syncTarget ?? this.syncTarget,
      syncMessage: syncMessage ?? this.syncMessage,
      syncOutcome: syncOutcome ?? this.syncOutcome,
      discovered: discovered ?? this.discovered,
      firebaseConfigured: firebaseConfigured ?? this.firebaseConfigured,
    );
  }
}
