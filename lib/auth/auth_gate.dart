import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/club_service.dart';
import '../data/activity_store.dart';
import '../screens/onboarding.dart';
import '../screens/main_screen.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, this.persistHistory = false});
  final AuthService auth;
  final bool persistHistory;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (_, _) => auth.account == null
        ? AuthScreen(auth: auth)
        : _AccountSession(
            key: ValueKey(auth.account!.uid),
            auth: auth,
            persistHistory: persistHistory,
          ),
  );
}

class _AccountSession extends StatefulWidget {
  const _AccountSession({
    super.key,
    required this.auth,
    required this.persistHistory,
  });
  final AuthService auth;
  final bool persistHistory;
  @override
  State<_AccountSession> createState() => _AccountSessionState();
}

class _AccountSessionState extends State<_AccountSession> {
  AppState? state;
  late Future<AppState> loaded = load();
  Future<AppState> load() async {
    final result = widget.persistHistory
        ? await AppState.load(LocalActivityStore(widget.auth.account!.uid))
        : AppState();
    if (!mounted) {
      result.dispose();
    } else {
      state = result;
      if (widget.auth is FirebaseAuthService &&
          (widget.auth as FirebaseAuthService).auth != null) {
        result.connectClubs(
          ClubService(FirebaseFirestore.instance, widget.auth.account!.uid),
        );
      }
    }
    return result;
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccountScope(
    auth: widget.auth,
    child: FutureBuilder<AppState>(
      future: loaded,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your saved activity log could not be loaded.'),
                  TextButton(
                    onPressed: () => setState(() => loaded = load()),
                    child: const Text('RETRY'),
                  ),
                  TextButton(
                    onPressed: widget.auth.signOut,
                    child: const Text('SIGN OUT'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ListenableBuilder(
          listenable: snapshot.data!,
          builder: (_, _) => Theme(
            data: sideQuestTheme(snapshot.data!.lightTheme),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) =>
                    (!snapshot.data!.hasProfile ||
                        snapshot.data!.interests.isEmpty)
                    ? WelcomeScreen(state: snapshot.data!)
                    : MainScreen(state: snapshot.data!),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class AccountScope extends InheritedWidget {
  const AccountScope({super.key, required this.auth, required super.child});
  final AuthService auth;
  static AuthService? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountScope>()?.auth;
  @override
  bool updateShouldNotify(AccountScope oldWidget) => true;
}

class AccountPanel extends StatefulWidget {
  const AccountPanel({super.key, required this.auth});
  final AuthService auth;
  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  bool busy = false;
  String? message;
  Future<void> run(Future<void> Function() action, String? success) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      if (mounted) setState(() => message = success);
    } catch (error) {
      if (mounted) setState(() => message = authError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.auth.account;
    if (account == null) return const SizedBox.shrink();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('ACCOUNT'),
          const SizedBox(height: 12),
          Text(account.email),
          const SizedBox(height: 8),
          Text(
            account.verified ? 'Email verified' : 'Email not verified',
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
          if (!account.verified)
            Wrap(
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(
                          widget.auth.sendVerification,
                          'Verification email sent. Check your inbox.',
                        ),
                  child: const Text('Send verification email'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(widget.auth.refreshAccount, null),
                  child: const Text('Check verification'),
                ),
              ],
            ),
          if (message != null)
            Text(message!, style: TextStyle(color: context.palette.green)),
          TextButton.icon(
            onPressed: busy ? null : () => run(widget.auth.signOut, null),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(busy ? 'PLEASE WAIT…' : 'SIGN OUT'),
          ),
        ],
      ),
    );
  }
}
