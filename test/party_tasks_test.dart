import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/quest.dart';
import 'package:sidequest/models/verification.dart';

import 'gps_helpers.dart';

import 'package:sidequest/screens/friends_screen.dart';

void verify(AppState state, Quest q) {
  if (q.verification.method == VerificationMethod.location) {
    verifyGPS(state, q);
  } else {
    state.confirmHonor(q, true);
  }
}

void main() {
  test('party gets three unique tasks, verifies them once, and generates a fresh round', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    final group = state.group;
    final ids = group.partyTasks.map((t) => t.questId).toList();
    expect(ids.toSet().length, 3);
    expect(ids.every((id) => !state.quest(id).isLocked), isTrue);
    expect(group.partyCompletedCount, 0);
    expect(state.generatePartyTasks(), isFalse);
    for (final id in ids) {
      expect(state.startPartyTask(id), isTrue);
      final q = state.quest(id);
      expect(state.complete(q), isNull);
      verify(state, q);
      final result = state.complete(q)!;
      final task = group.partyTasks.firstWhere((t) => t.questId == id);
      expect(task.completedByName, 'You');
      expect(task.earnedXP, result.awardedXP);
      expect(state.complete(q), isNull);
      expect(state.startPartyTask(id), isFalse);
    }
    expect(group.partyComplete, isTrue);
    expect(group.partyCompletedCount, 3);
    expect(state.generatePartyTasks(), isTrue);
    expect(group.partyRound, 2);
    expect(group.partyCompletedCount, 0);
    expect(
      group.partyTasks.map((t) => t.questId).toSet().difference(ids.toSet()),
      isNotEmpty,
    );
  });

  test(
    'switching groups credits the original party, leaving cancels credit',
    () {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final original = state.group;
      final id = original.partyTasks.first.questId;
      state.startPartyTask(id);
      state.joinGroup('INV-7319');
      final other = state.group;
      verify(state, state.quest(id));
      state.complete(state.quest(id));
      expect(original.partyCompletedCount, 1);
      expect(original.weeklyChallengeProgress, 8);
      expect(other.partyCompletedCount, 0);
      expect(other.weeklyChallengeProgress, 7);
      state.selectGroup(1);
      final pending = original.partyTasks
          .firstWhere((t) => !t.isCompleted)
          .questId;
      state.startPartyTask(pending);
      state.leaveGroup();
      state.joinGroup('INV-4821');
      verify(state, state.quest(pending));
      state.complete(state.quest(pending));
      expect(original.partyCompletedCount, 1);
    },
  );

  test(
    'party task needs fresh evidence and solo completions do not fill it',
    () {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final task = state.group.partyTasks.first;
      final q = state.quest(task.questId);
      state.start(q);
      verify(state, q);
      expect(q.verification.isSatisfied, isTrue);
      state.startPartyTask(q.id);
      expect(q.verification.isSatisfied, isFalse);
      expect(state.complete(q), isNull);
      verify(state, q);
      state.stop(q); // Explicitly abandon the party attempt.
      state.start(state.quest(q.id == 4 ? 2 : 4));
      state.start(q);
      verify(state, q);
      state.complete(q);
      expect(task.isCompleted, isFalse);
    },
  );

  testWidgets(
    'Friends launches party tasks, shows member credit, and starts next round',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      Quest? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (_, _) =>
                  FriendsScreen(state: state, openQuest: (q) => selected = q),
            ),
          ),
        ),
      );
      expect(find.text('0 / 3 party tasks completed'), findsNothing);
      expect(find.text('RECENT ACTIVITY'), findsNothing);
      await tester.ensureVisible(find.text(state.group.name));
      await tester.tap(find.text(state.group.name));
      await tester.pumpAndSettle();
      expect(find.text('0 / 3 party tasks completed'), findsOneWidget);
      await tester.ensureVisible(find.text('DO PARTY TASK →').first);
      await tester.tap(find.text('DO PARTY TASK →').first);
      await tester.pumpAndSettle();
      expect(selected, same(state.active));
      verify(state, selected!);
      state.complete(selected!);
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 party tasks completed'), findsOneWidget);
      expect(find.textContaining('Completed by You'), findsOneWidget);
      for (final task
          in state.group.partyTasks.where((t) => !t.isCompleted).toList()) {
        state.startPartyTask(task.questId);
        verify(state, state.quest(task.questId));
        state.complete(state.quest(task.questId));
      }
      await tester.pumpAndSettle();
      expect(find.text('Party list complete!'), findsOneWidget);
      await tester.ensureVisible(find.text('GENERATE NEXT PARTY LIST'));
      await tester.tap(find.text('GENERATE NEXT PARTY LIST'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 3 party tasks completed'), findsOneWidget);
      expect(find.text('PARTY TASKS · ROUND 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
