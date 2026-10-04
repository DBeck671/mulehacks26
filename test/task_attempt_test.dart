import 'evidence_helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';
import 'package:sidequest/widgets/quest_timer.dart';
import 'package:sidequest/screens/main_screen.dart';
import 'package:sidequest/widgets/quest_row_card.dart';

void main() {
  test('club starts enforce the same limit and reopening preserves a paused attempt', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    final id = state.group.partyTasks.first.questId;
    final q = state.quest(id);
    final others = state.quests
        .where((other) => !other.isLocked && other.id != id)
        .take(2)
        .toList();
    state.start(others[0]);
    state.start(others[1]);
    expect(state.startPartyTask(id), isFalse);
    expect(q.isActive, isFalse);
    expect(q.attemptNumber, 0);
    state.stop(others[0]);
    expect(state.startPartyTask(id), isTrue);
    state.pauseTask(q);
    final attempt = q.attemptNumber;
    expect(state.startPartyTask(id), isTrue);
    expect(q.attemptClock.isRunning, isFalse);
    expect(q.attemptNumber, attempt);
  });
  test('two active attempts include paused tasks; blocked starts preserve evidence', () {
    final state = AppState();
    addTearDown(state.dispose);
    final first = state.quest(2),
        second = state.quest(5),
        third = state.quest(4);
    expect(state.start(first), isTrue);
    state.pauseTask(first);
    expect(state.start(second), isTrue);
    state.pauseTask(second);
    final attempt = third.attemptNumber;
    expect(state.start(third), isFalse);
    expect(third.attemptNumber, attempt);
    expect(state.activeQuests.length, 2);
    expect(
      state.start(first),
      isTrue,
    ); // An explicit resume uses its existing slot.
    state.stop(second);
    expect(state.start(third), isTrue);
    expect(state.activeQuests.length, 2);
  });

  testWidgets('opening a paused active quest keeps it paused until Resume', (
    tester,
  ) async {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(2);
    state.start(q);
    state.pauseTask(q);
    final attempt = q.attemptNumber;
    await tester.pumpWidget(MaterialApp(home: MainScreen(state: state)));
    await tester.tap(find.text('Quests').last);
    await tester.pumpAndSettle();
    final card = find.byType(QuestRowCard).at(1);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(q.attemptClock.isRunning, isFalse);
    expect(q.attemptNumber, attempt);
    expect(find.text('Resume timer'), findsOneWidget);
    await tester.ensureVisible(find.text('Resume timer'));
    await tester.tap(find.text('Resume timer'));
    await tester.pump();
    expect(q.attemptClock.isRunning, isTrue);
  });
  test('stop discards attempt without XP or log and permits a fresh start', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    final q = state.quest(2);
    final xp = state.totalXP;
    state.start(q);
    final attempt = q.attemptNumber;
    verifyNonLocation(state, q);
    expect(q.attemptClock.isRunning, isTrue);
    expect(state.stop(q), isTrue);
    expect(q.isActive, isFalse);
    expect(q.isCompleted, isFalse);
    expect(q.verification.isSatisfied, isFalse);
    expect(q.attemptClock.isRunning, isFalse);
    expect(q.attemptClock.elapsed, Duration.zero);
    expect(state.totalXP, xp);
    expect(state.completedActivities, isEmpty);
    state.failLocation(q, 'late callback', attempt: attempt);
    expect(q.verification.locationError, isNull);
    expect(state.complete(q), isNull);
    state.start(q);
    expect(q.attemptClock.isRunning, isTrue);
    verifyNonLocation(state, q);
    expect(state.complete(q), isNotNull);
    final earned = state.totalXP;
    state.start(q);
    state.stop(q);
    expect(state.totalXP, earned);
    expect(q.completionCount, 1);
    expect(q.isCompleted, isTrue);
    expect(state.completedActivities.length, 1);
  });

  testWidgets('timer pauses, resumes and stop exits without logging', (
    tester,
  ) async {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    final q = state.quest(2);
    state.start(q);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestDetailScreen(state: state, quest: q),
                ),
              ),
              child: const Text('Open task'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open task'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestTimer), findsOneWidget);
    await tester.ensureVisible(find.text('Pause timer'));
    await tester.tap(find.text('Pause timer'));
    await tester.pump();
    expect(q.attemptClock.isRunning, isFalse);
    expect(find.text('TIMER PAUSED'), findsOneWidget);
    await tester.tap(find.text('Resume timer'));
    await tester.pump();
    expect(q.attemptClock.isRunning, isTrue);
    await tester.ensureVisible(find.text('Stop task'));
    await tester.tap(find.text('Stop task'));
    await tester.pumpAndSettle();
    expect(find.text('Open task'), findsOneWidget);
    expect(q.isActive, isFalse);
    expect(state.completedActivities, isEmpty);
  });
}
