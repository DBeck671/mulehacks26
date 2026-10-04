import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/activity_tree_screen.dart';

import 'gps_helpers.dart';

void main() {
  testWidgets(
    'unlock map shows all parents, updates after completion and opens task details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(home: ActivityTreeScreen(state: state)),
      );
      expect(find.byKey(const ValueKey('tree-task-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-13')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsNothing);
      for (final quest in state.quests) {
        expect(find.byKey(ValueKey('tree-task-${quest.id}')), findsOneWidget);
      }
      expect(find.text('Highlight a quest'), findsOneWidget);
      expect(find.text('All sidequests'), findsOneWidget);
      final q = state.quest(1);
      state.start(q);
      verifyGPS(state, q);
      state.complete(q);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tree-task-1')),
          matching: find.text('Completed'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tree-task-3')),
          matching: find.text('Available'),
        ),
        findsOneWidget,
      );
      expect(state.quest(13).isLocked, isTrue);
      await tester.ensureVisible(find.byKey(const ValueKey('tree-task-3')));
      await tester.tap(find.byKey(const ValueKey('tree-task-3')));
      await tester.pumpAndSettle();
      expect(find.text('YOUR SIDEQUEST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
