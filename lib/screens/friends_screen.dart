import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';
import '../widgets/join_group_panel.dart';
import '../widgets/weekly_group_quest.dart';
import 'club_activity_screen.dart';
import '../widgets/start_club_panel.dart';
import '../widgets/club_invite_sheet.dart';
import '../models/quest.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.state, this.openQuest});
  final AppState state;
  final ValueChanged<Quest>? openQuest;
  void showJoin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                JoinGroupPanel(state: state),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('DONE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showCode(BuildContext context) {
    final invitedGroup = state.group;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ClubInviteSheet(club: invitedGroup),
    );
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading('Friends', ''),
      if (state.hasGroup) ...[
        WeeklyGroupQuest(state: state),
        const SizedBox(height: 20),
        if (state.joinedGroups.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.joinedGroups
                .map(
                  (g) => ChoiceChip(
                    label: Text(g.name),
                    selected: state.activeGroupId == g.id,
                    onSelected: (_) => state.selectGroup(g.id),
                    showCheckmark: false,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.group.hostId == state.you.id) ...[
                const Eyebrow('YOUR CLUB · HOST'),
                const SizedBox(height: 10),
              ],
              Text(
                state.group.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.group.members.length} ${state.group.members.length == 1 ? 'member' : 'members'} · ${state.group.partyCompletedCount} of ${state.group.partyTasks.length} shared tasks done',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubActivityScreen(
                        state: state,
                        openQuest: openQuest,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.checklist_rounded, size: 20),
                  label: const Text('Club Activity'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showCode(context),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('INVITE FRIEND'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: const Border(),
          collapsedShape: const Border(),
          title: const Text(
            'Members',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          children: state.group.members
              .map(
                (f) => ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: raised,
                    child: Text(
                      f.avatarInitial,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    state.showcaseMode && f.id != 0
                        ? '${f.name} · bot'
                        : f.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: f.id == state.group.hostId
                      ? const Text(
                          'Host',
                          style: TextStyle(color: muted, fontSize: 11),
                        )
                      : null,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
      ] else ...[
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.groups_outlined, color: green, size: 32),
              SizedBox(height: 16),
              Text(
                'Find your people.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                'You are not in a group. Start a club or join with an invite to complete a shared task list.',
                style: TextStyle(color: muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          StartClubPanel(
            state: state,
            compact: true,
            onCreated: () => showCode(context),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => showJoin(context),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('JOIN A GROUP'),
          ),
        ],
      ),
      if (state.hasGroup) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            final name = state.group.name;
            state.leaveGroup();
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Left $name')));
          },
          child: const Text('LEAVE GROUP'),
        ),
      ],
    ],
  );
}
