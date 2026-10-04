import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/group.dart';
import 'common.dart';

class StartClubPanel extends StatelessWidget {
  const StartClubPanel({
    super.key,
    required this.state,
    required this.onCreated,
    this.compact = false,
  });
  final AppState state;
  final VoidCallback onCreated;
  final bool compact;
  @override
  Widget build(BuildContext context) => compact
      ? FilledButton.icon(
          style: state.hasGroup
              ? FilledButton.styleFrom(
                  backgroundColor: context.palette.surface,
                  foregroundColor: context.palette.green,
                  side: BorderSide(color: context.palette.raised),
                )
              : null,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('START A CLUB'),
          onPressed: () async {
            final created = await showModalBottomSheet<bool>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => _CreateClubSheet(state: state),
            );
            if (created == true && context.mounted) onCreated();
          },
        )
      : Panel(
          color: context.palette.green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start your own club',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Name your crew, invite friends, and take on a shared task list.',
                style: TextStyle(
                  color: context.palette.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('START A CLUB'),
                  onPressed: () async {
                    final created = await showModalBottomSheet<bool>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => _CreateClubSheet(state: state),
                    );
                    if (created == true && context.mounted) onCreated();
                  },
                ),
              ),
            ],
          ),
        );
}

class _CreateClubSheet extends StatefulWidget {
  const _CreateClubSheet({required this.state});
  final AppState state;
  @override
  State<_CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<_CreateClubSheet> {
  final name = TextEditingController();
  final slots = TextEditingController(text: '5');
  String? slotError;
  String? error;
  bool creating = false;
  ClubVisibility visibility = ClubVisibility.public;
  @override
  void dispose() {
    name.dispose();
    slots.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      final count = int.tryParse(slots.text);
      if (count == null || count < 2 || count > 100) {
        setState(() {
          creating = false;
          slotError = 'Choose 2–100 member slots.';
        });
        return;
      }
      await widget.state.createClubOnline(
        name.text,
        memberLimit: count,
        visibility: visibility,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        creating = false;
        error = e is FormatException
            ? e.message
            : 'Could not create club. Check your connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('YOUR CREW. YOUR ADVENTURE.', color: context.palette.green),
            const SizedBox(height: 16),
            const Text(
              'Start a Club',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => create(),
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
              decoration: InputDecoration(
                labelText: 'Club name',
                hintText: 'Weekend explorers',
                hintStyle: TextStyle(
                  color: context.palette.muted.withValues(alpha: .85),
                ),
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slots,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (_) {
                if (slotError != null) setState(() => slotError = null);
              },
              decoration: InputDecoration(
                labelText: 'Member slots',
                helperText: '2–100, including you',
                errorText: slotError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ClubVisibility>(
                segments: const [
                  ButtonSegment(
                    value: ClubVisibility.public,
                    icon: Icon(Icons.public),
                    label: Text('Public'),
                  ),
                  ButtonSegment(
                    value: ClubVisibility.private,
                    icon: Icon(Icons.lock_outline),
                    label: Text('Private'),
                  ),
                ],
                selected: {visibility},
                showSelectedIcon: false,
                onSelectionChanged: creating
                    ? null
                    : (v) => setState(() => visibility = v.first),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              visibility == ClubVisibility.public
                  ? 'Anyone can discover and join.'
                  : 'Join with an invite code or host approval.',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'Your club gets an invite code and three party tasks.',
              style: TextStyle(
                color: context.palette.muted,
                height: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.state.sharedClubs)
              Text(
                'Demo clubs · simulated members on this device.',
                style: TextStyle(
                  color: context.palette.muted,
                  height: 1.5,
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: creating ? null : create,
                child: Text(creating ? 'CREATING…' : 'CREATE CLUB'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
