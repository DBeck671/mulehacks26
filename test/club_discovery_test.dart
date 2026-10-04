import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/group.dart';
import 'package:sidequest/screens/friends_screen.dart';
import 'package:sidequest/main.dart';
import 'package:sidequest/models/quest.dart';
import 'package:sidequest/screens/settings_screen.dart';

import 'activity_persistence_test.dart' show MemoryStore;

void main() {
  test(
    'discovery bots vary capacity and public joins do not fill open slots',
    () async {
      final state = AppState(demoData: true, showcaseMode: true);
      addTearDown(state.dispose);
      state.audio.enabled = false;
      state.ensureDemoDiscovery();
      final clubs = state.discoverableClubs.where((c) => c.id >= 100).toList();
      expect(clubs.length, 6);
      expect(clubs.map((c) => c.memberLimit).toSet().length, 6);
      expect(
        clubs.map((c) => c.visibility).toSet(),
        ClubVisibility.values.toSet(),
      );
      expect(clubs.every((c) => !c.isFull), isTrue);
      final public = clubs.firstWhere(
        (c) => c.visibility == ClubVisibility.public,
      );
      final before = public.memberCount;
      expect(await state.joinClub(public), JoinGroupResult.joined);
      expect(public.memberCount, before + 1);
      state.setDemoBotsRunning(true);
      expect(public.memberCount, before + 1);
      state.audio.enabled = false;
      state.ensureDemoDiscovery();
      expect(state.groups.where((c) => c.id >= 100).length, 6);
    },
  );
  testWidgets('private demo requests wait for bot host approval', (
    tester,
  ) async {
    final state = AppState(demoData: true, showcaseMode: true);
    addTearDown(state.dispose);
    state.audio.enabled = false;
    state.ensureDemoDiscovery();
    final private = state.discoverableClubs.firstWhere(
      (c) => c.id >= 100 && c.visibility == ClubVisibility.private,
    );
    expect(await state.joinClub(private), JoinGroupResult.requested);
    expect(state.joinedGroupIds.contains(private.id), isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(state.joinedGroupIds.contains(private.id), isTrue);
    expect(private.joinRequests.single.status, 'approved');
  });
  testWidgets('Discover shows public join and private approval actions', (
    tester,
  ) async {
    final state = AppState(demoData: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FriendsScreen(state: state)),
      ),
    );
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Find a club'), findsOneWidget);
    expect(find.text('JOIN CLUB'), findsWidgets);
    expect(find.text('REQUEST TO JOIN'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  test('theme preference persists independently per account without changing progress', () async {
    final store = MemoryStore();
    final first = await AppState.load(store);
    first.setLightTheme(true);
    await first.historySaved;
    first.dispose();
    final restored = await AppState.load(store);
    final other = await AppState.load(MemoryStore());
    addTearDown(restored.dispose);
    addTearDown(other.dispose);
    expect(restored.lightTheme, isTrue);
    expect(other.lightTheme, isFalse);
    expect(restored.totalXP, 0);
    expect(restored.completedActivities, isEmpty);
  });
  testWidgets('light theme updates settings and keeps navigation intact', (
    tester,
  ) async {
    final state = AppState(demoData: true);
    state.interests.add(Category.nature);
    await tester.pumpWidget(SideQuestApp(demoMode: true, initialState: state));
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.light,
    );
    expect(find.text('Sound effects'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('SideQuest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
