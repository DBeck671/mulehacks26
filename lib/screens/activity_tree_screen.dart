import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/sample_quests.dart';
import '../models/quest.dart';
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
      final ids = widget.state.quests.map((q) => q.id).toSet();
      final highlighted = <int>{};
      void include(int id) {
        if (!highlighted.add(id)) return;
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
                'All sidequests',
                'Every quest and its unlock connections.',
              ),
              DropdownButtonFormField<int>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Highlight a quest',
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
                'Lines connect prerequisites to the tasks they unlock. Complete every prerequisite. Tap any task for details.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: Category.values
                    .map(
                      (c) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, color: c.color, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            c.label,
                            style: TextStyle(color: c.color, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                    .toList(),
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
                        y + (i ~/ columns) * 180,
                        width,
                        164,
                      );
                    }
                    y += ((row.length / columns).ceil()) * 180 + 42;
                  }
                  return SizedBox(
                    height: y - 42,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BranchPainter(positions, highlighted, {
                              for (final q in widget.state.quests)
                                q.id: q.color,
                            }),
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
                                color: Color.alphaBlend(
                                  q.color.withValues(alpha: .06),
                                  surface,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: q.color.withValues(
                                      alpha: highlighted.contains(q.id)
                                          ? .9
                                          : .35,
                                    ),
                                    width: highlighted.contains(q.id) ? 2 : 1,
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
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: q.categories
                                              .map(
                                                (category) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: category.color
                                                        .withValues(alpha: .12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    category.label,
                                                    style: TextStyle(
                                                      color: category.color,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        const SizedBox(height: 8),
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
                                        const SizedBox(height: 6),
                                        Text(
                                          (questParents[q.id] ?? []).isEmpty
                                              ? 'Starting quest'
                                              : 'Requires: ${(questParents[q.id] ?? []).map((id) => widget.state.quest(id).title).join(' + ')}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 10,
                                            height: 1.2,
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
  _BranchPainter(this.positions, this.highlighted, this.colors);
  final Map<int, Rect> positions;
  final Set<int> highlighted;
  final Map<int, Color> colors;
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
        paint.color =
            (highlighted.contains(child) && highlighted.contains(parent))
            ? (colors[child] ?? green).withValues(alpha: .85)
            : (colors[child] ?? muted).withValues(alpha: .4);
        canvas.drawPath(path, paint);
        canvas.drawCircle(
          Offset(end.dx, end.dy - 4),
          3,
          Paint()..color = paint.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BranchPainter oldDelegate) => true;
}
