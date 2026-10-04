import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  Future<void> resetDemo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset demo account?'),
        content: const Text(
          'Start at Level 1 with no XP, activity, active tasks, rewards, badges or clubs. This clears only this demo account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('RESET DEMO'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await state.resetDemoAccount();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.historySaveFailed
              ? 'Reset in memory. Saving failed; retry before refreshing.'
              : 'Demo reset. Ready for your first quest.',
        ),
        action: state.historySaveFailed
            ? SnackBarAction(label: 'RETRY', onPressed: state.retryHistorySave)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        children: [
          Panel(
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                activeTrackColor: context.palette.green,
                contentPadding: EdgeInsets.zero,
                title: const Text('Light theme'),
                subtitle: const Text('Calm blues and white surfaces'),
                value: state.lightTheme,
                onChanged: state.setLightTheme,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                activeTrackColor: context.palette.green,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show completed quests'),
                subtitle: const Text(
                  'Keep repeatable tasks visible in Explore.',
                ),
                value: state.showCompletedQuests,
                onChanged: state.setShowCompletedQuests,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                activeTrackColor: context.palette.green,
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound effects'),
                value: state.audio.enabled,
                onChanged: state.setSoundEnabled,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (state.demoData) ...[
            OutlinedButton.icon(
              onPressed: () => resetDemo(context),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('RESET DEMO ACCOUNT'),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Activity history is saved on this device for your account. Signing out keeps your saved log. Device storage is separate from other devices.',
            style: TextStyle(color: context.palette.muted, height: 1.6),
          ),
        ],
      ),
    ),
  );
}
