import 'evidence_helpers.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/quest.dart';

import 'activity_persistence_test.dart' show MemoryStore;

void main() {
  test('new real account starts empty with no seeded progress or clubs', () {
    final state = AppState();
    addTearDown(state.dispose);
    expect(state.level, 1);
    expect(state.totalXP, 0);
    expect(state.you.xp, 0);
    expect(state.you.questsCompleted, 0);
    expect(state.completedCount, 0);
    expect(state.connectionCount, 0);
    expect(state.achievements.every((a) => !a), isTrue);
    expect(state.completedActivities, isEmpty);
    expect(state.groups, isEmpty);
    expect(state.hasGroup, isFalse);
    expect(state.hasProfile, isFalse);
    expect(state.interests, isEmpty);
  });

  test(
    'accounts independently retain their profile, interests and earned XP',
    () async {
      final storeA = MemoryStore(), storeB = MemoryStore();
      final first = await AppState.load(storeA);
      first.setProfile('Taylor', 'Prefer not to say');
      first.buildPath({Category.nature, Category.creativity});
      final q = first.quest(2);
      first.start(q);
      verifyNonLocation(first, q);
      first.complete(q);
      await first.historySaved;
      first.dispose();
      final second = await AppState.load(storeB);
      final restored = await AppState.load(storeA);
      addTearDown(second.dispose);
      addTearDown(restored.dispose);
      expect(second.totalXP, 0);
      expect(second.profileName, isEmpty);
      expect(second.interests, isEmpty);
      expect(second.completedActivities, isEmpty);
      expect(restored.totalXP, 50);
      expect(restored.you.xp, 50);
      expect(restored.you.name, 'Taylor');
      expect(restored.interests, {Category.nature, Category.creativity});
      expect(restored.completedCount, 1);
      expect(restored.completedActivities.length, 1);
    },
  );
}
