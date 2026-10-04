import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../models/verification.dart';
import 'common.dart';

class QuestRowCard extends StatelessWidget {
  const QuestRowCard({super.key, required this.quest, required this.onTap});
  final Quest quest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: quest.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                quest.isLocked
                    ? Icons.lock_outline
                    : quest.categories.first.icon,
                color: quest.color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${quest.duration} · ${quest.verification.method.label}',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.isActive
                        ? '${quest.attemptClock.isRunning ? 'In progress' : 'Paused'} · ${quest.attemptClock.elapsed.inMinutes}:${(quest.attemptClock.elapsed.inSeconds % 60).toString().padLeft(2, '0')} · ${quest.verification.isSatisfied ? 'Ready to complete' : 'Needs verification'}'
                        : quest.status,
                    style: TextStyle(
                      color: quest.isActive
                          ? quest.color
                          : context.palette.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                  '+${quest.rewardXP} XP',
                  style: TextStyle(
                    color: quest.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.palette.muted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
