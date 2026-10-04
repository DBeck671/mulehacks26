import 'dart:typed_data';

import 'gps_helpers.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/models/verification.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/quest.dart';

void main() {
  late AppState state;
  setUp(() => state = AppState());
  tearDown(() => state.dispose());
  CompletionResult finish(int id) {
    expect(state.start(state.quest(id)), isTrue);
    final q = state.quest(id);
    if (q.verification.method == VerificationMethod.location) {
      verifyGPS(state, q);
    } else {
      state.confirmHonor(q, true);
    }
    return state.complete(state.quest(id))!;
  }

  test('locked quests and duplicate completion taps cannot award XP', () {
    expect(state.start(state.quest(13)), isFalse);
    expect(state.complete(state.quest(13)), isNull);
    finish(1);
    expect(state.totalXP, 3855);
    expect(state.complete(state.quest(1)), isNull);
    expect(state.start(state.quest(1)), isTrue);
    expect(state.quest(1).verification.startLocation, isNull);
    expect(state.complete(state.quest(1)), isNull);
    expect(state.totalXP, 3855);
  });
  test(
    'successful repeat awards once with fresh evidence and keeps unlocks',
    () {
      finish(2);
      final q = state.quest(2);
      expect(state.quest(7).isLocked, isFalse);
      state.start(q);
      expect(q.status, 'Active');
      expect(q.verification.honorConfirmed, isFalse);
      expect(state.complete(q), isNull);
      state.setPhoto(q, Uint8List.fromList([1]));
      final second = state.complete(q)!;
      expect(second.unlocked, isEmpty);
      expect(state.complete(q), isNull);
      expect(q.completionCount, 2);
      expect(state.totalXP, 3855);
      expect(second.awardedXP, 25);
      expect(q.earnedXP, 75);
      state.start(q);
      expect(q.verification.photo, isNull);
      expect(state.quest(7).isLocked, isFalse);
    },
  );
  test('repeats pay half the base reward every time, rounded down with minimum one', () {
    final learning = state.quest(4);
    expect(finish(4).awardedXP, 75);
    expect(finish(4).awardedXP, 37);
    expect(finish(4).awardedXP, 37);
    expect(learning.earnedXP, 149);
    expect(state.you.xp, 1224);
    expect(state.completedActivities.map((e) => e.xp), [37, 37, 75]);
    final tiny = Quest(
      id: 99,
      title: 'Tiny task',
      description: 'A tiny test task',
      categories: [Category.learning],
      xp: 1,
      verification: Verification(
        method: VerificationMethod.reflection,
        prompt: 'Reflect',
      ),
    );
    state.quests.add(tiny);
    expect(finish(99).awardedXP, 1);
    expect(finish(99).awardedXP, 1);
    expect(tiny.earnedXP, 2);
    expect(state.complete(tiny), isNull);
  });
  test('walk unlocks park, and both connection parents are required', () {
    final walk = finish(1);
    expect(walk.unlocked.map((q) => q.id), contains(3));
    finish(3);
    expect(state.quest(13).isLocked, isTrue);
    final photograph = finish(2);
    expect(photograph.unlocked.map((q) => q.id), containsAll([7, 13]));
    expect(photograph.connections.single.title, 'Nature Photography');
    expect(state.quest(13).isNew, isTrue);
    expect(state.connectionCount, 7);
  });
  test('all four cross-category connections work in either parent order', () {
    finish(4);
    finish(5);
    expect(state.quest(15).isLocked, isFalse);
    finish(11);
    finish(9);
    final walk = finish(1);
    expect(walk.unlocked.map((q) => q.id), containsAll([3, 14, 16]));
    expect(walk.connections.length, 2);
    finish(2);
    finish(3);
    expect(state.connections.every((c) => c.isDiscovered), isTrue);
  });
  test(
    'XP carries across levels and updates ranks and group challenge once',
    () {
      finish(6); // +150 moves from #3 to #2.
      expect(state.rank, 2);
      final reward = finish(26); // +100 crosses 4000 XP and takes first place.
      expect(reward.oldXP, 3930);
      expect(state.level, 5);
      expect(state.levelXP, 30);
      expect(state.you.xp, 1325);
      expect(state.rank, 1);
      expect(state.group.weeklyChallengeProgress, 9);
      finish(8);
      expect(state.group.weeklyChallengeProgress, 10);
      expect(
        state.group.weeklyXP,
        state.group.members.fold<int>(500, (sum, f) => sum + f.xp),
      );
      finish(9);
      expect(state.group.weeklyChallengeProgress, 10);
    },
  );
  test('selected interests personalize the featured quest and one quest stays active', () {
    state.buildPath({Category.food, Category.learning});
    expect(state.featured.categories.any(state.interests.contains), isTrue);
    state.start(state.quest(5));
    state.start(state.quest(4));
    expect(state.active!.id, 4);
    expect(state.quest(5).isActive, isFalse);
    expect(state.nodes.firstWhere((n) => n.questId == 13).parentQuestIds, [
      3,
      2,
    ]);
  });
  test('each quest has a specific verification method and prompt', () {
    expect(state.quests.length, 26);
    expect(state.quests.every((q) => q.verification.prompt.isNotEmpty), isTrue);
    expect(state.quest(2).verification.method, VerificationMethod.photo);
    expect(state.quest(4).verification.method, VerificationMethod.reflection);
    expect(state.quest(1).verification.method, VerificationMethod.location);
  });
  test('evidence gates XP and can be removed before completion', () {
    final q = state.quest(2);
    state.start(q);
    expect(state.complete(q), isNull);
    state.setPhoto(q, Uint8List.fromList([1]));
    expect(q.verification.isSatisfied, isTrue);
    state.setPhoto(q, null);
    expect(state.complete(q), isNull);
    state.confirmHonor(q, true);
    expect(state.complete(q), isNotNull);
    expect(state.totalXP, 3830);
    expect(q.verification.recordedMethod, 'Honor-based confirmation');
  });
  test('reflection and checklist must meet their requirements', () {
    final learning = state.quest(4);
    state.start(learning);
    state.setReflection(learning, 'Too short');
    expect(state.complete(learning), isNull);
    state.setReflection(
      learning,
      'I learned how birds navigate using the stars.',
    );
    expect(state.complete(learning), isNotNull);
    final walk = state.quest(9);
    state.start(walk);
    state.setStep(walk, 0, true);
    expect(state.complete(walk), isNull);
    state.setStep(walk, 1, true);
    state.setStep(walk, 0, false);
    expect(state.complete(walk), isNull);
    state.setStep(walk, 0, true);
    expect(state.complete(walk), isNotNull);
  });
  test('evidence is quest-specific and cannot be edited after completion', () {
    final q = state.quest(4);
    state.setReflection(q, 'This quest has not started yet.');
    expect(q.verification.reflection, isEmpty);
    state.start(q);
    state.setReflection(q, 'This is a reflection on a new thing I learned.');
    state.start(state.quest(1));
    expect(state.quest(1).verification.isSatisfied, isFalse);
    state.start(q);
    expect(q.verification.isSatisfied, isTrue);
    state.complete(q);
    state.setReflection(q, '');
    state.confirmHonor(q, true);
    expect(q.verification.reflection, isNotEmpty);
    expect(q.verification.honorConfirmed, isFalse);
  });
}
