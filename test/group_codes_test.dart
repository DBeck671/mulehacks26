import 'evidence_helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';

import 'gps_helpers.dart';

import 'package:sidequest/screens/friends_screen.dart';

void main() {
  test('invite and group codes normalize, reject unknown codes, and preserve player XP', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    expect(state.joinGroup(''), JoinGroupResult.invalidCode);
    expect(state.joinGroup('SQ-9999'), JoinGroupResult.unknownCode);
    expect(state.joinGroup('SQ-4821'), JoinGroupResult.alreadyActive);
    state.start(state.quest(1));
    verifyGPS(state, state.quest(1));
    state.complete(state.quest(1));
    final user = state.you;
    expect(state.joinGroup('  inv 7319  '), JoinGroupResult.joined);
    expect(state.group.name, 'Curiosity Club');
    expect(state.you, same(user));
    expect(state.you.xp, 1150);
    expect(state.joinedGroups.length, 2);
    expect(state.challengeContributions, isEmpty);
    expect(state.group.weeklyChallengeProgress, 7);
    state.start(state.quest(2));
    verifyNonLocation(state, state.quest(2));
    state.complete(state.quest(2));
    expect(state.group.weeklyChallengeProgress, 8);
    expect(state.challengeContributions, [2]);
    state.selectGroup(1);
    expect(state.group.weeklyChallengeProgress, 8);
    expect(state.challengeContributions, [1]);
    expect(state.you.xp, 1200);
    expect(state.joinGroup('sq-7319'), JoinGroupResult.joined);
    expect(state.joinGroup('INV-7319'), JoinGroupResult.alreadyActive);
    expect(state.joinedGroups.length, 2);
  });
  test('leaving and rejoining preserves player and independent membership', () {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    state.joinGroup('INV-7319');
    state.leaveGroup();
    expect(state.activeGroupId, 1);
    expect(state.group.members.any((f) => f.id == 0), isTrue);
    expect(state.groups[1].members.any((f) => f.id == 0), isFalse);
    state.leaveGroup();
    expect(state.hasGroup, isFalse);
    expect(state.leaderboard, isEmpty);
    expect(state.rank, 0);
    state.start(state.quest(2));
    verifyNonLocation(state, state.quest(2));
    state.complete(state.quest(2));
    expect(state.you.xp, 1125);
    expect(state.leaveGroup(), isFalse);
    state.joinGroup('INV-7319');
    expect(state.group.members.where((f) => f.id == 0).length, 1);
    expect(state.you.xp, 1125);
  });
  testWidgets(
    'code section joins a group, shows errors, and displays invite code and supports leaving',
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
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (_, _) => FriendsScreen(state: state),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('JOIN A GROUP'));
      await tester.tap(find.text('JOIN A GROUP'));
      await tester.pumpAndSettle();
      expect(find.text('Invite code or group code'), findsOneWidget);
      await tester.tap(find.text('JOIN GROUP'));
      await tester.pump();
      expect(
        find.text('Enter a code like SQ-7319 or INV-7319.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'SQ-9999');
      await tester.tap(find.text('JOIN GROUP'));
      await tester.pump();
      expect(
        find.text('Code not found. Check it and try again.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'INV-7319');
      await tester.tap(find.text('JOIN GROUP'));
      await tester.pumpAndSettle();
      expect(find.text("You're in!"), findsOneWidget);
      expect(find.byKey(const ValueKey('club-card-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('club-card-2')), findsOneWidget);
      expect(find.text('JOIN GROUP'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text("You're in!"), findsNothing);
      final invite = find.descendant(
        of: find.byKey(const ValueKey('club-card-2')),
        matching: find.text('INVITE FRIEND'),
      );
      await tester.ensureVisible(invite);
      await tester.tap(invite);
      await tester.pumpAndSettle();
      expect(find.text('SQ-7319'), findsNothing);
      expect(find.text('GROUP CODE'), findsNothing);
      expect(find.text('INV-7319'), findsOneWidget);
      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();
      final leaveSecond = find.descendant(
        of: find.byKey(const ValueKey('club-card-2')),
        matching: find.text('LEAVE GROUP'),
      );
      await tester.ensureVisible(leaveSecond);
      await tester.tap(leaveSecond);
      await tester.pumpAndSettle();
      expect(state.activeGroupId, 1);
      await tester.ensureVisible(find.text('LEAVE GROUP'));
      await tester.tap(find.text('LEAVE GROUP'));
      await tester.pumpAndSettle();
      expect(state.hasGroup, isFalse);
      expect(find.textContaining('You are not in a group.'), findsOneWidget);
      expect(find.text('JOIN A GROUP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
