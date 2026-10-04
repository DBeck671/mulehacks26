import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../models/verification.dart';
import 'common.dart';

class PartyTasksPanel extends StatelessWidget {
  const PartyTasksPanel({
    super.key,
    required this.state,
    required this.openQuest,
  });
  final AppState state;
  final ValueChanged<Quest> openQuest;

  @override
  Widget build(BuildContext context) {
    final party = state.group;
    return Panel(
      color: context.palette.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(
            'PARTY TASKS · ROUND ${party.partyRound}',
            color: context.palette.green,
          ),
          const SizedBox(height: 12),
          Text(
            party.partyComplete
                ? 'Party list complete!'
                : 'Complete these together',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Work through your shared list. Each task needs one successful completion by a party member.',
            style: TextStyle(
              color: context.palette.muted,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${party.partyCompletedCount} / ${party.partyTasks.length} party tasks completed',
            style: TextStyle(
              color: context.palette.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SmoothBar(
            value: party.partyTasks.isEmpty
                ? 0
                : party.partyCompletedCount / party.partyTasks.length,
          ),
          const SizedBox(height: 16),
          ...party.partyTasks.map((task) {
            final q = state.quest(task.questId);
            return Padding(
              key: ValueKey(
                'party-task-${party.id}-${party.partyRound}-${q.id}',
              ),
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task.isCompleted
                            ? context.palette.green
                            : context.palette.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.isCompleted
                        ? 'Completed by ${task.completedByName} · +${task.earnedXP} XP'
                        : '${q.duration} · +${q.rewardXP} XP · ${q.verification.method.label}',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  if (!task.isCompleted)
                    TextButton(
                      onPressed: () => openQuest(q),
                      child: const Text('DO PARTY TASK →'),
                    ),
                ],
              ),
            );
          }),
          if (party.partyComplete)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.generatePartyTasks,
                child: const Text('GENERATE NEXT PARTY LIST'),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            state.showcaseMode ? 'Demo club · friends are simulated bots.' : 'Local demo: party progress stays on this device. Online member updates are not connected yet.',
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
