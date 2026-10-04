import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import 'activity_tree_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.state});
  final AppState state;
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  AppState get state => widget.state;
  bool overTree = false, touchingTree = false;
  @override
  Widget build(BuildContext context) {
    return PageBody(
      scrollPhysics: overTree || touchingTree
          ? const NeverScrollableScrollPhysics()
          : null,
      children: [
        const PageHeading('Your Journey', ''),
        Panel(
          color: context.palette.green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: context.palette.green,
                  ),
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
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 600,
            child: MouseRegion(
              onEnter: (_) => setState(() => overTree = true),
              onExit: (_) => setState(() => overTree = false),
              child: Listener(
                onPointerDown: (_) => setState(() => touchingTree = true),
                onPointerUp: (_) => setState(() => touchingTree = false),
                onPointerCancel: (_) => setState(() => touchingTree = false),
                child: ActivityTreeScreen(state: state, embedded: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        StatStrip(
          values: ['${state.completedCount}', '${state.connectionCount}'],
          labels: const ['SideQuests', 'Connections'],
        ),
        const SizedBox(height: 30),
        const Eyebrow('YOUR PATHS'),
        const SizedBox(height: 16),
        ...Category.values.map((c) {
          final base = state.hasSeededProgress
              ? [4, 3, 3, 2, 2, 1][c.index]
              : 1;
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
                          value: state.hasSeededProgress
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
      ],
    );
  }
}
