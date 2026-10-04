import 'package:flutter/material.dart';

import 'main.dart';
import 'app_state.dart';
import 'data/activity_store.dart';

// Local design preview only. The normal main.dart entry requires Firebase login.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load(LocalActivityStore('local-preview'));
  runApp(SideQuestApp(demoMode: true, initialState: state));
}
