import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/settings_screen.dart';

import 'activity_persistence_test.dart' show MemoryStore, finish;

void main() {
  test('demo reset clears all gameplay and stays fresh after reload', () async {
    final store = MemoryStore();
    final state = await AppState.load(
      store,
      demoData: true,
      showcaseMode: true,
    );
    state.audio.enabled = false;
    state.setProfile('Demo player', 'Prefer not to say');
    for (var i = 0; i < 6; i++) {
      finish(state);
    }
    state.claimReward('coffee');
    final club = state.createClub('Test crew');
    state.sendClubMessage(club.id, 'Test pending reply');
    state.setDemoBotsRunning(true);
    final abandoned = state.quest(2);
    state.start(abandoned);
    await state.resetDemoAccount();
    expect(state.level, 1);
    expect(state.totalXP, 0);
    expect(state.earnedXP, 0);
    expect(state.completedCount, 0);
    expect(state.connectionCount, 0);
    expect(state.you.xp, 0);
    expect(state.you.questsCompleted, 0);
    expect(state.activeQuests, isEmpty);
    expect(state.completedActivities, isEmpty);
    expect(state.rewardClaims, isEmpty);
    expect(state.tokenBalance, 0);
    expect(state.equippedBadgeIds, isEmpty);
    expect(state.achievements.every((earned) => !earned), isTrue);
    expect(state.groups, isEmpty);
    expect(state.joinedGroups, isEmpty);
    expect(state.clubMessages(club.id), isEmpty);
    expect(state.demoBotsRunning, isFalse);
    expect(state.complete(abandoned), isNull);
    expect(state.quest(3).isLocked, isTrue);
    expect(state.quest(4).rewardXP, 75);
    state.dispose();
    final restored = await AppState.load(
      store,
      demoData: true,
      showcaseMode: true,
    );
    expect(restored.level, 1);
    expect(restored.hasSeededProgress, isFalse);
    expect(restored.completedCount, 0);
    expect(restored.groups, isEmpty);
    expect(restored.you.questsCompleted, 0);
    finish(restored);
    expect(restored.totalXP, 75);
    expect(restored.you.xp, 75);
    expect(restored.completedCount, 1);
    await restored.historySaved;
    restored.dispose();
    final again = await AppState.load(
      store,
      demoData: true,
      showcaseMode: true,
    );
    expect(again.totalXP, 75);
    expect(again.completedCount, 1);
    expect(again.you.questsCompleted, 1);
    again.dispose();
  });

  testWidgets('reset is demo-only and requires confirmation', (tester) async {
    final real = AppState();
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(state: real)));
    expect(find.text('RESET DEMO ACCOUNT'), findsNothing);
    await expectLater(real.resetDemoAccount(), throwsStateError);
    real.dispose();
    final demo = AppState(demoData: true);
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(state: demo)));
    await tester.tap(find.text('RESET DEMO ACCOUNT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(demo.totalXP, 3780);
    await tester.tap(find.text('RESET DEMO ACCOUNT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESET DEMO'));
    await tester.pumpAndSettle();
    expect(demo.level, 1);
    expect(
      find.text('Demo reset. Ready for your first quest.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    demo.dispose();
  });
}
