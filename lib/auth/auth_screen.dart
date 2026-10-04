import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/common.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});
  final AuthService auth;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool create = false, hidden = true, busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !widget.auth.available || !form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (create) {
        await widget.auth.createAccount(email.text, password.text);
      } else {
        await widget.auth.signIn(email.text, password.text);
      }
      if (mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        password.clear();
        confirmation.clear();
      }
    } catch (error) {
      if (mounted) setState(() => message = authError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset() async {
    if (busy || !widget.auth.available) return;
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      setState(
        () => message = 'Enter your email above to reset your password.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.auth.resetPassword(address);
      if (mounted) {
        setState(
          () => message =
              'If an account matches this email, a reset link has been sent.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => message = authError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.route_rounded, color: green, size: 38),
                    const SizedBox(height: 24),
                    const Eyebrow('SIDEQUEST', color: green),
                    const SizedBox(height: 12),
                    Text(
                      create ? 'Your adventure\nstarts here.' : 'Welcome back.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      create
                          ? 'Create an account and take your first step.'
                          : 'Log in to find your next SideQuest.',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 30),
                    if (!widget.auth.available) ...[
                      const Panel(
                        child: Text(
                          'Account sign-in is awaiting the Firebase project connection.',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Enter a valid email address.',
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: hidden,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: [
                        create
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: create
                            ? 'Use 15–128 characters. Passphrases work well.'
                            : null,
                        suffixIcon: IconButton(
                          tooltip: hidden ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final length = (value ?? '').runes.length;
                        if (length == 0) return 'Enter your password.';
                        if (create && (length < 15 || length > 128)) {
                          return 'Use 15–128 characters.';
                        }
                        return null;
                      },
                      onFieldSubmitted: create ? null : (_) => submit(),
                    ),
                    if (create) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: confirmation,
                        enabled: !busy,
                        obscureText: hidden,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                        ),
                        validator: (value) => value == password.text
                            ? null
                            : 'Passwords do not match.',
                        onFieldSubmitted: (_) => submit(),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        message!,
                        semanticsLabel: message,
                        style: const TextStyle(color: green),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy || !widget.auth.available
                            ? null
                            : submit,
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(create ? 'CREATE ACCOUNT' : 'LOG IN'),
                      ),
                    ),
                    if (!create)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy || !widget.auth.available
                              ? null
                              : reset,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                create = !create;
                                message = null;
                                password.clear();
                                confirmation.clear();
                                form.currentState?.reset();
                              }),
                        child: Text(
                          create
                              ? 'Already have an account? Log in'
                              : 'New here? Create an account',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in securely with Firebase. Your Activity Log is saved for this account on this device.',
                      style: TextStyle(color: muted, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
