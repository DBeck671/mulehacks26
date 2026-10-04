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
    color: surface,
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
                    : quest.isCompleted
                    ? Icons.check_rounded
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
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.status,
                    style: TextStyle(
                      color: quest.isActive ? quest.color : muted,
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
                const Icon(Icons.chevron_right_rounded, color: muted, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
