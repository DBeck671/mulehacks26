import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../models/verification.dart';

const background = Color(0xFF0F1117);
const surface = Color(0xFF181C24);
const raised = Color(0xFF202631);
const green = Color(0xFF6EEB83);
const muted = Color(0xFF929BAB);

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: (color ?? Colors.white).withValues(
          alpha: color == null ? .07 : .3,
        ),
      ),
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: muted, height: 1.5)),
        ],
      ],
    ),
  );
}

class XPBar extends StatelessWidget {
  const XPBar({
    super.key,
    required this.totalXP,
    this.color = green,
    this.animate = true,
  });
  final int totalXP;
  final Color color;
  final bool animate;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Eyebrow('Level ${totalXP ~/ 1000 + 1}', color: color),
          const Spacer(),
          Text(
            '${totalXP % 1000} / 1000 XP',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SmoothBar(value: (totalXP % 1000) / 1000, color: color, animate: animate),
    ],
  );
}

class SmoothBar extends StatelessWidget {
  const SmoothBar({
    super.key,
    required this.value,
    this.color = green,
    this.animate = true,
  });
  final double value;
  final Color color;
  final bool animate;
  Widget bar(double progress) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: LinearProgressIndicator(
      value: progress,
      minHeight: 7,
      color: color,
      backgroundColor: raised,
    ),
  );
  @override
  Widget build(BuildContext context) => animate
      ? TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (_, progress, _) => bar(progress),
        )
      : bar(value.clamp(0, 1));
}

class CategoryBadges extends StatelessWidget {
  const CategoryBadges(this.categories, {super.key});
  final List<Category> categories;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: categories
        .map(
          (c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              c.label.toUpperCase(),
              style: TextStyle(
                color: c.color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class CategoryFilters extends StatelessWidget {
  const CategoryFilters({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final Category? selected;
  final ValueChanged<Category?> onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [null, ...Category.values]
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c?.label ?? 'All'),
                selected: selected == c,
                onSelected: (_) => onSelect(c),
                selectedColor: (c?.color ?? green).withValues(alpha: .2),
                labelStyle: TextStyle(
                  color: selected == c ? c?.color ?? green : muted,
                ),
                showCheckmark: false,
              ),
            ),
          )
          .toList(),
    ),
  );
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
    this.featured = false,
  });
  final Quest quest;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: quest.isLocked ? .55 : 1,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Panel(
            color: quest.isActive || quest.isNew || featured
                ? quest.color
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: quest.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        quest.isLocked
                            ? Icons.lock_outline
                            : quest.categories.first.icon,
                        color: quest.color,
                      ),
                    ),
                    const Spacer(),
                    if (!featured)
                      Eyebrow(
                        quest.status,
                        color: quest.isNew || quest.isActive
                            ? quest.color
                            : muted,
                      )
                    else
                      const Icon(Icons.north_east_rounded, color: muted),
                  ],
                ),
                const SizedBox(height: 20),
                CategoryBadges(quest.categories),
                const SizedBox(height: 12),
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: featured ? 29 : 21,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  quest.description,
                  style: const TextStyle(
                    color: muted,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          quest.duration,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          quest.difficulty,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '+${quest.rewardXP} XP',
                      style: TextStyle(
                        color: quest.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      quest.verification.method.icon,
                      color: muted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        quest.verification.method.label,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (featured) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      child: Text(
                        quest.isCompleted && !quest.isActive
                            ? 'START SIDEQUEST'
                            : quest.isActive
                            ? 'CONTINUE SIDEQUEST'
                            : 'START SIDEQUEST',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.values, required this.labels});
  final List<String> values, labels;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      values.length,
      (i) => Expanded(
        child: Column(
          children: [
            Text(
              values[i],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[i],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
