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
                  const SizedBox(height: 30),
                  const Eyebrow('RECENT ACTIVITY'),
                  const SizedBox(height: 14),
                  ...[
                    ...state.recentActivity.take(3),
                    'Alex completed Take a Detour · +150 XP',
                    'Jordan discovered Nature + Creativity · Capture Nature',
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
