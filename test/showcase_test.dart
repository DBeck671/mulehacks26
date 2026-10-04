import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/main_screen.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';

void main() {
  testWidgets(
    'next button and swipe browse without starting tasks or stacking routes',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuestDetailScreen(state: state, quest: state.quest(2)),
                  ),
                ),
                child: const Text('Open quest'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open quest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next quest'));
      await tester.pumpAndSettle();
      final next = tester
          .widget<QuestDetailScreen>(find.byType(QuestDetailScreen))
          .quest;
      expect(next.id, isNot(2));
      expect(next.isLocked, isFalse);
      await tester.fling(
        find.text(next.description),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      final afterSwipe = tester
          .widget<QuestDetailScreen>(find.byType(QuestDetailScreen))
          .quest;
      expect(afterSwipe.id, isNot(next.id));
      expect(state.activeQuests, isEmpty);
      expect(state.totalXP, 0);
      expect(state.completedActivities, isEmpty);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open quest'), findsOneWidget);
      expect(find.byType(QuestDetailScreen), findsNothing);
    },
  );
  testWidgets(
    'every demo club gets bots, scoped activity and pausable automatic contributions',
    (tester) async {
      final state = AppState(demoData: true, showcaseMode: true);
      state.audio.enabled = false;
      addTearDown(state.dispose);
      state.setDemoBotsRunning(true);
      expect(state.group.partyCompletedCount, 1);
      final original = state.group;
      final club = state.createClub('Demo crew');
      expect(club.members.length, 5);
      expect(club.partyCompletedCount, 1);
      final firstEntry = state.clubRecentActivity.single;
      expect(firstEntry, contains('(bot) completed'));
      await tester.pump(const Duration(seconds: 12));
      expect(club.partyCompletedCount, 2);
      expect(state.clubRecentActivity.length, 2);
      expect(original.partyCompletedCount, 1);
      expect(
        original.members.first.xp,
        1250 + state.quest(original.partyTasks.first.questId).rewardXP,
      );
      state.setDemoBotsRunning(false);
      await tester.pump(const Duration(seconds: 24));
      expect(club.partyCompletedCount, 2);
      state.selectGroup(original.id);
      expect(state.clubRecentActivity.length, 1);
      expect(state.completedActivities, isEmpty);
      expect(state.earnedXP, 0);
    },
  );
  test(
    'concurrent club attempts retain their own credit when another task stops',
    () {
      final state = AppState(demoData: true, showcaseMode: true);
      state.audio.enabled = false;
      addTearDown(state.dispose);
      final ids = state.group.partyTasks.map((t) => t.questId).take(2).toList();
      for (final id in ids) {
        state.startPartyTask(id);
        state.simulateVerification(state.quest(id));
      }
      final solo = state.quests.firstWhere(
        (q) => !q.isLocked && !ids.contains(q.id),
      );
      state.start(solo);
      state.stop(solo);
      for (final id in ids) {
        expect(state.complete(state.quest(id))!.club, isNotNull);
      }
      expect(state.group.partyCompletedCount, 2);
    },
  );
  test('demo simulation is unavailable to real accounts', () {
    final state = AppState();
    addTearDown(state.dispose);
    state.start(state.quest(1));
    expect(state.simulateVerification(state.quest(1)), isFalse);
    expect(state.complete(state.quest(1)), isNull);
    expect(state.simulateFriendCompletion(), isFalse);
    expect(() => AppState(showcaseMode: true), throwsArgumentError);
  });
  test('bots credit club progress without awarding personal XP or history', () {
    final state = AppState(demoData: true, showcaseMode: true);
    state.audio.enabled = false;
    addTearDown(state.dispose);
    final xp = state.totalXP;
    final task = state.group.partyTasks.first;
    state.startPartyTask(task.questId);
    expect(state.simulateFriendCompletion(), isTrue);
    expect(task.isCompleted, isFalse); // Never steals an active user task.
    expect(state.group.partyCompletedCount, 1);
    expect(state.totalXP, xp);
    expect(state.completedActivities, isEmpty);
    expect(state.simulateVerification(state.quest(task.questId)), isTrue);
    final result = state.complete(state.quest(task.questId))!;
    expect(result.club!.completedIds.length, 2);
    expect(
      state.completedActivities.single.verificationMethod,
      'Demo simulation',
    );
    state.start(state.quest(task.questId));
    expect(state.quest(task.questId).verification.demoVerified, isFalse);
  });
  testWidgets('Active tab lists started tasks and removes stopped tasks', (
    tester,
  ) async {
    final state = AppState();
    addTearDown(state.dispose);
    state.start(state.quest(2));
    state.start(state.quest(4));
    state.setReflection(state.quest(4), 'A useful thing I learned today.');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (_, _) => QuestsScreen(state: state, openQuest: (_) {}),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Active (2)'));
    await tester.pump();
    expect(find.text(state.quest(2).title), findsOneWidget);
    expect(find.text(state.quest(4).title), findsOneWidget);
    expect(find.text(state.quest(1).title), findsNothing);
    final attempt = state.quest(4).attemptNumber;
    state.start(state.quest(4));
    expect(state.quest(4).attemptNumber, attempt);
    expect(state.quest(4).verification.isSatisfied, isTrue);
    state.stop(state.quest(2));
    await tester.pump();
    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.text(state.quest(2).title), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
