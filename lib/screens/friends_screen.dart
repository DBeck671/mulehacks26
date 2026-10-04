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
      const PageHeading('Friends', 'Your clubs. Your people.'),
      if (state.hasGroup) ...[
        WeeklyGroupQuest(state: state),
        const SizedBox(height: 24),
      ],
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          StartClubPanel(
            state: state,
            compact: true,
            onCreated: () => showCode(context),
          ),
          OutlinedButton.icon(
            onPressed: () => showJoin(context),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('JOIN A GROUP'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (!state.hasGroup)
        const Panel(
          child: Text(
            'You are not in a group. Join a crew to share your next adventure.',
            style: TextStyle(color: muted, height: 1.6),
          ),
        )
      else ...[
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
          const SizedBox(height: 20),
        ],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.group.name,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.group.members.length} ${state.group.members.length == 1 ? 'member' : 'members'}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              if (state.group.hostId == state.you.id) ...[
                const SizedBox(height: 8),
                const Text(
                  'YOUR CLUB · HOST',
                  style: TextStyle(color: green, fontSize: 11),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showCode(context),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('INVITE FRIEND'),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: raised),
              ...state.group.members.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: raised,
                        child: Text(
                          f.avatarInitial,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (f.id == state.group.hostId)
                        const Text(
                          'Host',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt_outlined, color: green),
              title: const Text(
                'Club Activity',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Party tasks & updates',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: muted,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ClubActivityScreen(state: state, openQuest: openQuest),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
