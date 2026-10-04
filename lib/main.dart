import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/auth_gate.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_config.dart';

import 'app_state.dart';
import 'screens/onboarding.dart';
import 'screens/main_screen.dart';
import 'widgets/common.dart';

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
  Widget build(BuildContext context) => MaterialApp(
    title: 'SideQuest',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: green,
        onPrimary: background,
        surface: surface,
        onSurface: Color(0xFFF3F5F0),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.3,
          height: 1.12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: .2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: const Color(0xFFF3F5F0),
          side: const BorderSide(color: raised),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: raised),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: raised),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: green.withValues(alpha: .12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 10,
            color: s.contains(WidgetState.selected) ? green : muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: raised),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: widget.demoMode
        ? state.interests.isEmpty
              ? WelcomeScreen(state: state)
              : MainScreen(state: state)
        : AuthGate(auth: auth, persistHistory: widget.persistHistory),
  );
}
