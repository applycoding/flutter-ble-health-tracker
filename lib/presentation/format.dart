import '../domain/models.dart';

String formatBpm(int? bpm) => bpm == null ? '—' : '$bpm';

String formatClock(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String formatDayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${target.day} ${months[target.month - 1]} ${target.year}';
}

String phaseLabel(WearablePhase phase) => switch (phase) {
      WearablePhase.idle => 'Idle',
      WearablePhase.scanning => 'Scanning',
      WearablePhase.connecting => 'Connecting',
      WearablePhase.streaming => 'Live',
      WearablePhase.stopped => 'Paused',
      WearablePhase.error => 'Check Bluetooth',
    };
