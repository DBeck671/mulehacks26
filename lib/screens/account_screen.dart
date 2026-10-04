import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../app_state.dart';
import '../auth/auth_service.dart';
import '../widgets/common.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.auth, required this.state});
  final AuthService? auth;
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account')),
    body: PageBody(
      children: [
        if (state.hasProfile) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.profileName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Gender: ${state.profileGender}',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                Text(
                  state.interests.map((c) => c.name).join(' · '),
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (auth?.account != null)
          AccountPanel(auth: auth!)
        else
          const Panel(
            child: Text(
              'You are exploring the local preview. Use the regular login app to create or manage your account.',
            ),
          ),
      ],
    ),
  );
}
