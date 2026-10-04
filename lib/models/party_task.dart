// A task belongs to one party round; successful attempts credit it once.
class PartyTask {
  PartyTask({required this.questId});
  final int questId;
  int? completedById;
  String? completedByName;
  DateTime? completedAt;
  int earnedXP = 0;
  bool get isCompleted => completedAt != null;
}

class PartyAttempt {
  const PartyAttempt(this.groupId, this.round, this.questId, this.attempt);
  final int groupId, round, questId, attempt;
}
