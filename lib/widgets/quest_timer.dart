import 'dart:async';

import 'package:flutter/material.dart';

import '../models/quest.dart';
import 'common.dart';

class QuestTimer extends StatefulWidget {
  const QuestTimer({super.key, required this.quest});
  final Quest quest;
  @override
  State<QuestTimer> createState() => _QuestTimerState();
}

class _QuestTimerState extends State<QuestTimer> {
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  String clock(Duration value) {
    final seconds = value.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds ~/ 60) % 60;
    final rest = seconds % 60;
    return '${hours > 0 ? '$hours:' : ''}${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final elapsed = q.attemptClock.elapsed;
    final target = q.targetDuration;
    final reached = target != null && elapsed >= target;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(q.attemptClock.isRunning ? 'TASK TIMER' : 'TIMER PAUSED'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  clock(target == null || reached ? elapsed : target - elapsed),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  q.attemptClock.isRunning
                      ? q.attemptClock.stop()
                      : q.attemptClock.start();
                }),
                icon: Icon(
                  q.attemptClock.isRunning ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(
                  q.attemptClock.isRunning ? 'Pause timer' : 'Resume timer',
                ),
              ),
            ],
          ),
          Text(
            target == null
                ? 'Time spent on this quest'
                : reached
                ? 'Estimated time reached · ${clock(elapsed)} elapsed'
                : '${clock(elapsed)} elapsed · estimated time remaining',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          if (target != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (elapsed.inMilliseconds / target.inMilliseconds).clamp(
                0,
                1,
              ),
              color: q.color,
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Time is a guide. Complete the activity and its verification to earn XP. Pausing this timer does not pause GPS tracking.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
