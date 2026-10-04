import 'dart:async';

import 'package:flutter/material.dart';

import 'common.dart';

/// A local, non-blocking welcome; it never requests notification permission.
void showClubWelcome(BuildContext context, String clubName) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  bool removed = false;
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _ClubWelcome(clubName: clubName, onDismissed: remove),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}

class _ClubWelcome extends StatefulWidget {
  const _ClubWelcome({required this.clubName, required this.onDismissed});
  final String clubName;
  final VoidCallback onDismissed;
  @override
  State<_ClubWelcome> createState() => _ClubWelcomeState();
}

class _ClubWelcomeState extends State<_ClubWelcome>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    reverseDuration: const Duration(milliseconds: 180),
  );
  Timer? timer;
  bool closing = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (timer != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.duration = Duration.zero;
      controller.reverseDuration = Duration.zero;
    }
    controller.forward();
    timer = Timer(const Duration(seconds: 4), dismiss);
  }

  Future<void> dismiss() async {
    if (closing) return;
    closing = true;
    timer?.cancel();
    await controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ease = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: ease,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -.35),
          end: Offset.zero,
        ).animate(ease),
        child: Semantics(
          liveRegion: true,
          label: 'Joined ${widget.clubName}',
          child: Material(
            color: surface,
            elevation: 16,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: green.withValues(alpha: .25)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "You're in!",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.clubName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss welcome',
                    onPressed: dismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: muted,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
