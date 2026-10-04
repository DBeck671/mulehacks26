import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import '../widgets/party_tasks_panel.dart';
import 'quest_detail_screen.dart';

class ClubActivityScreen extends StatelessWidget {
  const ClubActivityScreen({super.key, required this.state, this.openQuest});
  final AppState state;
  final ValueChanged<Quest>? openQuest;
  void openPartyTask(BuildContext context, Quest quest) {
    if (!state.startPartyTask(quest.id)) return;
    if (openQuest != null) {
      openQuest!(quest);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestDetailScreen(state: state, quest: quest),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Text('Club Activity')),
      body: SafeArea(
        child: !state.hasGroup
            ? const PageBody(
                children: [
                  PageHeading(
                    'No active club',
                    'Return to Friends to join or start a club.',
                  ),
                ],
              )
            : PageBody(
                children: [
                  PageHeading(
                    state.group.name,
                    'Shared tasks, progress, and recent adventures.',
                  ),
                  PartyTasksPanel(
                    state: state,
                    openQuest: (q) => openPartyTask(context, q),
                  ),
                  if (state.showcaseMode) ...[
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Demo friends'),
                      subtitle: Text(
                        state.demoBotsRunning
                            ? 'Completing shared tasks automatically'
                            : 'Paused',
                      ),
                      value: state.demoBotsRunning,
                      onChanged: state.setDemoBotsRunning,
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          state.group.partyTasks.any(
                            (t) =>
                                !t.isCompleted &&
                                !state.quest(t.questId).isActive,
                          )
                          ? () => state.simulateFriendCompletion()
                          : null,
                      icon: const Icon(Icons.smart_toy_outlined),
                      label: const Text('Let a demo friend complete a task'),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Eyebrow('RECENT ACTIVITY'),
                  const SizedBox(height: 14),
                  ...[
                    ...state.clubRecentActivity.take(6),
                    if (state.demoData && !state.showcaseMode)
                      'Alex completed Take a Detour · +150 XP',
                    if (state.demoData && !state.showcaseMode)
                      'Jordan discovered Nature + Creativity · Capture Nature',
                    if (state.demoData && !state.showcaseMode)
                      'Sam completed Morning Movement · +125 XP',
                  ].map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              size: 18,
                              color: green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: muted,
                                  height: 1.5,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
