import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';

class WeeklyGroupQuest extends StatelessWidget {
  const WeeklyGroupQuest({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('WEEKLY GROUP SIDEQUEST'),
      const SizedBox(height: 14),
      Panel(
        color: const Color(0xFFA879FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFA879FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.group.weeklyChallengeProgress >= 10
                        ? 'Challenge complete!'
                        : 'Try Something New',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "As a group, complete 10 SideQuests from categories you haven't explored much.",
              style: TextStyle(color: muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '${state.group.weeklyChallengeProgress} / 10',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Text(
                  '+500 GROUP XP',
                  style: TextStyle(
                    color: Color(0xFFA879FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SmoothBar(
              value: state.group.weeklyChallengeProgress / 10,
              color: const Color(0xFFA879FF),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: state.group.members
                  .map(
                    (f) => Text(
                      '${f.name} · ${f.id == 0 ? 2 + state.challengeContributions.length : f.questsCompleted} quests',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ],
  );
}
