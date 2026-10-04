import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../app_state.dart';
import '../data/sample_quests.dart';
import '../models/quest.dart';
import '../widgets/common.dart';

class ActivityTreeScreen extends StatefulWidget {
  const ActivityTreeScreen({
    super.key,
    required this.state,
    this.questId = 1,
    this.embedded = false,
  });
  final AppState state;
  final int questId;
  final bool embedded;
  @override
  State<ActivityTreeScreen> createState() => _ActivityTreeScreenState();
}

class _ActivityTreeScreenState extends State<ActivityTreeScreen>
    with SingleTickerProviderStateMixin {
  final camera = TransformationController();
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool positioned = false, reducedMotion = false;
  String activeSignature = '';
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

  Set<int> neighbors(Set<int> active) {
    final related = {...active};
    for (final entry in questParents.entries) {
      if (active.contains(entry.key)) related.addAll(entry.value);
      if (entry.value.any(active.contains)) related.add(entry.key);
    }
    return related;
  }

  void focusTasks(List<Quest> active) {
    if (viewport.isEmpty) return;
    final target = positions[active.firstOrNull?.id ?? widget.questId]!;
    camera.value = Matrix4.diagonal3Values(.85, .85, .85)
      ..setTranslationRaw(
        viewport.width / 2 - target.center.dx * .85,
        viewport.height / 2 - target.center.dy * .85,
        0,
      );
  }

  void zoom(double factor) {
    if (viewport.isEmpty) return;
    final current = camera.value;
    final oldScale = current.getMaxScaleOnAxis();
    final nextScale = (oldScale * factor).clamp(.35, 1.8);
    final center = viewport.center(Offset.zero);
    camera.value = Matrix4.diagonal3Values(nextScale, nextScale, nextScale)
      ..setTranslationRaw(
        center.dx - (center.dx - current.storage[12]) * nextScale / oldScale,
        center.dy - (center.dy - current.storage[13]) * nextScale / oldScale,
        0,
      );
  }

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
      final active = widget.state.activeQuests;
      final activeIds = active.map((q) => q.id).toSet();
      final related = neighbors(activeIds);
      final signature = activeIds.join(',');
      if (signature != activeSignature) {
        activeSignature = signature;
        positioned = false;
      }
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
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          title: const Text('Activity tree'),
          actions: [
            IconButton(
              tooltip: 'Zoom out',
              onPressed: () => zoom(1 / 1.25),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: () => zoom(1.25),
              icon: const Icon(Icons.add_rounded),
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
                    if (viewport != constraints.biggest) positioned = false;
                    viewport = constraints.biggest;
                    if (!positioned) {
                      positioned = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) focusTasks(widget.state.activeQuests);
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
                                    (active.firstOrNull?.color ?? green)
                                        .withValues(alpha: .055),
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
                          scaleEnabled: true,
                          panEnabled: true,
                          minScale: .35,
                          maxScale: 1.8,
                          // Wheel events pan through our signal handler; pinch zooms.
                          scaleFactor: double.infinity,
                          boundaryMargin: const EdgeInsets.all(650),
                          child: Listener(
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent) {
                                GestureBinding.instance.pointerSignalResolver
                                    .register(event, (_) {
                                      // InteractiveViewer already pans trackpad events.
                                      // Claim the event so an ancestor cannot scroll too.
                                      if (event.kind !=
                                          PointerDeviceKind.trackpad) {
                                        final next = camera.value.clone();
                                        next.setTranslationRaw(
                                          next.storage[12] -
                                              event.scrollDelta.dx,
                                          next.storage[13] -
                                              event.scrollDelta.dy,
                                          next.storage[14],
                                        );
                                        camera.value = next;
                                      }
                                    });
                              }
                            },
                            child: SizedBox(
                              width: mapSize.width,
                              height: mapSize.height,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _BranchPainter(
                                        positions: positions,
                                        activeIds: activeIds,
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
                                        related: related.contains(entry.key),
                                        pulse: pulse,
                                        reducedMotion: reducedMotion,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 20,
                          bottom: 16,
                          child: IgnorePointer(
                            child: Text(
                              'Drag to explore · Pinch to zoom',
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(
                    top: BorderSide(color: green.withValues(alpha: .12)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('ACTIVE QUESTS'),
                    if (active.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'No active quests',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                    for (final quest in active)
                      Padding(
                        key: ValueKey('active-tree-summary-${quest.id}'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              quest.categories.first.icon,
                              color: quest.color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          quest.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        quest.attemptClock.isRunning
                                            ? 'In progress'
                                            : 'Paused',
                                        style: TextStyle(
                                          color: quest.color,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quest.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
    required this.related,
    required this.pulse,
    required this.reducedMotion,
  });
  final Quest quest;
  final bool related, reducedMotion;
  final Animation<double> pulse;
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
      label:
          '${quest.title}, $status, ${quest.categories.map((c) => c.label).join(', ')}',
      child: Column(
        children: [
          SizedBox(
            height: 88,
            width: 100,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, _) {
                final wave = reducedMotion || !quest.isActive
                    ? .5
                    : (math.sin(pulse.value * math.pi * 2) + 1) / 2;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (related || quest.isActive)
                      Container(
                        key: quest.isActive
                            ? ValueKey('active-tree-pulse-${quest.id}')
                            : null,
                        width: 74 + wave * 12,
                        height: 74 + wave * 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: quest.color.withValues(
                              alpha: quest.isActive
                                  ? .35 + (1 - wave) * .35
                                  : .12,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: quest.color.withValues(
                                alpha: quest.isActive ? .15 + wave * .15 : .06,
                              ),
                              blurRadius: quest.isActive ? 20 + wave * 12 : 28,
                              spreadRadius: quest.isActive ? 2 + wave * 3 : 3,
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
                          quest.isActive,
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
                fontWeight: quest.isActive ? FontWeight.w700 : FontWeight.w500,
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
    required this.activeIds,
    required this.colors,
    required this.pulse,
    required this.reducedMotion,
  }) : super(repaint: pulse);
  final Map<int, Rect> positions;
  final Set<int> activeIds;
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
        final active = activeIds.contains(child) || activeIds.contains(parent);
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
