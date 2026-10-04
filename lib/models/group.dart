import 'friend.dart';
import 'party_task.dart';

enum ClubVisibility { public, private }

class ClubJoinRequest {
  ClubJoinRequest(this.uid, this.name, {this.status = 'pending'});
  final String uid, name;
  String status;
}

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
    this.memberLimit = 5,
    this.visibility = ClubVisibility.private,
    this.cloudId,
    this.hostUid,
    this.directoryMemberCount,
  });
  final int id, weeklyChallengeGoal;
  int hostId;
  final ClubVisibility visibility;
  final String? cloudId, hostUid;
  int? directoryMemberCount;
  final List<ClubJoinRequest> joinRequests = [];
  int get memberCount => directoryMemberCount ?? members.length;
  final String name;
  String groupCode, inviteCode;
  final List<Friend> members;
  static const minMemberLimit = 2;
  static const maxMemberLimit = 100;
  int memberLimit;
  bool get isFull => memberCount >= memberLimit;
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
