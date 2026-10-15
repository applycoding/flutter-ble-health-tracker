enum SyncPhase { localOnly, offline, syncing, synced, failed }

final class SyncOutcome {
  const SyncOutcome({required this.phase, required this.pending, this.detail});

  final SyncPhase phase;
  final int pending;
  final String? detail;
}
