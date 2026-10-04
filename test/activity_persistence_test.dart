import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/data/activity_store.dart';

class MemoryStore implements ActivityStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String data) async {
    if (fail) throw StateError('Storage unavailable');
    value = data;
  }
}

void finish(AppState state) {
  final q = state.quest(4);
  state.start(q);
  state.setReflection(q, 'I learned how to preserve my task history today.');
  expect(state.complete(q), isNotNull);
}

void main() {
  test(
    'reopening restores every repeat, timestamps, verification, XP and reward',
    () async {
      final store = MemoryStore();
      final first = await AppState.load(store, demoData: true);
      first.setProfile('Taylor', 'Prefer not to say');
      finish(first);
      finish(first);
      await first.historySaved;
      final time = first.completedActivities.first.completedAt;
      first.dispose();
      final restored = await AppState.load(store, demoData: true);
      addTearDown(restored.dispose);
      expect(restored.profileName, 'Taylor');
      expect(restored.you.name, 'Taylor');
      expect(restored.profileGender, 'Prefer not to say');
      expect(restored.completedActivities.length, 2);
      expect(restored.completedActivities.map((e) => e.xp), [37, 75]);
      expect(
        restored.completedActivities.first.completedAt.isAtSameMomentAs(time),
        isTrue,
      );
      expect(
        restored.completedActivities.first.verificationMethod,
        'Short reflection',
      );
      expect(restored.quest(4).completionCount, 2);
      expect(restored.quest(4).rewardXP, 37);
      expect(restored.totalXP, 3892);
      finish(restored);
      await restored.historySaved;
      final again = await AppState.load(store, demoData: true);
      addTearDown(again.dispose);
      expect(again.completedActivities.length, 3);
      expect(again.completedActivities.map((e) => e.attempt), [3, 2, 1]);
      expect(again.totalXP, 3929);
    },
  );

  test(
    'sign-out disposal retains saved history without sharing another account',
    () async {
      final accountA = MemoryStore(), accountB = MemoryStore();
      final state = await AppState.load(accountA, demoData: true);
      finish(state);
      state.dispose();
      await state.historySaved;
      final other = await AppState.load(accountB, demoData: true);
      final sameAccount = await AppState.load(accountA, demoData: true);
      addTearDown(other.dispose);
      addTearDown(sameAccount.dispose);
      expect(other.completedActivities, isEmpty);
      expect(sameAccount.completedActivities.length, 1);
    },
  );

  test(
    'storage failure keeps in-memory entries and retry saves them',
    () async {
      final store = MemoryStore();
      final state = await AppState.load(store, demoData: true);
      addTearDown(state.dispose);
      store.fail = true;
      finish(state);
      await state.historySaved;
      expect(state.historySaveFailed, isTrue);
      expect(state.completedActivities.length, 1);
      store.fail = false;
      state.retryHistorySave();
      await state.historySaved;
      expect(state.historySaveFailed, isFalse);
      final restored = await AppState.load(store, demoData: true);
      addTearDown(restored.dispose);
      expect(restored.completedActivities.length, 1);
    },
  );

  test('unreadable history is not silently erased', () async {
    final store = MemoryStore()..value = 'invalid stored history';
    await expectLater(
      AppState.load(store, demoData: true),
      throwsFormatException,
    );
    expect(store.value, 'invalid stored history');
  });
}
