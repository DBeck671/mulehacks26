import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        children: [
          Panel(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show completed quests'),
              subtitle: const Text('Keep repeatable tasks visible in Explore.'),
              value: state.showCompletedQuests,
              onChanged: state.setShowCompletedQuests,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Activity history is saved on this device for your account. Signing out keeps your saved log. Device storage is separate from other devices.',
            style: TextStyle(color: muted, height: 1.6),
          ),
        ],
      ),
    ),
  );
}
