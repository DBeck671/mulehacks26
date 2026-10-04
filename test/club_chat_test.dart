import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/club_activity_screen.dart';
import 'package:sidequest/screens/main_screen.dart';

void main() {
  testWidgets('club chat sends scoped messages and labels demo bot replies', (
    tester,
  ) async {
    final state = AppState(demoData: true, showcaseMode: true);
    addTearDown(state.dispose);
    final club = state.createClub('Test club');
    await tester.pumpWidget(
      MaterialApp(home: ClubActivityScreen(state: state)),
    );
    await tester.tap(find.byTooltip('Group chat'));
    await tester.pumpAndSettle();
    expect(find.text('Demo chat · bot replies'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Send message',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'Let’s do these quests!');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(find.text('Let’s do these quests!'), findsOneWidget);
    expect(state.clubMessages(club.id).length, 1);
    expect(state.clubMessages(1), isEmpty);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Alex · bot'), findsOneWidget);
    expect(state.clubMessages(club.id).length, 2);
    state.leaveGroup(groupId: club.id);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(state.sendClubMessage(club.id, 'No longer a member'), isFalse);
    expect(state.sendClubMessage(1, '   '), isFalse);
    expect(state.sendClubMessage(1, 'a' * 501), isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Activity Log is a bottom tab; account settings remain available without a drawer',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      await tester.pumpWidget(MaterialApp(home: MainScreen(state: state)));
      expect(find.byType(Drawer), findsNothing);
      await tester.tap(find.text('Activity Log').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      await tester.tap(find.byTooltip('Account menu'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
