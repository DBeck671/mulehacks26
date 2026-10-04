import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/activity_store.dart';
import 'main.dart';
import 'models/quest.dart';

/// Presentation entry point. Never uses a Firebase account's storage key.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load(
    LocalActivityStore('showcase-demo-v1'),
    demoData: true,
    showcaseMode: true,
  );
  if (!state.hasProfile) state.setProfile('You', 'Prefer not to say');
  if (state.interests.isEmpty) {
    state.interests.addAll([Category.exploration, Category.creativity]);
  }
  state.setDemoBotsRunning(true);
  runApp(SideQuestApp(demoMode: true, initialState: state));
}
