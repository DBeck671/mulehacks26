import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';

class QuestCompleteScreen extends StatefulWidget {
  const QuestCompleteScreen({
    super.key,
    required this.state,
    required this.result,
  });
  final AppState state;
  final CompletionResult result;
  @override
  State<QuestCompleteScreen> createState() => _QuestCompleteScreenState();
}

class _QuestCompleteScreenState extends State<QuestCompleteScreen> {
  late final suggestions = widget.state.suggestedNextTasks(widget.result.quest);
  bool revealed = false;
  AppState get state => widget.state;
  CompletionResult get result => widget.result;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeOutCubic,
        onEnd: () {
          if (mounted) setState(() => revealed = true);
        },
        builder: (_, progress, _) {
          final gainedXP = (result.awardedXP * progress).round();
          final displayedXP = result.oldXP + gainedXP;
          return PageBody(
            children: [
              const Center(
                child: Icon(Icons.check_circle_rounded, color: green, size: 64),
              ),
              const SizedBox(height: 18),
              const Center(child: Eyebrow('SIDEQUEST COMPLETE', color: green)),
              const SizedBox(height: 14),
              Text(
                result.quest.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '+$gainedXP XP',
                  key: const ValueKey('xp-gain'),
                  style: TextStyle(
                    color: result.quest.color,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Added to your Activity Log',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              XPBar(
                totalXP: displayedXP,
                color: result.quest.color,
                animate: false,
              ),
              if (displayedXP ~/ 1000 > result.oldXP ~/ 1000) ...[
                const SizedBox(height: 12),
                Text(
                  'LEVEL UP · LEVEL ${displayedXP ~/ 1000 + 1}',
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: revealed
                    ? Column(
                        key: const ValueKey('suggested-tasks'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What will you do next?',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose a task to keep going, or head home and take a break.',
                            style: TextStyle(color: muted, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          ...suggestions.map(
                            (q) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                QuestCard(
                                  quest: q,
                                  onTap: () {
                                    if (state.start(q)) {
                                      Navigator.pop<Quest>(context, q);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        key: ValueKey('earning-xp'),
                        child: Text(
                          'Adding your XP…',
                          style: TextStyle(color: muted),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('RETURN TO HOME'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
