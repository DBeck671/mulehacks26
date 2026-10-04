import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/activity_tree_screen.dart';
import 'package:sidequest/screens/progress_screen.dart';

import 'gps_helpers.dart';

Widget app(Widget child) => MaterialApp(
  builder: (_, child) => MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: child!,
  ),
  home: child,
);

void main() {
  testWidgets(
    'tree owns wheel, trackpad and touch movement; outside still scrolls page',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        app(Scaffold(body: ProgressScreen(state: state))),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final camera = viewer.transformationController!;
      final position = tester.getCenter(find.byType(InteractiveViewer));
      for (final kind in [
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      ]) {
        final before = camera.value.getTranslation().clone();
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: position,
            scrollDelta: const Offset(30, 80),
            kind: kind,
          ),
        );
        await tester.pumpAndSettle();
        expect(camera.value.getTranslation(), isNot(before));
        expect(scroll.position.pixels, 0);
      }
      final before = camera.value.getTranslation().clone();
      final touch = await tester.startGesture(position);
      await tester.pump();
      await touch.moveBy(const Offset(0, -120));
      await tester.pump();
      await touch.up();
      await tester.pumpAndSettle();
      expect(camera.value.getTranslation(), isNot(before));
      expect(scroll.position.pixels, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: position);
      await tester.pump();
      await mouse.moveTo(const Offset(10, 100));
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(100, 100),
          scrollDelta: Offset(0, 120),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Progress shows read-only tree below level without duplicate rewards or achievements',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        app(Scaffold(body: ProgressScreen(state: state))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rewards & badges'), findsNothing);
      expect(find.text('ACHIEVEMENTS'), findsNothing);
      expect(find.text('Achievements'), findsNothing);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(ActivityTreeScreen)).dy,
        greaterThan(tester.getTopLeft(find.text('Level 1').first).dy),
      );
      expect(find.text('No active quests'), findsOneWidget);
      expect(find.byTooltip('Zoom in'), findsNothing);
      expect(find.byTooltip('View quest'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'all quests stay visible to the map; dragging pans without selecting or opening tasks',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(app(ActivityTreeScreen(state: state)));
      await tester.pumpAndSettle();
      for (final quest in state.quests) {
        expect(find.byKey(ValueKey('tree-task-${quest.id}')), findsOneWidget);
      }
      expect(find.byType(InkWell), findsNothing);
      expect(find.byTooltip('Fit entire tree'), findsNothing);
      expect(find.byTooltip('Reset view'), findsNothing);
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.scaleEnabled, isFalse);
      expect(viewer.panEnabled, isTrue);
      final camera = viewer.transformationController!;
      final scale = camera.value.entry(0, 0);
      final before = camera.value.getTranslation().clone();
      await tester.drag(
        find.byKey(const ValueKey('quest-tree-map')),
        const Offset(-100, -80),
      );
      await tester.pumpAndSettle();
      expect(camera.value.getTranslation(), isNot(before));
      expect(camera.value.entry(0, 0), scale);
      expect(state.activeQuests, isEmpty);
      expect(find.text('YOUR SIDEQUEST'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'both active tasks have summaries and halos; stopping and completing clear them',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      state.start(state.quest(1));
      state.start(state.quest(4));
      await tester.pumpWidget(app(ActivityTreeScreen(state: state)));
      await tester.pumpAndSettle();
      for (final id in [1, 4]) {
        expect(find.byKey(ValueKey('active-tree-pulse-$id')), findsOneWidget);
        final summary = find.byKey(ValueKey('active-tree-summary-$id'));
        expect(summary, findsOneWidget);
        expect(
          find.descendant(
            of: summary,
            matching: find.text(state.quest(id).description),
          ),
          findsOneWidget,
        );
      }
      state.pauseTask(state.quest(4));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      state.stop(state.quest(4));
      verifyGPS(state, state.quest(1));
      expect(state.complete(state.quest(1)), isNotNull);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('active-tree-pulse-1')), findsNothing);
      expect(find.byKey(const ValueKey('active-tree-pulse-4')), findsNothing);
      expect(find.text('No active quests'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tree-task-3')),
          matching: find.text('Available'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
