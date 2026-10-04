import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/auth/auth_service.dart';
import 'package:sidequest/auth/auth_screen.dart';
import 'package:sidequest/auth/auth_gate.dart';
import 'package:sidequest/main.dart';

class FakeAuth extends AuthService {
  Account? current;
  int creates = 0, logins = 0, resets = 0;
  Object? failure;
  @override
  Account? get account => current;
  @override
  bool get available => true;
  @override
  String? get setupError => null;
  @override
  Future<void> createAccount(String email, String password) async {
    creates++;
    if (failure != null) throw failure!;
    current = Account('user-a', email.trim(), false);
    notifyListeners();
  }

  @override
  Future<void> signIn(String email, String password) async {
    logins++;
    if (failure != null) throw failure!;
    current = Account('user-a', email.trim(), true);
    notifyListeners();
  }

  @override
  Future<void> resetPassword(String email) async {
    resets++;
  }

  @override
  Future<void> sendVerification() async {}
  @override
  Future<void> refreshAccount() async {}
  @override
  Future<void> signOut() async {
    current = null;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'unconfigured app requires authentication and disables requests',
    (tester) async {
      await tester.pumpWidget(const SideQuestApp());
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('START EXPLORING'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'LOG IN'))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'signup validates passphrase and confirmation before making a request',
    (tester) async {
      final auth = FakeAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));
      await tester.tap(find.text('New here? Create an account'));
      await tester.pump();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'different');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();
      expect(auth.creates, 0);
      expect(find.text('Use 15–128 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.enterText(fields.at(1), 'A long sample passphrase');
      await tester.enterText(fields.at(2), 'A long sample passphrase');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();
      expect(auth.creates, 1);
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'reset gives generic feedback and sign-in failures keep gate closed',
    (tester) async {
      final auth = FakeAuth()
        ..failure = FirebaseAuthException(code: 'invalid-credential');
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp(home: AuthGate(auth: auth)));
      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'incorrect password',
      );
      await tester.tap(find.text('LOG IN'));
      await tester.pump();
      expect(
        find.text('Unable to sign in. Check your email and password.'),
        findsOneWidget,
      );
      expect(find.text('START EXPLORING'), findsNothing);
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(auth.resets, 1);
      expect(
        find.text(
          'If an account matches this email, a reset link has been sent.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'sign-out removes protected routes, next sign-in starts a fresh session',
    (tester) async {
      final auth = FakeAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(SideQuestApp(auth: auth));
      await auth.signIn('user@example.com', 'not saved by application');
      await tester.pump();
      await tester.pump();
      await tester.ensureVisible(find.text('START EXPLORING'));
      await tester.tap(find.text('START EXPLORING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('BUILD MY PATH'), findsOneWidget);
      await auth.signOut();
      await tester.pump();
      expect(find.text('BUILD MY PATH'), findsNothing);
      expect(find.text('Welcome back.'), findsOneWidget);
      await auth.signIn('user@example.com', 'not saved by application');
      await tester.pump();
      await tester.pump();
      expect(find.text('START EXPLORING'), findsOneWidget);
      expect(find.text('BUILD MY PATH'), findsNothing);
    },
  );
}
