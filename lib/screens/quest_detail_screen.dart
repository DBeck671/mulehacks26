import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/sample_quests.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import '../widgets/quest_timer.dart';
import '../widgets/verification_panel.dart';
import 'quest_complete_screen.dart';

class QuestDetailScreen extends StatelessWidget {
  const QuestDetailScreen({
    super.key,
    required this.state,
    required this.quest,
    this.onReturnHome,
  });
  final AppState state;
  final Quest quest;
  final VoidCallback? onReturnHome;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Eyebrow('YOUR SIDEQUEST')),
      body: SafeArea(
        child: PageBody(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: quest.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: quest.color.withValues(alpha: .3)),
              ),
              child: Icon(
                quest.isCompleted
                    ? Icons.check_rounded
                    : quest.isLocked
                    ? Icons.lock_outline
                    : quest.categories.first.icon,
                color: quest.color,
                size: 40,
              ),
            ),
            const SizedBox(height: 30),
            CategoryBadges(quest.categories),
            const SizedBox(height: 18),
            Text(quest.title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            Text(
              quest.description,
              style: const TextStyle(color: muted, height: 1.7, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Panel(
              child: StatStrip(
                values: [
                  quest.duration,
                  quest.difficulty,
                  '+${quest.rewardXP}',
                ],
                labels: const ['Estimated time', 'Difficulty', 'XP reward'],
              ),
            ),
            if (quest.isActive) ...[
              const SizedBox(height: 18),
              QuestTimer(
                key: ValueKey('timer-${quest.id}-${quest.attemptNumber}'),
                quest: quest,
              ),
            ],
            const SizedBox(height: 28),
            VerificationPanel(
              key: ValueKey(quest.attemptNumber),
              state: state,
              quest: quest,
            ),
            const SizedBox(height: 24),
            if (quest.isLocked) ...[
              const Eyebrow('LOCKED'),
              const SizedBox(height: 12),
              const Text(
                'Complete these activities to open this path:',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 12),
              ...(questParents[quest.id] ?? []).map(
                (id) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        state.quest(id).isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: state.quest(id).isCompleted ? green : muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.quest(id).title)),
                    ],
                  ),
                ),
              ),
            ] else if (quest.isCompleted && !quest.isActive) ...[
              Panel(
                color: quest.color,
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: quest.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completed ${quest.completionCount} times · ${quest.earnedXP} XP earned',
                        style: TextStyle(
                          color: quest.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => state.start(quest),
                  child: const Text('DO SIDEQUEST AGAIN'),
                ),
              ),
            ] else ...[
              if (quest.isActive) ...[
                Eyebrow('QUEST ACTIVE', color: quest.color),
                const SizedBox(height: 14),
              ],
              if (!quest.isActive && state.active != null) ...[
                Text(
                  'Starting this quest will replace your active quest: ${state.active!.title}.',
                  style: const TextStyle(
                    color: muted,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: quest.isActive && !quest.verification.isSatisfied
                      ? null
                      : () async {
                          if (!quest.isActive) {
                            state.start(quest);
                            return;
                          }
                          final result = state.complete(quest);
                          if (result == null) return;
                          final next = await Navigator.push<Quest>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestCompleteScreen(
                                state: state,
                                result: result,
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          if (next == null) {
                            if (onReturnHome != null) {
                              onReturnHome!();
                            } else {
                              Navigator.pop(context, true);
                            }
                          } else {
                            Navigator.pushReplacement<bool, bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestDetailScreen(
                                  state: state,
                                  quest: next,
                                  onReturnHome: onReturnHome,
                                ),
                              ),
                              result: true,
                            );
                          }
                        },
                  child: Text(
                    quest.isActive ? 'COMPLETE SIDEQUEST' : 'START SIDEQUEST',
                  ),
                ),
              ),
            ],
            if (quest.isActive) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  state.stop(quest);
                  if (onReturnHome != null) {
                    onReturnHome!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop task'),
              ),
              const Text(
                'Stopping earns no XP and adds nothing to your Activity Log.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 17, color: muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location is used only for the check-ins or GPS tracking you start. Walking and running tracking pauses when you leave this task.\n\nYour evidence stays on this device for the current attempt. Successful task summaries are saved in your Activity Log. Photos are not automatically reviewed; GPS quests must meet their distance target.',
                    style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
