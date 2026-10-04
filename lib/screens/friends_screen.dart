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

enum _FriendsView { clubs, discover }

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.state, this.openQuest});
  final AppState state;
  final ValueChanged<Quest>? openQuest;
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  AppState get state => widget.state;
  ValueChanged<Quest>? get openQuest => widget.openQuest;
  @override
  void initState() {
    super.initState();
    state.ensureDemoDiscovery();
    state.addListener(onClubChange);
  }

  _FriendsView view = _FriendsView.clubs;
  final Set<int> pendingApprovals = {};
  void onClubChange() {
    final approved = state.joinedGroups
        .where((c) => pendingApprovals.contains(c.id))
        .firstOrNull;
    if (approved == null) return;
    pendingApprovals.remove(approved.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => view = _FriendsView.clubs);
      if (state.sharedClubs) state.audio.play('join');
      showClubWelcome(context, approved.name);
    });
  }

  @override
  void dispose() {
    state.removeListener(onClubChange);
    super.dispose();
  }

  String search = '';
  final Set<int> busyClubs = {};

  Future<void> joinDiscovered(Group club) async {
    setState(() => busyClubs.add(club.id));
    try {
      final result = await state.joinClub(club);
      if (!mounted) return;
      if (result == JoinGroupResult.joined) {
        state.selectGroup(club.id);
        setState(() => view = _FriendsView.clubs);
        showClubWelcome(context, club.name);
      } else {
        if (result == JoinGroupResult.requested) pendingApprovals.add(club.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (result) {
              JoinGroupResult.requested => 'Request sent to ${club.name}.',
              JoinGroupResult.full => 'This club is full.',
              JoinGroupResult.alreadyActive => 'You are already a member.',
              _ => 'Could not join this club.',
            }),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not join. Check your connection and retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busyClubs.remove(club.id));
    }
  }

  Widget discoveryCard(Group club) {
    final pending = club.joinRequests.any(
      (r) =>
          r.uid == (state.clubService?.uid ?? 'demo-you') &&
          r.status == 'pending',
    );
    final private = club.visibility == ClubVisibility.private;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  private ? Icons.lock_outline : Icons.public,
                  size: 20,
                  color: context.palette.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${private ? "Private" : "Public"} · ${club.memberCount} / ${club.memberLimit} members${state.demoData ? " · Demo" : ""}',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        busyClubs.contains(club.id) || pending || club.isFull
                        ? null
                        : () => joinDiscovered(club),
                    child: Text(
                      busyClubs.contains(club.id)
                          ? 'PLEASE WAIT…'
                          : pending
                          ? 'REQUEST SENT'
                          : club.isFull
                          ? 'FULL'
                          : private
                          ? 'REQUEST TO JOIN'
                          : 'JOIN CLUB',
                    ),
                  ),
                ),
                if (private) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => showJoin(context),
                    child: const Text('USE CODE'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.palette.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${club.memberCount} / ${club.memberLimit} members · ${club.partyCompletedCount} of ${club.partyTasks.length} shared tasks done',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
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
                      style: TextButton.styleFrom(
                        foregroundColor: context.palette.muted,
                      ),
                      onPressed: busyClubs.contains(club.id)
                          ? null
                          : () async {
                              setState(() => busyClubs.add(club.id));
                              try {
                                await state.leaveClubOnline(club);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not leave. Please retry.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              } finally {
                                if (mounted) {
                                  setState(() => busyClubs.remove(club.id));
                                }
                              }
                              if (!context.mounted) return;
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
      if (state.hasGroup && view == _FriendsView.clubs) ...[
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
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<_FriendsView>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _FriendsView.clubs, label: Text('My clubs')),
            ButtonSegment(
              value: _FriendsView.discover,
              label: Text('Discover'),
            ),
          ],
          selected: {view},
          onSelectionChanged: (v) => setState(() => view = v.first),
        ),
      ),
      const SizedBox(height: 20),
      if (state.clubsLoading) const LinearProgressIndicator(),
      if (state.clubConnectionError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            state.clubConnectionError!,
            style: TextStyle(color: context.palette.muted),
          ),
        ),
      if (view == _FriendsView.clubs && !state.hasGroup)
        Panel(
          child: Text(
            'You are not in a group. Start a club or join with an invite.',
            style: TextStyle(color: context.palette.muted, height: 1.5),
          ),
        ),
      if (view == _FriendsView.clubs)
        ...state.joinedGroups.map((club) => clubCard(context, club)),
      if (view == _FriendsView.discover) ...[
        TextField(
          onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
          decoration: const InputDecoration(
            hintText: 'Find a club',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 18),
        if (!state.clubsLoading &&
            state.discoverableClubs
                .where((c) => c.name.toLowerCase().contains(search))
                .isEmpty)
          Text(
            'No clubs found. Start one and invite your crew.',
            style: TextStyle(color: context.palette.muted),
          ),
        ...state.discoverableClubs
            .where((c) => c.name.toLowerCase().contains(search))
            .map(discoveryCard),
      ],
    ],
  );
}
