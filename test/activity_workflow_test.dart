import 'dart:math';

import 'package:flutter/material.dart';

import 'gps_helpers.dart';

import 'package:sidequest/models/verification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/main_screen.dart';
import 'package:sidequest/screens/quest_complete_screen.dart';
import 'package:sidequest/screens/activity_log_screen.dart';
import 'package:sidequest/widgets/common.dart';

void main() {
  test(
    'each repeat creates a snapshot and three available follow-up choices',
    () {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final q = state.quest(4);
      for (var i = 0; i < 2; i++) {
        state.start(q);
        state.setReflection(q, 'My new learning reflection for attempt $i.');
        expect(state.complete(q), isNotNull);
        expect(state.complete(q), isNull);
        final options = state.suggestedNextTasks(q);
        expect(options.length, 3);
        expect(options, isNot(contains(same(q))));
        expect(options.map((q) => q.id).toSet().length, 3);
        expect(options.every((q) => !q.isLocked), isTrue);
      }
      expect(state.completedActivities.length, 2);
      expect(state.completedActivities.map((e) => e.attempt), [2, 1]);
      expect(state.completedActivities.map((e) => e.xp), [37, 75]);
      state.start(q);
      expect(q.verification.reflection, isEmpty);
      expect(
        state.completedActivities.first.verificationMethod,
        'Short reflection',
      );
      expect(state.completedActivities.length, 2);
    },
  );

  test('recommendations vary tasks and positions without consecutive duplicate sets', () {
    final state = AppState(demoData: true, recommendationRandom: Random(42));
    addTearDown(state.dispose);
    final task = state.quest(4);
    state.start(task);
    state.confirmHonor(task, true);
    state.complete(task);
    final seen = <int>{};
    Set<int>? previous;
    for (var i = 0; i < 20; i++) {
      final choices = state.suggestedNextTasks(task);
      final ids = choices.map((q) => q.id).toSet();
      expect(ids.length, 3);
      expect(ids, isNot(contains(task.id)));
      expect(choices.every((q) => !q.isLocked), isTrue);
      if (previous != null) expect(ids.difference(previous), isNotEmpty);
      seen.addAll(ids);
      previous = ids;
    }
    expect(seen.length, greaterThan(6));
  });

  testWidgets(
    'XP counts up before suggestions appear and shows the actual repeat reward',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final task = state.quest(4);
      state.start(task);
      state.confirmHonor(task, true);
      state.complete(task);
      state.start(task);
      state.confirmHonor(task, true);
      final result = state.complete(task)!;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: QuestCompleteScreen(state: state, result: result),
        ),
      );
      expect(find.byType(QuestCard), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('xp-gain'))).data,
        '+0 XP',
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(QuestCard), findsNothing);
      final partial = tester
          .widget<Text>(find.byKey(const ValueKey('xp-gain')))
          .data!;
      expect(partial, isNot('+0 XP'));
      expect(partial, isNot('+37 XP'));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('xp-gain'))).data,
        '+37 XP',
      );
      expect(find.byType(QuestCard), findsNWidgets(3));
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .892,
      );
      expect(
        find.byWidgetPredicate((w) => w is QuestCard && w.quest.id == 4),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty log contains no artificial completed tasks', (
    tester,
  ) async {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogScreen(state: state, openQuest: (_) {}),
        ),
      ),
    );
    expect(find.text('Activity Log'), findsOneWidget);
    expect(
      find.text('Your first adventure starts with a choice.'),
      findsOneWidget,
    );
    expect(find.textContaining('Attempt 1'), findsNothing);
  });

  testWidgets(
    'choose, complete, repeat, continue another task, then return home and view log',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: MainScreen(state: state),
        ),
      );
      await tester.tap(find.text('Quests').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Learn Something New'));
      await tester.tap(find.text('Learn Something New'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('START SIDEQUEST'));
      await tester.tap(find.text('START SIDEQUEST'));
      await tester.pumpAndSettle();
      Future<void> finish() async {
        await tester.enterText(
          find.byType(TextField),
          'I learned something new on this particular attempt.',
        );
        await tester.pump();
        await tester.ensureVisible(find.text('COMPLETE SIDEQUEST'));
        await tester.tap(find.text('COMPLETE SIDEQUEST'));
        await tester.pumpAndSettle();
      }

      await finish();
      expect(find.text('What will you do next?'), findsOneWidget);
      expect(find.byType(QuestCard), findsNWidgets(3));
      expect(find.text('DO THIS TASK AGAIN'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is QuestCard && w.quest.id == 4),
        findsNothing,
      );
      await tester.ensureVisible(find.text('RETURN TO HOME'));
      await tester.tap(find.text('RETURN TO HOME'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity Log'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('DO THIS TASK AGAIN →'));
      await tester.tap(find.text('DO THIS TASK AGAIN →'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('DO SIDEQUEST AGAIN'));
      await tester.tap(find.text('DO SIDEQUEST AGAIN'));
      await tester.pumpAndSettle();
      expect(state.active!.id, 4);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await finish();
      final otherCard = find
          .byWidgetPredicate((w) => w is QuestCard && w.quest.id != 4)
          .first;
      final chosen = tester.widget<QuestCard>(otherCard).quest;
      await tester.ensureVisible(otherCard);
      await tester.tap(otherCard);
      await tester.pumpAndSettle();
      expect(state.active, same(chosen));
      expect(find.text('QUEST ACTIVE'), findsOneWidget);
      if (chosen.verification.method == VerificationMethod.location) {
        verifyGPS(state, chosen);
      } else {
        state.confirmHonor(chosen, true);
      }
      await tester.pump();
      await tester.ensureVisible(find.text('COMPLETE SIDEQUEST'));
      await tester.tap(find.text('COMPLETE SIDEQUEST'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('RETURN TO HOME'));
      await tester.tap(find.text('RETURN TO HOME'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(state.active, isNull);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity Log'));
      await tester.pumpAndSettle();
      expect(find.text('Learn Something New'), findsOneWidget);
      expect(find.text('Completed 2 times'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('activity-log-4')),
          matching: find.text('+112 XP'),
        ),
        findsOneWidget,
      );
      expect(find.text('Completed 1 time'), findsOneWidget);
      expect(state.completedActivities.length, 3);
      expect(find.text('DO THIS TASK AGAIN →'), findsNWidgets(2));
      expect(find.text('Activity Tree'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
