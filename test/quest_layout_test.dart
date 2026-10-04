import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/main_screen.dart';
import 'package:sidequest/widgets/quest_row_card.dart';

void main() {
  testWidgets(
    'navigation places Progress third; quests use stacked horizontal cards',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(home: MainScreen(state: state)));
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label),
        ['Home', 'Quests', 'Progress', 'Friends'],
      );
      await tester.tap(find.text('Progress').last);
      await tester.pump();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(find.text('Your Journey'), findsOneWidget);
      await tester.tap(find.text('Quests').last);
      await tester.pump();
      final cards = find.byType(QuestRowCard);
      expect(cards, findsNWidgets(state.quests.length));
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(first.width, greaterThan(300));
      expect(first.left, second.left);
      expect(second.top, greaterThan(first.bottom));
      expect(find.byTooltip('Next tasks'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
