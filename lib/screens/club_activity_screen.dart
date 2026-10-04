import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../models/group.dart';
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
        activeTrackColor: context.palette.green,
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

  final Set<String> reviewing = {};
  Future<void> review(ClubJoinRequest request, bool approve) async {
    if (!reviewing.add(request.uid)) return;
    try {
      await state.reviewClubRequest(state.group, request, approve);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FormatException
                  ? e.message
                  : 'Could not review request. Please retry.',
            ),
          ),
        );
      }
    } finally {
      reviewing.remove(request.uid);
    }
  }

  void editMemberSlots() {
    final club = state.group;
    showDialog<void>(
      context: context,
      builder: (_) => _MemberSlotsDialog(
        state: state,
        groupId: club.id,
        memberLimit: club.memberLimit,
      ),
    );
  }

  List<Widget> members() => [
    if (state.group.hostId == state.you.id) ...[
      for (final request in state.group.joinRequests.where(
        (r) => r.status == 'pending',
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request.name} wants to join'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => review(request, true),
                      child: const Text('APPROVE'),
                    ),
                    TextButton(
                      onPressed: () => review(request, false),
                      child: const Text('DECLINE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
    if (state.group.hostId == state.you.id)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton.icon(
          onPressed: editMemberSlots,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text('MEMBER SLOTS · ${state.group.memberLimit}'),
        ),
      ),
    ...state.group.members.map(
      (f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: context.palette.raised,
              child: Text(f.avatarInitial),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.showcaseMode && f.id != 0 ? '${f.name} · bot' : f.name,
                ),
                if (state.badgesFor(f).isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final badge in state.badgesFor(f))
                        MemberBadge(badge: badge),
                    ],
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${f.xp} XP · ${f.questsCompleted} quests',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            trailing: f.id == state.group.hostId
                ? Text(
                    'Host',
                    style: TextStyle(
                      color: context.palette.green,
                      fontSize: 12,
                    ),
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
      Panel(
        child: Text(
          'Completed team tasks will appear here.',
          style: TextStyle(color: context.palette.muted),
        ),
      ),
    ...state.clubRecentActivity.map(
      (text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: context.palette.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: context.palette.muted,
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
                    '${state.group.members.length} / ${state.group.memberLimit} members',
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

class _MemberSlotsDialog extends StatefulWidget {
  const _MemberSlotsDialog({
    required this.state,
    required this.groupId,
    required this.memberLimit,
  });
  final AppState state;
  final int groupId, memberLimit;
  @override
  State<_MemberSlotsDialog> createState() => _MemberSlotsDialogState();
}

class _MemberSlotsDialogState extends State<_MemberSlotsDialog> {
  late final controller = TextEditingController(text: '${widget.memberLimit}');
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Member slots'),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: 'Member slots',
        helperText: '2–100, including you',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: () async {
          try {
            await widget.state.setClubMemberLimitOnline(
              widget.groupId,
              int.tryParse(controller.text) ?? 0,
            );
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) {
              setState(
                () => error = e is FormatException
                    ? e.message
                    : 'Could not save. Please retry.',
              );
            }
          }
        },
        child: const Text('SAVE'),
      ),
    ],
  );
}
