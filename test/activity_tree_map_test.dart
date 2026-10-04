import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/activity_tree_screen.dart';
import 'package:sidequest/screens/progress_screen.dart';

import 'gps_helpers.dart';

void main() {
  testWidgets(
    'Progress embeds the interactive tree below the level and removes duplicate rewards and achievements',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(body: ProgressScreen(state: state)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rewards & badges'), findsNothing);
      expect(find.text('ACHIEVEMENTS'), findsNothing);
      expect(find.text('Achievements'), findsNothing);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      final levelY = tester.getTopLeft(find.text('Level 1').first).dy;
      final treeY = tester.getTopLeft(find.byType(ActivityTreeScreen)).dy;
      expect(treeY, greaterThan(levelY));
      await tester.ensureVisible(find.byTooltip('Zoom in'));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: ActivityTreeScreen(state: state, questId: 3),
        ),
      );
      expect(find.byKey(const ValueKey('tree-task-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('tree-task-13')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      for (final quest in state.quests) {
        expect(find.byKey(ValueKey('tree-task-${quest.id}')), findsOneWidget);
      }
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      final combinedQuest = find.byKey(const ValueKey('tree-task-13'));
      expect(
        find.descendant(of: combinedQuest, matching: find.text('Nature')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: combinedQuest, matching: find.text('Creativity')),
        findsOneWidget,
      );
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
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final camera = viewer.transformationController!;
      final originalScale = camera.value.entry(0, 0);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(camera.value.entry(0, 0), greaterThan(originalScale));
      final beforeDrag = camera.value.getTranslation().clone();
      await tester.drag(
        find.byKey(const ValueKey('quest-tree-map')),
        const Offset(-100, -80),
      );
      await tester.pumpAndSettle();
      expect(camera.value.getTranslation(), isNot(beforeDrag));
      await tester.tap(find.byTooltip('Fit entire tree'));
      await tester.pump();
      expect(camera.value.entry(0, 0), lessThan(originalScale));
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tree-task-3')));
      await tester.pump();
      expect(find.text('YOUR SIDEQUEST'), findsNothing);
      await tester.tap(find.byTooltip('View quest'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR SIDEQUEST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
