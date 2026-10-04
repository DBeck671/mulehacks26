import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import '../widgets/party_tasks_panel.dart';
import 'quest_detail_screen.dart';
import 'club_chat_screen.dart';
import '../widgets/member_badge.dart';

enum _ClubView { tasks, members, activity }

class ClubActivityScreen extends StatefulWidget {
  const ClubActivityScreen({super.key, required this.state, this.openQuest});
  final AppState state;
  final ValueChanged<Quest>? openQuest;
  @override
  State<ClubActivityScreen> createState() => _ClubActivityScreenState();
}

class _ClubActivityScreenState extends State<ClubActivityScreen> {
  _ClubView view = _ClubView.tasks;
  AppState get state => widget.state;
  void openPartyTask(BuildContext context, Quest quest) {
    if (!state.startPartyTask(quest.id)) {
      if (!state.canStart(quest)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two quests are active. Complete or stop one first.'),
          ),
        );
      }
      return;
    }
    if (widget.openQuest != null) {
      widget.openQuest!(quest);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestDetailScreen(state: state, quest: quest),
        ),
      );
    }
  }

  List<Widget> tasks(BuildContext context) => [
    PartyTasksPanel(state: state, openQuest: (q) => openPartyTask(context, q)),
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
              (t) => !t.isCompleted && !state.quest(t.questId).isActive,
            )
            ? () => state.simulateFriendCompletion()
            : null,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Let a demo friend complete a task'),
      ),
    ],
  ];

  List<Widget> members() => [
    ...state.group.members.map(
      (f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: raised,
              child: Text(f.avatarInitial),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.showcaseMode && f.id != 0 ? '${f.name} · bot' : f.name,
                ),
                if (state.badgeFor(f) case final badge?) ...[
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MemberBadge(badge: badge),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${f.xp} XP · ${f.questsCompleted} quests',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            trailing: f.id == state.group.hostId
                ? const Text(
                    'Host',
                    style: TextStyle(color: green, fontSize: 12),
                  )
                : null,
          ),
        ),
      ),
    ),
  ];

  List<Widget> activity() => [
    const Eyebrow('RECENT ACTIVITY'),
    const SizedBox(height: 14),
    if (state.clubRecentActivity.isEmpty)
      const Panel(
        child: Text(
          'Completed team tasks will appear here.',
          style: TextStyle(color: muted),
        ),
      ),
    ...state.clubRecentActivity.map(
      (text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: green),
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
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Club Activity'),
        actions: [
          if (state.hasGroup)
            IconButton(
              tooltip: 'Group chat',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ClubChatScreen(state: state, club: state.group),
                ),
              ),
            ),
        ],
      ),
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
                    '${state.group.members.length} members',
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_ClubView>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _ClubView.tasks,
                          label: Text('Tasks'),
                        ),
                        ButtonSegment(
                          value: _ClubView.members,
                          label: Text('Members'),
                        ),
                        ButtonSegment(
                          value: _ClubView.activity,
                          label: Text('Activity'),
                        ),
                      ],
                      selected: {view},
                      onSelectionChanged: (selected) =>
                          setState(() => view = selected.first),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...switch (view) {
                    _ClubView.tasks => tasks(context),
                    _ClubView.members => members(),
                    _ClubView.activity => activity(),
                  },
                ],
              ),
      ),
    ),
  );
}
