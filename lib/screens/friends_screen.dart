import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';
import '../widgets/join_group_panel.dart';
import '../widgets/weekly_group_quest.dart';
import 'club_activity_screen.dart';
import '../widgets/start_club_panel.dart';
import '../widgets/club_invite_sheet.dart';
import '../models/quest.dart';
import '../models/group.dart';
import '../widgets/club_welcome.dart';

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
                JoinGroupPanel(
                  state: state,
                  onJoined: () {
                    Navigator.pop(sheetContext);
                    showClubWelcome(context, state.group.name);
                  },
                ),
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

  void openClub(BuildContext context, Group club) {
    state.selectGroup(club.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubActivityScreen(state: state, openQuest: openQuest),
      ),
    );
  }

  void showCode(BuildContext context, [Group? club]) {
    final invitedGroup = club ?? state.group;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ClubInviteSheet(club: invitedGroup),
    );
  }

  Widget clubCard(BuildContext context, Group club) => Padding(
    key: ValueKey('club-card-${club.id}'),
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      button: true,
      label: 'View ${club.name} club',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openClub(context, club),
          borderRadius: BorderRadius.circular(24),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (club.hostId == state.you.id) ...[
                  const Eyebrow('YOUR CLUB · HOST'),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        club.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${club.members.length} / ${club.memberLimit} members · ${club.partyCompletedCount} of ${club.partyTasks.length} shared tasks done',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showCode(context, club),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('INVITE FRIEND'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: muted),
                      onPressed: () {
                        state.leaveGroup(groupId: club.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Left ${club.name}')),
                        );
                      },
                      child: const Text('LEAVE GROUP'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading('Friends', ''),
      if (state.hasGroup) ...[
        WeeklyGroupQuest(state: state),
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
      const SizedBox(height: 24),
      if (!state.hasGroup)
        const Panel(
          child: Text(
            'You are not in a group. Start a club or join with an invite.',
            style: TextStyle(color: muted, height: 1.5),
          ),
        ),
      ...state.joinedGroups.map((club) => clubCard(context, club)),
    ],
  );
}
