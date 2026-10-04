import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/sample_quests.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import 'quest_detail_screen.dart';

class ActivityTreeScreen extends StatefulWidget {
  const ActivityTreeScreen({
    super.key,
    required this.state,
    this.questId = 13,
    this.embedded = false,
    this.onReturnQuests,
  });
  final AppState state;
  final int questId;
  final bool embedded;
  final VoidCallback? onReturnQuests;
  @override
  State<ActivityTreeScreen> createState() => _ActivityTreeScreenState();
}

class _ActivityTreeScreenState extends State<ActivityTreeScreen>
    with SingleTickerProviderStateMixin {
  late int selected = widget.questId;
  final camera = TransformationController();
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool positioned = false;
  bool reducedMotion = false;
  Size viewport = Size.zero, mapSize = Size.zero;
  Map<int, Rect> positions = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      pulse.stop();
      pulse.value = .5;
    } else if (!pulse.isAnimating) {
      pulse.repeat();
    }
  }

  int depth(int id) {
    final parents = questParents[id] ?? [];
    return parents.isEmpty ? 0 : 1 + parents.map(depth).reduce(math.max);
  }

  Set<int> relatedTo(int id) {
    final related = <int>{};
    void ancestors(int current) {
      if (!related.add(current)) return;
      for (final parent in questParents[current] ?? <int>[]) {
        ancestors(parent);
      }
    }

    void descendants(int current) {
      for (final entry in questParents.entries) {
        if (entry.value.contains(current)) {
          ancestors(entry.key);
          descendants(entry.key);
        }
      }
    }

    ancestors(id);
    descendants(id);
    return related;
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
    final point = camera.toScene(viewport.center(Offset.zero));
    center(point, (camera.value.entry(0, 0) * factor).clamp(.12, 2.5));
  }

  void fitAll() {
    center(
      mapSize.center(Offset.zero),
      math
          .min(
            (viewport.width - 48) / mapSize.width,
            (viewport.height - 48) / mapSize.height,
          )
          .clamp(.12, 2.5),
    );
  }

  void focusSelected() => center(positions[selected]!.center, .9);

  void openSelected() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QuestDetailScreen(
        state: widget.state,
        quest: widget.state.quest(selected),
        onStopTask: widget.onReturnQuests,
      ),
    ),
  );

  @override
  void dispose() {
    pulse.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (_, _) {
      final related = relatedTo(selected);
      final layers = <int, List<int>>{};
      for (final q in widget.state.quests) {
        layers.putIfAbsent(depth(q.id), () => []).add(q.id);
      }
      positions = {};
      var maxBottom = 0.0;
      for (final level in layers.keys.toList()..sort()) {
        final row = layers[level]!;
        if (level == 0) {
          row.sort(
            (a, b) => widget.state
                .quest(a)
                .categories
                .first
                .index
                .compareTo(widget.state.quest(b).categories.first.index),
          );
        }
        double desiredY(int id) {
          final parents = questParents[id] ?? [];
          if (parents.isEmpty) return row.indexOf(id) * 196 + 100;
          return parents
                  .map((id) => positions[id]!.top)
                  .reduce((a, b) => a + b) /
              parents.length;
        }

        if (level > 0) row.sort((a, b) => desiredY(a).compareTo(desiredY(b)));
        var cursor = 100.0;
        for (final id in row) {
          final y = math.max(cursor, desiredY(id));
          positions[id] = Rect.fromLTWH(64 + level * 324, y, 220, 158);
          cursor = y + 196;
          maxBottom = math.max(maxBottom, y + 158);
        }
      }
      mapSize = Size(
        (layers.keys.reduce(math.max) + 1) * 324 + 128,
        maxBottom + 100,
      );
      final current = widget.state.quest(selected);
      final parents = questParents[selected] ?? <int>[];
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          title: const Text('Activity tree'),
          actions: [
            IconButton(
              tooltip: 'Zoom out',
              onPressed: () => zoom(.8),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: () => zoom(1.25),
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: 'Fit entire tree',
              onPressed: fitAll,
              icon: const Icon(Icons.fullscreen_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: !widget.embedded,
          bottom: !widget.embedded,
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
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -.3),
                                radius: 1.1,
                                colors: [
                                  Color.alphaBlend(
                                    current.color.withValues(alpha: .055),
                                    background,
                                  ),
                                  background,
                                ],
                              ),
                            ),
                          ),
                        ),
                        InteractiveViewer(
                          key: const ValueKey('quest-tree-map'),
                          transformationController: camera,
                          constrained: false,
                          minScale: .12,
                          maxScale: 2.5,
                          boundaryMargin: const EdgeInsets.all(650),
                          child: SizedBox(
                            width: mapSize.width,
                            height: mapSize.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _BranchPainter(
                                      positions: positions,
                                      related: related,
                                      colors: {
                                        for (final q in widget.state.quests)
                                          q.id: q.color,
                                      },
                                      pulse: pulse,
                                      reducedMotion: reducedMotion,
                                    ),
                                  ),
                                ),
                                for (final entry in positions.entries)
                                  Positioned.fromRect(
                                    rect: entry.value,
                                    child: _QuestOrb(
                                      key: ValueKey('tree-task-${entry.key}'),
                                      quest: widget.state.quest(entry.key),
                                      selected: selected == entry.key,
                                      related: related.contains(entry.key),
                                      pulse: pulse,
                                      reducedMotion: reducedMotion,
                                      onTap: () =>
                                          setState(() => selected = entry.key),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: IconButton.filledTonal(
                            tooltip: 'Reset view',
                            onPressed: focusSelected,
                            icon: const Icon(
                              Icons.center_focus_strong_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 20,
                          bottom: 20,
                          child: IgnorePointer(
                            child: Text(
                              'Explore your connections',
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(
                    top: BorderSide(
                      color: current.color.withValues(alpha: .16),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: current.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            current.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: 'View quest',
                          onPressed: openSelected,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (parents.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Unlocks after ${parents.map((id) => widget.state.quest(id).title).join(' + ')}',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: Category.values
                          .map(
                            (c) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: c.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  c.label,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
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

class _QuestOrb extends StatelessWidget {
  const _QuestOrb({
    super.key,
    required this.quest,
    required this.selected,
    required this.related,
    required this.pulse,
    required this.reducedMotion,
    required this.onTap,
  });
  final Quest quest;
  final bool selected, related, reducedMotion;
  final Animation<double> pulse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final status = quest.isActive
        ? 'Active'
        : quest.isCompleted
        ? 'Completed'
        : quest.isLocked
        ? 'Locked'
        : 'Available';
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${quest.title}, $status, ${quest.categories.map((c) => c.label).join(', ')}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(80),
          onTap: onTap,
          child: Column(
            children: [
              SizedBox(
                height: 88,
                width: 100,
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, _) {
                    final wave = reducedMotion
                        ? .5
                        : (math.sin(pulse.value * math.pi * 2) + 1) / 2;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (related)
                          Container(
                            width: 74 + wave * 12,
                            height: 74 + wave * 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: quest.color.withValues(
                                  alpha: .12 + (1 - wave) * .16,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: quest.color.withValues(
                                    alpha: .06 + wave * .05,
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.alphaBlend(
                              quest.color.withValues(
                                alpha: quest.isLocked ? .04 : .13,
                              ),
                              surface,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _OrbRingPainter(
                              quest.categories,
                              selected,
                              quest.isLocked,
                            ),
                            child: Icon(
                              quest.categories.first.icon,
                              size: 27,
                              color: quest.color.withValues(
                                alpha: quest.isLocked ? .6 : 1,
                              ),
                            ),
                          ),
                        ),
                        if (quest.isLocked)
                          Positioned(
                            right: 14,
                            bottom: 9,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 11,
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  quest.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: related
                        ? Colors.white
                        : Colors.white.withValues(alpha: .72),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: quest.categories
                    .map(
                      (c) => Text(
                        c.label,
                        style: TextStyle(
                          color: c.color.withValues(alpha: .85),
                          fontSize: 9,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 9,
                  color: quest.isLocked ? muted : quest.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  _OrbRingPainter(this.categories, this.selected, this.locked);
  final List<Category> categories;
  final bool selected, locked;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final segment = math.pi * 2 / categories.length;
    for (var i = 0; i < categories.length; i++) {
      canvas.drawArc(
        rect.deflate(1.5),
        -math.pi / 2 + segment * i + .07,
        segment - .14,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round
          ..color = categories[i].color.withValues(
            alpha: locked
                ? .38
                : selected
                ? 1
                : .7,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbRingPainter old) =>
      categories != old.categories ||
      selected != old.selected ||
      locked != old.locked;
}

class _BranchPainter extends CustomPainter {
  _BranchPainter({
    required this.positions,
    required this.related,
    required this.colors,
    required this.pulse,
    required this.reducedMotion,
  }) : super(repaint: pulse);
  final Map<int, Rect> positions;
  final Set<int> related;
  final Map<int, Color> colors;
  final Animation<double> pulse;
  final bool reducedMotion;
  @override
  void paint(Canvas canvas, Size size) {
    final dust = Paint()..color = Colors.white.withValues(alpha: .035);
    for (double x = 24; x < size.width; x += 40) {
      for (double y = 24; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), .8, dust);
      }
    }
    for (final child in positions.keys) {
      for (final parent in questParents[child] ?? <int>[]) {
        final from = positions[parent]!, to = positions[child]!;
        final start = Offset(from.center.dx + 37, from.top + 44);
        final end = Offset(to.center.dx - 37, to.top + 44);
        final distance = end.dx - start.dx;
        final path = Path()..moveTo(start.dx, start.dy);
        if (to.left - from.right > 140) {
          // Skip-level dependencies arc through the gap above the node row,
          // so an unrelated intermediate quest never looks like a prerequisite.
          final lane = math.min(start.dy, end.dy) - 64;
          path
            ..cubicTo(
              start.dx + 50,
              start.dy,
              start.dx + 50,
              lane,
              start.dx + 100,
              lane,
            )
            ..lineTo(end.dx - 100, lane)
            ..cubicTo(end.dx - 50, lane, end.dx - 50, end.dy, end.dx, end.dy);
        } else {
          path.cubicTo(
            start.dx + distance * .45,
            start.dy,
            end.dx - distance * .45,
            end.dy,
            end.dx,
            end.dy,
          );
        }
        final active = related.contains(child) && related.contains(parent);
        final color = colors[child] ?? green;
        if (active) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = color.withValues(alpha: .07)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = active ? 1.8 : 1
            ..shader = LinearGradient(
              colors: [
                (colors[parent] ?? color).withValues(alpha: active ? .65 : .13),
                color.withValues(alpha: active ? .65 : .13),
              ],
            ).createShader(Rect.fromPoints(start, end).inflate(1)),
        );
        if (active && !reducedMotion) {
          final metric = path.computeMetrics().first;
          final point = metric
              .getTangentForOffset(
                metric.length * ((pulse.value + child * .13) % 1),
              )!
              .position;
          canvas.drawCircle(
            point,
            7,
            Paint()..color = color.withValues(alpha: .12),
          );
          canvas.drawCircle(
            point,
            2.5,
            Paint()..color = color.withValues(alpha: .95),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BranchPainter old) => true;
}
