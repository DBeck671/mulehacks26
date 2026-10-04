import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/main.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';

void main() {
  testWidgets(
    'onboarding requires two interests and all four tabs preserve quest state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const SideQuestApp(demoMode: true));
      expect(find.byType(NavigationBar), findsNothing);
      await tester.ensureVisible(find.text('START EXPLORING'));
      await tester.tap(find.text('START EXPLORING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'BUILD MY PATH'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Taylor');
      await tester.pump();
      await tester.ensureVisible(find.text('Nature'));
      await tester.tap(find.text('Nature'));
      await tester.tap(find.text('Creativity'));
      await tester.pump();
      await tester.ensureVisible(find.text('BUILD MY PATH'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BUILD MY PATH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Nature Through a New Lens'), findsOneWidget);
      await tester.ensureVisible(find.text('START SIDEQUEST'));
      await tester.tap(find.text('START SIDEQUEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('START SIDEQUEST'));
      await tester.tap(find.text('START SIDEQUEST'));
      await tester.pump();
      expect(find.text('QUEST ACTIVE'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Use honor-based confirmation'));
      await tester.tap(find.text('Use honor-based confirmation'));
      await tester.pump();
      await tester.ensureVisible(find.text('COMPLETE SIDEQUEST'));
      await tester.tap(find.text('COMPLETE SIDEQUEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SIDEQUEST COMPLETE'), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 7000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.ensureVisible(find.text('RETURN TO HOME'));
      await tester.tap(find.text('RETURN TO HOME'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('1175 XP'), findsOneWidget);
      expect(find.text('FRIENDS THIS WEEK'), findsNothing);
      await tester.tap(find.text('Friends').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('1175 XP'), findsNothing);
      expect(find.text('8 / 10'), findsOneWidget);
      await tester.ensureVisible(find.text('Club Activity'));
      await tester.tap(find.text('Club Activity'));
      await tester.pumpAndSettle();
      expect(find.text('WEEKLY GROUP SIDEQUEST'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('880 / 1000 XP'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('880 / 1000 XP'), findsOneWidget);
      await tester.tap(find.text('Quests').last);
      await tester.pump();
      expect(find.text('Find your next SideQuest.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'locked details explain prerequisites and offer no start button',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: QuestDetailScreen(state: state, quest: state.quest(13)),
        ),
      );
      expect(find.text('Visit a Park'), findsOneWidget);
      expect(find.text('Take a Photograph'), findsOneWidget);
      expect(find.text('START SIDEQUEST'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
