import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import 'activity_tree_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    const titles = [
      'Connected',
      'Explorer',
      'Creative Mind',
      'Adventurer',
      'Friendly Competition',
      'Pathfinder',
    ];
    const descriptions = [
      'Discover your first activity connection.',
      'Complete 5 Exploration SideQuests.',
      'Complete 5 Creativity SideQuests.',
      'Complete 10 SideQuests.',
      'Reach #1 in your group leaderboard.',
      'Open 10 new activities through completed tasks.',
    ];
    const icons = [
      Icons.hub_outlined,
      Icons.explore_outlined,
      Icons.palette_outlined,
      Icons.landscape_outlined,
      Icons.emoji_events_outlined,
      Icons.route_outlined,
    ];
    final achievements = state.achievements;
    return PageBody(
      children: [
        const PageHeading('Your Journey', ''),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityTreeScreen(state: state),
              ),
            ),
            icon: const Icon(Icons.account_tree_outlined, size: 20),
            label: const Text('Activity tree'),
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          color: green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: green),
                  const SizedBox(width: 12),
                  Text(
                    'Level ${state.level}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              XPBar(totalXP: state.totalXP),
            ],
          ),
        ),
        const SizedBox(height: 30),
        StatStrip(
          values: [
            '${state.completedCount}',
            '${state.connectionCount}',
            '${achievements.where((a) => a).length}',
          ],
          labels: const ['SideQuests', 'Connections', 'Achievements'],
        ),
        const SizedBox(height: 34),
        const Eyebrow('YOUR PATHS'),
        const SizedBox(height: 16),
        ...Category.values.map((c) {
          final base = state.demoData ? [4, 3, 3, 2, 2, 1][c.index] : 1;
          final count = state.categoryCount(c);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(c.icon, color: c.color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Level ${base + count ~/ 3}',
                              style: TextStyle(color: c.color, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SmoothBar(
                          value: state.demoData
                              ? ((base + count) % 5 + 1) / 6
                              : (count % 3) / 3,
                          color: c.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 22),
        const Eyebrow('ACHIEVEMENTS'),
        const SizedBox(height: 16),
        ...List.generate(
          titles.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: achievements[i] ? 1 : .5,
              child: Panel(
                color: achievements[i] ? Category.values[i].color : null,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(icons[i], color: Category.values[i].color, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[i],
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            descriptions[i],
                            style: const TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      achievements[i]
                          ? Icons.check_circle_outline
                          : Icons.lock_outline,
                      color: achievements[i] ? Category.values[i].color : muted,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
