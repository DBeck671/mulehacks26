import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';
import 'club_welcome.dart';

class JoinGroupPanel extends StatefulWidget {
  const JoinGroupPanel({super.key, required this.state, this.onJoined});
  final AppState state;
  final VoidCallback? onJoined;
  @override
  State<JoinGroupPanel> createState() => _JoinGroupPanelState();
}

class _JoinGroupPanelState extends State<JoinGroupPanel> {
  final code = TextEditingController();
  String? message;
  bool isError = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void join() {
    final result = widget.state.joinGroup(code.text);
    setState(() {
      isError =
          result == JoinGroupResult.invalidCode ||
          result == JoinGroupResult.unknownCode ||
          result == JoinGroupResult.full;
      message = switch (result) {
        JoinGroupResult.joined =>
          'Joined ${widget.state.group.name}! Your XP comes with you.',
        JoinGroupResult.alreadyActive =>
          'You are already in ${widget.state.group.name}.',
        JoinGroupResult.invalidCode => 'Enter a code like SQ-7319 or INV-7319.',
        JoinGroupResult.unknownCode =>
          'Code not found. Check it and try again.',
        JoinGroupResult.full =>
          'This club is full. Ask the host to add more member slots.',
      };
      if (result == JoinGroupResult.joined) code.clear();
    });
    if (result == JoinGroupResult.joined) {
      if (widget.onJoined != null) {
        widget.onJoined!();
      } else {
        showClubWelcome(context, widget.state.group.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.group_add_outlined, color: green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Join a group',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Got an invite? Enter an invite code or group code to find your crew.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: code,
          maxLength: 20,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => join(),
          onChanged: (_) {
            if (message != null) setState(() => message = null);
          },
          decoration: const InputDecoration(
            labelText: 'Invite code or group code',
            hintText: 'SQ-7319 or INV-7319',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: join, child: const Text('JOIN GROUP')),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              message!,
              style: TextStyle(
                color: isError ? const Color(0xFFFF6B8A) : green,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Local demo · Try SQ-7319 or INV-7319 for Curiosity Club.',
          style: TextStyle(color: muted, fontSize: 10, height: 1.5),
        ),
      ],
    ),
  );
}
