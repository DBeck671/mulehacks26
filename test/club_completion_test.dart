import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/quest_complete_screen.dart';
import 'package:sidequest/screens/club_activity_screen.dart';

import 'party_tasks_test.dart' show verify;

CompletionResult finishClub(AppState state, int id) {
  expect(state.startPartyTask(id), isTrue);
  verify(state, state.quest(id));
  return state.complete(state.quest(id))!;
}

void main() {
  testWidgets(
    'club completion shows only its shared list and continues with club credit',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final club = state.group;
      final result = finishClub(state, club.partyTasks.first.questId);
      expect(result.club!.completedIds.length, 1);
      expect(result.club!.taskIds, club.partyTasks.map((t) => t.questId));
      await tester.pumpWidget(
        MaterialApp(
          home: QuestCompleteScreen(state: state, result: result),
        ),
      );
      expect(find.byKey(const ValueKey('club-progress')), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 club tasks completed'), findsOneWidget);
      expect(find.text('What will you do next?'), findsNothing);
      expect(find.byKey(const ValueKey('suggested-tasks')), findsNothing);
      expect(find.text('CONTINUE CLUB TASK'), findsNWidgets(2));
      await tester.ensureVisible(find.text('CONTINUE CLUB TASK').first);
      await tester.tap(find.text('CONTINUE CLUB TASK').first);
      await tester.pump();
      final next = state.active!;
      expect(
        club.partyTasks.any((t) => t.questId == next.id && !t.isCompleted),
        isTrue,
      );
      verify(state, next);
      final nextResult = state.complete(next)!;
      expect(nextResult.club!.completedIds.length, 2);
      // Earlier completion results remain snapshots of the completed attempt.
      expect(result.club!.completedIds.length, 1);
    },
  );

  testWidgets(
    'finished club list celebrates the goal without generating or recommending tasks',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final club = state.group;
      CompletionResult? result;
      for (final task in club.partyTasks.toList()) {
        result = finishClub(state, task.questId);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: QuestCompleteScreen(state: state, result: result!),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Club task list complete!'), findsOneWidget);
      expect(find.text('3 / 3 club tasks completed'), findsOneWidget);
      expect(find.text('CONTINUE CLUB TASK'), findsNothing);
      expect(find.text('RETURN TO CLUB'), findsOneWidget);
      expect(find.text('RETURN TO HOME'), findsNothing);
      expect(find.text('What will you do next?'), findsNothing);
      expect(club.partyRound, 1);
      expect(club.partyComplete, isTrue);
    },
  );

  testWidgets('return to club returns to its activity page instead of home', (
    tester,
  ) async {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ClubActivityScreen(state: state)),
    );
    await tester.ensureVisible(find.text('DO PARTY TASK →').first);
    await tester.tap(find.text('DO PARTY TASK →').first);
    await tester.pumpAndSettle();
    verify(state, state.active!);
    await tester.pump();
    await tester.ensureVisible(find.text('COMPLETE SIDEQUEST'));
    await tester.tap(find.text('COMPLETE SIDEQUEST'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('RETURN TO CLUB'));
    await tester.tap(find.text('RETURN TO CLUB'));
    await tester.pumpAndSettle();
    expect(find.text('Club Activity'), findsOneWidget);
    expect(find.text('1 / 3 party tasks completed'), findsOneWidget);
  });
}
