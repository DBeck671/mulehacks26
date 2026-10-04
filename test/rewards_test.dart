import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/rewards_screen.dart';
import 'package:sidequest/screens/club_activity_screen.dart';

import 'activity_persistence_test.dart' show MemoryStore;
import 'gps_helpers.dart';
import 'evidence_helpers.dart';

void finish(AppState state) {
  final q = state.quest(4);
  expect(state.start(q), isTrue);
  state.setReflection(
    q,
    'I learned something useful and can explain it clearly.',
  );
  expect(state.complete(q), isNotNull);
}

void earnFourBadges(AppState state) {
  for (final id in [1, 2, 3]) {
    final quest = state.quest(id);
    expect(state.start(quest), isTrue);
    if (id == 2) {
      verifyNonLocation(state, quest);
    } else {
      verifyGPS(state, quest);
    }
    expect(state.complete(quest), isNotNull);
  }
}

void main() {
  test('only successful personal completions earn tokens; repeats, claims and badges persist per account', () async {
    final store = MemoryStore();
    final state = await AppState.load(store);
    expect(state.tokenBalance, 0);
    expect(state.equippedBadgeIds, isEmpty);
    expect(state.toggleBadge('adventurer'), isFalse);
    expect(state.claimReward('coffee'), isNull);
    final q = state.quest(4);
    state.start(q);
    expect(state.complete(q), isNull);
    state.stop(q);
    expect(state.tokenBalance, 0);
    finish(state);
    expect(state.tokenBalance, 3);
    expect(state.hasBadge('first'), isTrue);
    expect(state.badgesFor(state.you).single.id, 'first');
    expect(state.complete(q), isNull);
    expect(state.tokenBalance, 3);
    for (var i = 0; i < 5; i++) {
      finish(state);
    }
    expect(state.tokenBalance, 8);
    expect(state.claimReward('unknown'), isNull);
    final claim = state.claimReward('coffee');
    expect(claim?.code, startsWith('SQ-DEMO-'));
    expect(state.tokenBalance, 0);
    expect(state.claimReward('coffee'), isNull);
    expect(state.rewardClaims.length, 1);
    await state.historySaved;
    state.dispose();
    final restored = await AppState.load(store);
    final other = await AppState.load(MemoryStore());
    addTearDown(restored.dispose);
    addTearDown(other.dispose);
    expect(restored.tokenBalance, 0);
    expect(restored.rewardClaims.single.code, claim!.code);
    expect(restored.equippedBadgeIds, ['first']);
    expect(other.rewardClaims, isEmpty);
    expect(other.tokenBalance, 0);
    expect(other.equippedBadgeIds, isEmpty);
  });

  test('badge display is capped at three, removable, and persists including empty selections', () async {
    final store = MemoryStore();
    final state = await AppState.load(store, demoData: true);
    addTearDown(state.dispose);
    earnFourBadges(state);
    for (final id in ['first', 'connected', 'adventurer', 'leader']) {
      expect(state.hasBadge(id), isTrue);
    }
    expect(state.toggleBadge('connected'), isTrue);
    expect(state.toggleBadge('adventurer'), isTrue);
    expect(state.toggleBadge('leader'), isFalse);
    expect(state.toggleBadge('creative'), isFalse);
    expect(state.equippedBadgeIds, ['first', 'connected', 'adventurer']);
    expect(state.toggleBadge('first'), isTrue);
    expect(state.toggleBadge('leader'), isTrue);
    await state.historySaved;
    final restored = await AppState.load(store, demoData: true);
    addTearDown(restored.dispose);
    expect(restored.equippedBadgeIds, ['connected', 'adventurer', 'leader']);
    for (final id in restored.equippedBadgeIds) {
      restored.toggleBadge(id);
    }
    await restored.historySaved;
    final empty = await AppState.load(store, demoData: true);
    addTearDown(empty.dispose);
    finish(empty);
    expect(empty.equippedBadgeIds, isEmpty);
  });

  test(
    'legacy single badge selection migrates without losing history',
    () async {
      final store = MemoryStore();
      final state = await AppState.load(store, demoData: true);
      earnFourBadges(state);
      await state.historySaved;
      state.dispose();
      final data = jsonDecode(store.value!) as Map<String, dynamic>;
      data.remove('equippedBadges');
      data['equippedBadge'] = 'connected';
      store.value = jsonEncode(data);
      final restored = await AppState.load(store, demoData: true);
      addTearDown(restored.dispose);
      expect(restored.equippedBadgeIds, ['connected']);
      expect(restored.completedActivities.length, 3);
    },
  );

  testWidgets(
    'badge picker toggles selections and explains the three badge limit',
    (tester) async {
      final state = AppState(demoData: true);
      addTearDown(state.dispose);
      earnFourBadges(state);
      await tester.pumpWidget(MaterialApp(home: RewardsScreen(state: state)));
      Future<void> choose(String id) async {
        final choice = find.byKey(ValueKey('badge-choice-$id'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }

      await choose('connected');
      await choose('adventurer');
      await choose('leader');
      expect(state.equippedBadgeIds.length, 3);
      expect(
        find.text('Choose up to three badges. Remove one to add another.'),
        findsOneWidget,
      );
      await choose('adventurer');
      await choose('leader');
      expect(state.equippedBadgeIds, ['first', 'connected', 'leader']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'reward claims require confirmation, spend once and clearly label sample coupons',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState();
      addTearDown(state.dispose);
      for (var i = 0; i < 6; i++) {
        finish(state);
      }
      await tester.pumpWidget(MaterialApp(home: RewardsScreen(state: state)));
      await tester.ensureVisible(find.text('8 TOKENS'));
      await tester.tap(find.text('8 TOKENS'));
      await tester.pumpAndSettle();
      expect(state.tokenBalance, 8);
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(state.rewardClaims, isEmpty);
      await tester.tap(find.text('8 TOKENS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USE 8 TOKENS'));
      await tester.pumpAndSettle();
      expect(state.tokenBalance, 0);
      expect(find.text('SQ-DEMO-COFFEE'), findsOneWidget);
      expect(find.textContaining('Not redeemable at a store'), findsOneWidget);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('VIEW SAMPLE CODE'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('earned badges appear with your name in club members', (
    tester,
  ) async {
    final state = AppState(demoData: true, showcaseMode: true);
    addTearDown(state.dispose);
    earnFourBadges(state);
    state.toggleBadge('connected');
    state.toggleBadge('adventurer');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: ClubActivityScreen(state: state)),
    );
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('First steps'), findsWidgets);
    expect(
      state.badgesFor(state.group.members.firstWhere((f) => f.id != 0)),
      isNotEmpty,
    );
    expect(state.badgesFor(state.you).map((b) => b.id), [
      'first',
      'connected',
      'adventurer',
    ]);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Adventurer'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
