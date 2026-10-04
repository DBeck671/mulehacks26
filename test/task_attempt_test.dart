import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';
import 'package:sidequest/widgets/quest_timer.dart';

void main() {
  test('stop discards attempt without XP or log and permits a fresh start', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    final q = state.quest(2);
    final xp = state.totalXP;
    state.start(q);
    final attempt = q.attemptNumber;
    state.confirmHonor(q, true);
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
    state.confirmHonor(q, true);
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
