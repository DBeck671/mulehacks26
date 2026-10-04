class Connection {
  Connection({
    required this.id,
    required this.requiredQuestIds,
    required this.unlockedQuestId,
    required this.title,
    this.isDiscovered = false,
  });
  final int id, unlockedQuestId;
  final List<int> requiredQuestIds;
  final String title;
  bool isDiscovered;
}
