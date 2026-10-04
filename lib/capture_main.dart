import 'package:flutter/material.dart';

import 'app_state.dart';
import 'main.dart';
import 'models/quest.dart';
import 'app_theme.dart';
import 'screens/onboarding.dart';

/// Isolated presentation fixture. Does not read or write account/demo history.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(demoData: true, showcaseMode: true);
  final screen = Uri.base.queryParameters['screen'];
  if (screen == 'welcome') {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: sideQuestTheme(false),
        home: WelcomeScreen(state: state),
      ),
    );
    return;
  }
  state.setProfile('You', 'Prefer not to say');
  state.interests.addAll([Category.exploration, Category.creativity]);
  state.setDemoBotsRunning(true);
  runApp(SideQuestApp(demoMode: true, initialState: state));
}
