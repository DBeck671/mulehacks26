import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';

class WeeklyGroupQuest extends StatelessWidget {
  const WeeklyGroupQuest({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final club = state.group;
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('WEEKLY GROUP SIDEQUEST'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  club.weeklyChallengeProgress >= club.weeklyChallengeGoal
                      ? 'Challenge complete!'
                      : 'Try Something New',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '+500 GROUP XP',
                style: TextStyle(
                  color: context.palette.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Complete ${club.weeklyChallengeGoal} SideQuests from less-explored categories together.",
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SmoothBar(
                  value:
                      club.weeklyChallengeProgress / club.weeklyChallengeGoal,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${club.weeklyChallengeProgress} / ${club.weeklyChallengeGoal}',
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
