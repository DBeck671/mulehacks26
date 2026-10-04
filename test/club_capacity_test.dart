import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/friend.dart';
import 'package:sidequest/screens/club_activity_screen.dart';
import 'package:sidequest/screens/friends_screen.dart';

void main() {
  test('hosts can choose and resize demo clubs above five without awarding personal XP', () {
    final state = AppState(demoData: true, showcaseMode: true);
    state.audio.enabled = false;
    addTearDown(state.dispose);
    final xp = state.totalXP;
    final club = state.createClub('Large crew', memberLimit: 12);
    expect(club.memberLimit, 12);
    expect(club.members.length, 12);
    expect(club.members.map((f) => f.id).toSet().length, 12);
    state.setClubMemberLimit(club.id, 20);
    expect(club.members.length, 20);
    state.setClubMemberLimit(club.id, 3);
    expect(club.members.length, 3);
    expect(club.members.any((f) => f.id == state.you.id), isTrue);
    expect(state.totalXP, xp);
    expect(state.completedActivities, isEmpty);
    expect(() => state.setClubMemberLimit(1, 10), throwsFormatException);
    expect(
      () => state.createClub('Bad slots', memberLimit: 1),
      throwsFormatException,
    );
    expect(() => state.setClubMemberLimit(club.id, 101), throwsFormatException);
  });

  test('full clubs reject joins without mutation; real members cannot be removed by shrinking', () {
    final state = AppState();
    addTearDown(state.dispose);
    final club = state.createClub('Limited crew', memberLimit: 2);
    club.members.add(
      Friend(
        id: 1,
        name: 'Alex',
        xp: 0,
        avatarInitial: 'A',
        questsCompleted: 0,
      ),
    );
    expect(() => state.setClubMemberLimit(club.id, 1), throwsFormatException);
    state.leaveGroup();
    club.members.add(
      Friend(id: 2, name: 'Sam', xp: 0, avatarInitial: 'S', questsCompleted: 0),
    );
    expect(state.joinGroup(club.inviteCode), JoinGroupResult.full);
    expect(state.hasGroup, isFalse);
    expect(club.members.length, 2);
    club.members.removeLast();
    expect(state.joinGroup(club.inviteCode), JoinGroupResult.joined);
    expect(club.members.length, 2);
    state.createClub('Other');
    expect(state.joinGroup(club.inviteCode), JoinGroupResult.joined);
    expect(club.members.length, 2);
  });

  testWidgets(
    'phone create form accepts custom slots and hosts can edit them in Members',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(demoData: true, showcaseMode: true);
      state.audio.enabled = false;
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FriendsScreen(state: state)),
        ),
      );
      await tester.tap(find.text('START A CLUB'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Club name'),
        'Big crew',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Member slots'),
        '10',
      );
      await tester.ensureVisible(find.text('CREATE CLUB'));
      await tester.tap(find.text('CREATE CLUB'));
      await tester.pumpAndSettle();
      expect(state.group.memberLimit, 10);
      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(home: ClubActivityScreen(state: state)),
      );
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MEMBER SLOTS · 10'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Member slots'),
        '12',
      );
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(state.group.memberLimit, 12);
      expect(state.group.members.length, 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
