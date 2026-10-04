import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../models/completed_activity.dart';
import '../widgets/common.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({
    super.key,
    required this.state,
    required this.openQuest,
  });
  final AppState state;
  final ValueChanged<Quest> openQuest;

  @override
  Widget build(BuildContext context) {
    // Attempts arrive newest first; insertion order keeps the most recently
    // completed tasks at the top, including non-consecutive repeats.
    final stacks = <int, List<CompletedActivity>>{};
    for (final entry in state.completedActivities) {
      stacks.putIfAbsent(entry.questId, () => []).add(entry);
    }
    return PageBody(
      children: [
        const PageHeading(
          'Activity Log',
          'Your completed tasks, with every repeat counted.',
        ),
        if (state.historySaveFailed)
          Panel(
            child: Column(
              children: [
                const Text(
                  'Could not save your activity log on this device. Keep the app open and retry.',
                ),
                TextButton(
                  onPressed: state.retryHistorySave,
                  child: const Text('RETRY SAVE'),
                ),
              ],
            ),
          ),
        if (state.completedActivities.isEmpty)
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.task_alt_rounded, color: green, size: 32),
                SizedBox(height: 16),
                Text(
                  'Your first adventure starts with a choice.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                Text(
                  'Choose a task from Home or Quests. Once completed, it will appear here, including every repeat.',
                  style: TextStyle(color: muted, height: 1.6),
                ),
              ],
            ),
          )
        else ...[
          Text(
            '${state.completedActivities.length} completions · ${stacks.length} unique tasks · +${state.earnedXP} XP earned',
            style: const TextStyle(color: green, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ...stacks.values.map((attempts) {
            final entry = attempts.first;
            final totalXP = attempts.fold<int>(
              0,
              (sum, attempt) => sum + attempt.xp,
            );
            final q = state.quest(entry.questId);
            final at = entry.completedAt.toLocal();
            final time =
                '${at.month}/${at.day}/${at.year} · ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
            return Padding(
              key: ValueKey('activity-log-${entry.questId}'),
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                color: q.color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: q.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+$totalXP XP',
                          style: TextStyle(
                            color: q.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Last completed $time',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completed ${attempts.length} ${attempts.length == 1 ? 'time' : 'times'}',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Latest verification: ${entry.verificationMethod}',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => openQuest(q),
                      child: const Text('DO THIS TASK AGAIN →'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
