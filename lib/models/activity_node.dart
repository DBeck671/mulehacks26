import 'quest.dart';

enum NodeState { completed, available, locked, newlyUnlocked }

class ActivityNode {
  ActivityNode({
    required this.questId,
    required this.parentQuestIds,
    required this.childQuestIds,
    required this.categories,
    required this.state,
  });
  final int questId;
  final List<int> parentQuestIds, childQuestIds;
  final List<Category> categories;
  final NodeState state;
}
