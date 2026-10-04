import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/sample_quests.dart';
import '../widgets/common.dart';
import 'quest_detail_screen.dart';

class ActivityTreeScreen extends StatefulWidget {
  const ActivityTreeScreen({super.key, required this.state, this.questId = 13});
  final AppState state;
  final int questId;
  @override
  State<ActivityTreeScreen> createState() => _ActivityTreeScreenState();
}

class _ActivityTreeScreenState extends State<ActivityTreeScreen> {
  late int selected = widget.questId;
  int depth(int id) {
    final parents = questParents[id] ?? [];
    return parents.isEmpty ? 0 : 1 + parents.map(depth).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (_, _) {
      final ids = <int>{};
      void include(int id) {
        if (!ids.add(id)) return;
        for (final parent in questParents[id] ?? <int>[]) {
          include(parent);
        }
      }

      include(selected);
      final layers = <int, List<int>>{};
      for (final id in ids.toList()..sort()) {
        layers.putIfAbsent(depth(id), () => []).add(id);
      }
      final target = widget.state.quest(selected);
      return Scaffold(
        appBar: AppBar(title: const Text('Activity tree')),
        body: SafeArea(
          child: PageBody(
            children: [
              const PageHeading(
                'Find your path',
                'Follow the connections to unlock your next adventure.',
              ),
              DropdownButtonFormField<int>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'See unlock path for',
                ),
                items: widget.state.quests
                    .map(
                      (q) => DropdownMenuItem(
                        value: q.id,
                        child: Text(q.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) setState(() => selected = id);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete every connected task above to unlock your goal. Tap a task for details.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final positions = <int, Rect>{};
                  var y = 0.0;
                  for (final level in layers.keys.toList()..sort()) {
                    final row = layers[level]!;
                    final columns = math.min(2, row.length);
                    final width =
                        (constraints.maxWidth - 24 - (columns - 1) * 12) /
                        columns;
                    for (var i = 0; i < row.length; i++) {
                      positions[row[i]] = Rect.fromLTWH(
                        12 + (i % columns) * (width + 12),
                        y + (i ~/ columns) * 116,
                        width,
                        100,
                      );
                    }
                    y += ((row.length / columns).ceil()) * 116 + 42;
                  }
                  return SizedBox(
                    height: y - 42,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BranchPainter(positions),
                          ),
                        ),
                        ...positions.entries.map((entry) {
                          final q = widget.state.quest(entry.key);
                          final rect = entry.value;
                          final status = q.isCompleted
                              ? 'Completed'
                              : q.isLocked
                              ? 'Locked'
                              : 'Available';
                          return Positioned.fromRect(
                            rect: rect,
                            child: Semantics(
                              button: true,
                              label: '${q.title}, $status',
                              child: Material(
                                key: ValueKey('tree-task-${q.id}'),
                                color: surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: q.id == selected ? green : raised,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuestDetailScreen(
                                        state: widget.state,
                                        quest: q,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              q.isCompleted
                                                  ? Icons.check_circle_outline
                                                  : q.isLocked
                                                  ? Icons.lock_outline
                                                  : Icons.play_circle_outline,
                                              size: 17,
                                              color: q.isLocked ? muted : green,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: q.isLocked
                                                    ? muted
                                                    : green,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 9),
                                        Expanded(
                                          child: Text(
                                            q.title,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                target.isLocked
                    ? 'Complete the tasks above ${target.title} to unlock it.'
                    : '${target.title} is ${target.isCompleted ? 'completed and can be repeated' : 'ready to start'}.',
                style: const TextStyle(color: muted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BranchPainter extends CustomPainter {
  _BranchPainter(this.positions);
  final Map<int, Rect> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = green.withValues(alpha: .3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final child in positions.keys) {
      for (final parent in questParents[child] ?? <int>[]) {
        final from = positions[parent];
        if (from == null) continue;
        final start = from.bottomCenter, end = positions[child]!.topCenter;
        final middle = (start.dy + end.dy) / 2;
        final path = Path()..moveTo(start.dx, start.dy);
        if (end.dy - start.dy > 100) {
          // Skip-level dependencies run beside cards instead of disappearing
          // behind an intermediate task and implying a false prerequisite.
          final side = start.dx < size.width / 2 ? 2.0 : size.width - 2;
          path
            ..cubicTo(
              start.dx,
              start.dy + 20,
              side,
              start.dy + 20,
              side,
              start.dy + 32,
            )
            ..lineTo(side, end.dy - 24)
            ..cubicTo(side, end.dy - 12, end.dx, end.dy - 12, end.dx, end.dy);
        } else {
          path.cubicTo(start.dx, middle, end.dx, middle, end.dx, end.dy);
        }
        canvas.drawPath(path, paint);
        canvas.drawCircle(
          Offset(end.dx, end.dy - 4),
          3,
          Paint()..color = green,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BranchPainter oldDelegate) => true;
}
