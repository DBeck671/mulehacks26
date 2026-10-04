import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/friends_screen.dart';
import 'package:sidequest/widgets/club_invite_sheet.dart';

void main() {
  test('new clubs have unique codes, a host, independent boards and support rejoining', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    expect(() => state.createClub(' '), throwsFormatException);
    expect(() => state.createClub('x' * 41), throwsFormatException);
    expect(state.groups.length, 2);
    final club = state.createClub('  Weekend   explorers ');
    expect(club.name, 'Weekend explorers');
    expect(club.hostId, state.you.id);
    expect(club.members, [state.you]);
    expect(state.group, same(club));
    expect(club.partyTasks.length, 3);
    expect(club.weeklyChallengeProgress, 0);
    expect(state.totalXP, 3780);
    final code = club.inviteCode;
    final board = club.partyTasks.map((t) => t.questId).toList();
    state.leaveGroup();
    expect(state.joinGroup(code.toLowerCase()), JoinGroupResult.joined);
    expect(state.group, same(club));
    expect(club.members.length, 1);
    expect(club.partyTasks.map((t) => t.questId), board);
    for (var i = 0; i < 20; i++) {
      state.createClub('Club $i');
    }
    expect(state.groups.map((g) => g.id).toSet().length, state.groups.length);
    expect(
      state.groups.map((g) => g.inviteCode).toSet().length,
      state.groups.length,
    );
  });

  testWidgets(
    'create club validates name, opens invite sheet, and shows host and party tasks',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      state.leaveGroup();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (_, _) => FriendsScreen(state: state),
            ),
          ),
        ),
      );
      await tester.tap(find.text('START A CLUB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CREATE CLUB'));
      await tester.pump();
      expect(
        find.text('Choose a club name with 2–40 characters.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Club name'),
        'Trail crew',
      );
      await tester.tap(find.text('CREATE CLUB'));
      await tester.pumpAndSettle();
      expect(state.group.name, 'Trail crew');
      expect(find.text(state.group.inviteCode), findsOneWidget);
      expect(find.text('SHARE INVITE'), findsOneWidget);
      expect(find.byTooltip('Copy invite code'), findsOneWidget);
      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR CLUB · HOST'), findsOneWidget);
      expect(find.text('0 / 3 party tasks completed'), findsNothing);
      await tester.ensureVisible(find.text('Club Activity'));
      await tester.tap(find.text('Club Activity'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 3 party tasks completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invite sharing uses the correct club code and copy remains available',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      final club = state.createClub('Photo crew');
      ShareParams? shared;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClubInviteSheet(
              club: club,
              shareInvite: (params) async {
                shared = params;
                return ShareResult.unavailable;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('SHARE INVITE'));
      await tester.pumpAndSettle();
      expect(shared!.text, contains(club.name));
      expect(shared!.text, contains(club.inviteCode));
      expect(shared!.text, contains('online joining is not connected yet'));
      expect(
        find.text('Sharing unavailable here. Copy the invite code instead.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Copy invite code'));
      await tester.pump();
      expect(copied, club.inviteCode);
      expect(tester.takeException(), isNull);
    },
  );
}
