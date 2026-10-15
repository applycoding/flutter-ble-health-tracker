import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/heart_rate_reading.dart';
import '../../domain/models/sync_models.dart';
import '../providers.dart';

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

final class HistoryState {
  const HistoryState({
    required this.loading,
    required this.recent,
    required this.stats,
    required this.sync,
    required this.syncing,
  });

  const HistoryState.loading()
    : loading = true,
      recent = const [],
      stats = ReadingStats.empty,
      sync = const SyncOutcome(phase: SyncPhase.localOnly, pending: 0),
      syncing = false;

  final bool loading;
  final List<HeartRateReading> recent;
  final ReadingStats stats;
  final SyncOutcome sync;
  final bool syncing;

  HistoryState copyWith({
    bool? loading,
    List<HeartRateReading>? recent,
    ReadingStats? stats,
    SyncOutcome? sync,
    bool? syncing,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      recent: recent ?? this.recent,
      stats: stats ?? this.stats,
      sync: sync ?? this.sync,
      syncing: syncing ?? this.syncing,
    );
  }
}

final class HistoryController extends Notifier<HistoryState> {
  StreamSubscription<HistorySnapshot>? _subscription;

  @override
  HistoryState build() {
    final repository = ref.watch(heartRateRepositoryProvider);
    _subscription?.cancel();
    _subscription = repository.watchHistory().listen((snapshot) {
      final configured = repository.remote.isConfigured;
      final pending = snapshot.stats.pending;
      state = state.copyWith(
        loading: false,
        recent: snapshot.recent,
        stats: snapshot.stats,
        sync: SyncOutcome(
          phase: configured
              ? (pending == 0 ? SyncPhase.synced : SyncPhase.syncing)
              : SyncPhase.localOnly,
          pending: pending,
          detail: state.sync.detail ?? repository.remote.statusDetail,
        ),
      );
    });
    ref.onDispose(() => _subscription?.cancel());
    return const HistoryState.loading();
  }

  Future<void> sync() async {
    state = state.copyWith(syncing: true);
    final outcome = await ref.read(heartRateRepositoryProvider).syncPending();
    state = state.copyWith(syncing: false, sync: outcome);
  }
}
