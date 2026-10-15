import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

class BeatingHeart extends StatefulWidget {
  const BeatingHeart({required this.bpm, super.key});

  final int? bpm;

  @override
  State<BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<BeatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _syncDuration();
    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BeatingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) _syncDuration();
  }

  void _syncDuration() {
    final bpm = widget.bpm;
    final milliseconds = bpm == null || bpm <= 0 ? 900 : (60000 / bpm).round();
    _controller.duration = Duration(milliseconds: milliseconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.92,
        end: 1.12,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: const Icon(Icons.favorite, color: PulseColors.heart, size: 34),
    );
  }
}
