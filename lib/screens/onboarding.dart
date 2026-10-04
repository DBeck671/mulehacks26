import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../widgets/common.dart';
import 'main_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.route_rounded, color: green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Eyebrow(
                            'A little curiosity. A whole new path.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: JourneyArt(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SIDEQUEST',
                      style: TextStyle(
                        fontSize: 44,
                        letterSpacing: -2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Every experience\nleads somewhere.',
                      style: TextStyle(
                        fontSize: 32,
                        height: 1.12,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Turn everyday activities into adventures, discover unexpected connections, and level up along the way.',
                      style: TextStyle(color: muted, height: 1.7),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InterestsScreen(state: state),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('START EXPLORING'),
                            SizedBox(width: 14),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'More living. Less scrolling.',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class JourneyArt extends StatefulWidget {
  const JourneyArt({super.key});
  @override
  State<JourneyArt> createState() => _JourneyArtState();
}

class _JourneyArtState extends State<JourneyArt>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => CustomPaint(painter: _JourneyPainter(controller.value)),
  );
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * .5, size.height * .92),
      Offset(size.width * .5, size.height * .62),
      Offset(size.width * .22, size.height * .35),
      Offset(size.width * .77, size.height * .32),
      Offset(size.width * .38, size.height * .08),
      Offset(size.width * .88, size.height * .06),
    ];
    final colors = [
      green,
      green,
      Category.creativity.color,
      Category.exploration.color,
      Category.learning.color,
      Category.wellness.color,
    ];
    for (final edge in [
      [0, 1],
      [1, 2],
      [1, 3],
      [2, 4],
      [3, 5],
    ]) {
      final a = points[edge[0]], b = points[edge[1]];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, b.dy + 32, b.dx, a.dy - 32, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[edge[1]].withValues(alpha: .32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final metric = path.computeMetrics().first;
      final dot = metric.getTangentForOffset(
        metric.length * (.2 + phase * .6),
      )!;
      canvas.drawCircle(dot.position, 3, Paint()..color = colors[edge[1]]);
    }
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        23 + sin(phase * pi) * 3,
        Paint()..color = colors[i].withValues(alpha: .07),
      );
      canvas.drawCircle(points[i], 13, Paint()..color = background);
      canvas.drawCircle(
        points[i],
        13,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(points[i], 4, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  late final Set<Category> selected = {...widget.state.interests};
  late final TextEditingController name = TextEditingController(
    text: widget.state.profileName,
  );
  late String gender = widget.state.profileGender;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: PageBody(
        children: [
          const Eyebrow('YOUR ADVENTURE STARTS HERE', color: green),
          const SizedBox(height: 20),
          const PageHeading(
            'Make it yours.',
            "Choose at least 2 interests and we'll build your path.",
          ),
          TextField(
            controller: name,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.nickname],
            decoration: const InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'Your name or nickname',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: gender,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Gender (optional)'),
            items:
                const [
                      'Prefer not to say',
                      'Woman',
                      'Man',
                      'Non-binary',
                      'Another identity',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => gender = value ?? 'Prefer not to say'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gender is optional.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 26),
          const Text(
            'What do you like doing?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: Category.values
                .map(
                  (c) => GestureDetector(
                    onTap: () => setState(
                      () => selected.contains(c)
                          ? selected.remove(c)
                          : selected.add(c),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: selected.contains(c)
                            ? c.color.withValues(alpha: .09)
                            : surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected.contains(c) ? c.color : raised,
                          width: 1.5,
                        ),
                        boxShadow: selected.contains(c)
                            ? [
                                BoxShadow(
                                  color: c.color.withValues(alpha: .08),
                                  blurRadius: 20,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 30),
                              const Spacer(),
                              if (selected.contains(c))
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: c.color,
                                  size: 20,
                                ),
                            ],
                          ),
                          Text(
                            c.label,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 26),
          Text(
            '${selected.length} interests selected',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selected.length < 2 || name.text.trim().isEmpty
                  ? null
                  : () {
                      widget.state.setProfile(name.text, gender);
                      widget.state.buildPath(selected);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainScreen(state: widget.state),
                        ),
                        (_) => false,
                      );
                    },
              child: const Text('BUILD MY PATH'),
            ),
          ),
        ],
      ),
    ),
  );
}
