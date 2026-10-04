import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/auth_gate.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_config.dart';

import 'app_state.dart';
import 'screens/onboarding.dart';
import 'screens/main_screen.dart';
import 'app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseAuthService auth;
  if (!FirebaseConfig.configured) {
    auth = FirebaseAuthService(
      null,
      setupError: 'Firebase configuration is missing.',
    );
  } else {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      auth = FirebaseAuthService(FirebaseAuth.instance);
    } catch (_) {
      auth = FirebaseAuthService(
        null,
        setupError: 'Firebase could not be initialized.',
      );
    }
  }
  runApp(SideQuestApp(auth: auth, persistHistory: true));
}

class SideQuestApp extends StatefulWidget {
  const SideQuestApp({
    super.key,
    this.auth,
    this.demoMode = false,
    this.initialState,
    this.persistHistory = false,
  });
  final AuthService? auth;
  final AppState? initialState;
  final bool persistHistory;
  // Explicit test harness only; production entry always uses AuthGate.
  final bool demoMode;
  @override
  State<SideQuestApp> createState() => _SideQuestAppState();
}

class _SideQuestAppState extends State<SideQuestApp> {
  late final state = widget.initialState ?? AppState(demoData: widget.demoMode);
  late final AuthService auth =
      widget.auth ??
      FirebaseAuthService(
        null,
        setupError: 'Firebase configuration is missing.',
      );
  @override
  void dispose() {
    state.dispose();
    if (widget.auth == null) auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => MaterialApp(
      title: 'SideQuest',
      debugShowCheckedModeBanner: false,
      theme: sideQuestTheme(state.lightTheme),
      home: widget.demoMode
          ? state.interests.isEmpty
                ? WelcomeScreen(state: state)
                : MainScreen(state: state)
          : AuthGate(auth: auth, persistHistory: widget.persistHistory),
    ),
  );
}
