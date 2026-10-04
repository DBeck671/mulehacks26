import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';

class HomeLeaderboard extends StatelessWidget {
  const HomeLeaderboard({
    super.key,
    required this.state,
    required this.openFriends,
  });
  final AppState state;
  final VoidCallback openFriends;
  @override
  Widget build(BuildContext context) {
    if (!state.hasGroup) {
      return TextButton.icon(
        onPressed: openFriends,
        icon: const Icon(Icons.groups_outlined, size: 18),
        label: const Text('Join a club to share the adventure'),
      );
    }
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Leaderboard',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: openFriends,
                tooltip: 'Open clubs',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.groups_outlined, color: muted, size: 20),
              ),
            ],
          ),
          Text(
            '${state.group.name} · Weekly XP',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...state.leaderboard.asMap().entries.map((entry) {
            final f = entry.value;
            final me = f.id == state.you.id;
            return Container(
              key: ValueKey('home-rank-${f.id}'),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: me ? green.withValues(alpha: .07) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        color: entry.key == 0 ? const Color(0xFFFFD166) : muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: raised,
                    child: Text(
                      f.avatarInitial,
                      style: TextStyle(color: me ? green : muted, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.name,
                      style: TextStyle(
                        color: me ? green : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (state.badgeFor(f) case final badge?) ...[
                    Tooltip(
                      message: badge.title,
                      child: Icon(badge.icon, color: badge.color, size: 15),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: f.xp.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, xp, _) => Text(
                      '${xp.round()} XP',
                      style: TextStyle(
                        color: me ? green : muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
