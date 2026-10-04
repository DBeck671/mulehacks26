import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Account {
  const Account(this.uid, this.email, this.verified);
  final String uid, email;
  final bool verified;
}

abstract class AuthService extends ChangeNotifier {
  Account? get account;
  bool get available;
  String? get setupError;
  Future<void> signIn(String email, String password);
  Future<void> createAccount(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> sendVerification();
  Future<void> refreshAccount();
  Future<void> signOut();
}

class FirebaseAuthService extends AuthService {
  FirebaseAuthService(this.auth, {this.setupError}) {
    subscription = auth?.userChanges().listen((_) => notifyListeners());
  }
  final FirebaseAuth? auth;
  StreamSubscription<User?>? subscription;
  @override
  final String? setupError;
  @override
  bool get available => auth != null;
  @override
  Account? get account {
    final user = auth?.currentUser;
    return user == null
        ? null
        : Account(user.uid, user.email ?? '', user.emailVerified);
  }

  @override
  Future<void> signIn(String email, String password) async {
    await auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> createAccount(String email, String password) async {
    await auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await auth!.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> sendVerification() => auth!.currentUser!.sendEmailVerification();
  @override
  Future<void> refreshAccount() async {
    await auth!.currentUser?.reload();
    notifyListeners();
  }

  @override
  Future<void> signOut() => auth!.signOut();
  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}

String authError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'Use a stronger password that meets the account requirements.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Check your connection and try again.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled yet. Please contact the app owner.',
      'email-already-in-use' => 'Unable to create this account. Try logging in or resetting your password.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'user-disabled' => 'Unable to sign in. Check your email and password.',
      _ => 'Unable to complete this request. Please try again.',
    };
  }
  return 'Unable to complete this request. Please try again.';
}
