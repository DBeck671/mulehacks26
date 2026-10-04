import 'package:flutter/material.dart';

import 'app_state.dart';
import 'main.dart';
import 'models/quest.dart';

/// Isolated presentation fixture. Does not read or write account/demo history.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(demoData: true, showcaseMode: true);
  state.setProfile('You', 'Prefer not to say');
  state.interests.addAll([Category.exploration, Category.creativity]);
  state.setDemoBotsRunning(true);
  runApp(SideQuestApp(demoMode: true, initialState: state));
}
