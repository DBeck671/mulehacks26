import 'friend.dart';
import 'party_task.dart';

class Group {
  Group({
    required this.id,
    required this.name,
    required this.members,
    this.weeklyChallengeGoal = 10,
    this.weeklyChallengeProgress = 7,
    this.groupCode = 'SQ-4821',
    this.inviteCode = 'INV-4821',
    this.hostId = 1,
  });
  final int id, weeklyChallengeGoal, hostId;
  final String name, groupCode, inviteCode;
  final List<Friend> members;
  int weeklyChallengeProgress;
  int partyRound = 0;
  final List<PartyTask> partyTasks = [];
  int get partyCompletedCount => partyTasks.where((t) => t.isCompleted).length;
  bool get partyComplete =>
      partyTasks.isNotEmpty && partyTasks.every((t) => t.isCompleted);
  // The group's XP always uses the same member values as its leaderboard.
  int get weeklyXP =>
      members.fold(0, (sum, member) => sum + member.xp) +
      (weeklyChallengeProgress >= weeklyChallengeGoal ? 500 : 0);
}
