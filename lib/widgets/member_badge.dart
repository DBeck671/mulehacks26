import 'package:flutter/material.dart';

import '../models/reward.dart';

class MemberBadge extends StatelessWidget {
  const MemberBadge({super.key, required this.badge});
  final QuestBadge badge;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: badge.requirement,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badge.color.withValues(alpha: .18),
            badge.color.withValues(alpha: .04),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 11, color: badge.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: badge.color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
