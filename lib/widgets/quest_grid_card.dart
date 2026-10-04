import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../models/verification.dart';
import 'common.dart';

class QuestGridCard extends StatelessWidget {
  const QuestGridCard({super.key, required this.quest, required this.onTap});
  final Quest quest;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${quest.title}, ${quest.status}, ${quest.duration}, ${quest.rewardXP} XP, ${quest.verification.method.label}',
    child: Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: quest.isActive
                  ? quest.color
                  : context.palette.text.withValues(alpha: .08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    quest.isLocked
                        ? Icons.lock_outline
                        : quest.categories.first.icon,
                    color: quest.color,
                    size: 21,
                  ),
                  const Spacer(),
                  Text(
                    quest.status.toUpperCase(),
                    style: TextStyle(
                      color: quest.isActive || quest.isNew
                          ? quest.color
                          : context.palette.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  quest.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.duration,
                      maxLines: 1,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    '+${quest.rewardXP} XP',
                    style: TextStyle(
                      color: quest.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
