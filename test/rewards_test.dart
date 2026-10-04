import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/rewards_screen.dart';
import 'package:sidequest/screens/club_activity_screen.dart';

import 'activity_persistence_test.dart' show MemoryStore;

void finish(AppState state) {
  final q = state.quest(4);
  expect(state.start(q), isTrue);
  state.setReflection(
    q,
    'I learned something useful and can explain it clearly.',
  );
  expect(state.complete(q), isNotNull);
}

void main() {
  test('only successful personal completions earn tokens; repeats, claims and badges persist per account', () async {
    final store = MemoryStore();
    final state = await AppState.load(store);
    expect(state.tokenBalance, 0);
    expect(state.equippedBadgeId, isNull);
    expect(state.equipBadge('adventurer'), isFalse);
    expect(state.claimReward('coffee'), isNull);
    final q = state.quest(4);
    state.start(q);
    expect(state.complete(q), isNull);
    state.stop(q);
    expect(state.tokenBalance, 0);
    finish(state);
    expect(state.tokenBalance, 3);
    expect(state.hasBadge('first'), isTrue);
    expect(state.badgeFor(state.you)?.id, 'first');
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
    expect(restored.equippedBadgeId, 'first');
    expect(other.rewardClaims, isEmpty);
    expect(other.tokenBalance, 0);
    expect(other.equippedBadgeId, isNull);
  });

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
    finish(state);
    await tester.pumpWidget(
      MaterialApp(home: ClubActivityScreen(state: state)),
    );
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('First steps'), findsWidgets);
    expect(
      state.badgeFor(state.group.members.firstWhere((f) => f.id != 0)),
      isNotNull,
    );
    expect(state.badgeFor(state.you)?.id, 'first');
    expect(tester.takeException(), isNull);
  });
}
