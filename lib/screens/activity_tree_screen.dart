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
  final camera = TransformationController();
  bool positioned = false;
  Size viewport = Size.zero, mapSize = Size.zero;
  Map<int, Rect> positions = {};
  int depth(int id) {
    final parents = questParents[id] ?? [];
    return parents.isEmpty ? 0 : 1 + parents.map(depth).reduce(math.max);
  }

  void center(Offset point, double scale) {
    if (viewport.isEmpty) return;
    camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        viewport.width / 2 - point.dx * scale,
        viewport.height / 2 - point.dy * scale,
        0,
      );
  }

  void zoom(double factor) {
    final point = camera.toScene(
      Offset(viewport.width / 2, viewport.height / 2),
    );
    center(point, (camera.value.entry(0, 0) * factor).clamp(.15, 2.5));
  }

  void fitAll() {
    final scale = math
        .min(
          (viewport.width - 24) / mapSize.width,
          (viewport.height - 24) / mapSize.height,
        )
        .clamp(.15, 2.5);
    center(mapSize.center(Offset.zero), scale);
  }

  void focusSelected() => center(positions[selected]!.center, 1);
  @override
  void dispose() {
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (_, _) {
      final highlighted = <int>{};
      void include(int id) {
        if (!highlighted.add(id)) return;
        for (final parent in questParents[id] ?? <int>[]) {
          include(parent);
        }
      }

      include(selected);
      final layers = <int, List<int>>{};
      for (final q in widget.state.quests) {
        layers.putIfAbsent(depth(q.id), () => []).add(q.id);
      }
      positions = {};
      var maxBottom = 0.0;
      for (final level in layers.keys.toList()..sort()) {
        final row = layers[level]!;
        double desiredY(int id) {
          final parents = questParents[id] ?? [];
          if (parents.isEmpty) return row.indexOf(id) * 200 + 120;
          return parents
                      .map((id) => positions[id]!.center.dy)
                      .reduce((a, b) => a + b) /
                  parents.length -
              82;
        }

        if (level > 0) row.sort((a, b) => desiredY(a).compareTo(desiredY(b)));
        var cursor = 120.0;
        for (final id in row) {
          final y = math.max(cursor, desiredY(id));
          positions[id] = Rect.fromLTWH(80 + level * 340, y, 240, 164);
          cursor = y + 200;
          maxBottom = math.max(maxBottom, y + 164);
        }
      }
      mapSize = Size(
        (layers.keys.reduce(math.max) + 1) * 340 + 80,
        maxBottom + 100,
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Activity tree'),
          actions: [
            IconButton(
              tooltip: 'Zoom out',
              onPressed: () => zoom(.8),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: () => zoom(1.25),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'Fit entire tree',
              onPressed: fitAll,
              icon: const Icon(Icons.fit_screen),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    viewport = constraints.biggest;
                    if (!positioned) {
                      positioned = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) focusSelected();
                      });
                    }
                    return Stack(
                      children: [
                        InteractiveViewer(
                          key: const ValueKey('quest-tree-map'),
                          transformationController: camera,
                          constrained: false,
                          minScale: .15,
                          maxScale: 2.5,
                          boundaryMargin: const EdgeInsets.all(800),
                          child: SizedBox(
                            width: mapSize.width,
                            height: mapSize.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _BranchPainter(
                                      positions,
                                      highlighted,
                                      {
                                        for (final q in widget.state.quests)
                                          q.id: q.color,
                                      },
                                    ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: BorderSide(
                                            color: q.color.withValues(
                                              alpha: highlighted.contains(q.id)
                                                  ? .9
                                                  : .35,
                                            ),
                                            width: highlighted.contains(q.id)
                                                ? 2
                                                : 1,
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
                                                      q.categories.first.icon,
                                                      size: 17,
                                                      color: q.isLocked
                                                          ? muted
                                                          : green,
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
                                                            color: category
                                                                .color
                                                                .withValues(
                                                                  alpha: .12,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            category.label,
                                                            style: TextStyle(
                                                              color: category
                                                                  .color,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  (questParents[q.id] ?? [])
                                                          .isEmpty
                                                      ? 'Starting quest'
                                                      : 'Requires: ${(questParents[q.id] ?? []).map((id) => widget.state.quest(id).title).join(' + ')}',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'tree-focus',
                            tooltip: 'Reset view',
                            onPressed: focusSelected,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    const Text(
                      'Drag to explore · Pinch to zoom · Tap a quest',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: Category.values
                          .map(
                            (c) => Text(
                              c.label,
                              style: TextStyle(color: c.color, fontSize: 11),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
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
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (final child in positions.keys) {
      for (final parent in questParents[child] ?? <int>[]) {
        final from = positions[parent]!;
        final to = positions[child]!;
        final start = from.centerRight, end = to.centerLeft;
        final path = Path()..moveTo(start.dx, start.dy);
        if (to.left - from.right > 140) {
          // Longer dependencies use the clear lane above the node columns.
          path
            ..lineTo(start.dx + 30, start.dy)
            ..lineTo(start.dx + 30, 60)
            ..lineTo(end.dx - 30, 60)
            ..lineTo(end.dx - 30, end.dy)
            ..lineTo(end.dx, end.dy);
        } else {
          final middle = (start.dx + end.dx) / 2;
          path.cubicTo(middle, start.dy, middle, end.dy, end.dx, end.dy);
        }
        paint.color = (colors[child] ?? green).withValues(
          alpha: highlighted.contains(child) && highlighted.contains(parent)
              ? .9
              : .45,
        );
        canvas.drawPath(path, paint);
        canvas.drawCircle(end, 3, Paint()..color = paint.color);
      }
    }
  }

  @override
  bool shouldRepaint(_BranchPainter oldDelegate) => true;
}
