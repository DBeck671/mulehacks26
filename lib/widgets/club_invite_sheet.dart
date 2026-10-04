import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/group.dart';
import 'common.dart';

class ClubInviteSheet extends StatelessWidget {
  const ClubInviteSheet({super.key, required this.club, this.shareInvite});
  final Group club;
  final Future<ShareResult> Function(ShareParams)? shareInvite;
  void unavailable(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sharing unavailable here. Copy the invite code instead.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Eyebrow('INVITE YOUR CREW', color: green),
            const SizedBox(height: 18),
            Text(
              club.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            const Eyebrow('Invite code'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    club.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy invite code',
                  icon: const Icon(Icons.copy_rounded, color: green),
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: club.inviteCode),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copy unavailable. Select the code to copy it manually.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter this invite code in the Join a group section.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Local demo: clubs and codes stay on this device. Online joining is not connected yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('SHARE INVITE'),
                onPressed: () async {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  try {
                    final result = await (shareInvite ?? SharePlus.instance.share)(
                      ShareParams(
                        text:
                            'Join my SideQuest club "${club.name}"! Invite code: ${club.inviteCode}. Enter it in Friends → Join a group. Local demo: online joining is not connected yet.',
                        title: 'Join ${club.name}',
                        mailToFallbackEnabled: false,
                        sharePositionOrigin: box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      ),
                    );
                    if (result.status == ShareResultStatus.unavailable &&
                        context.mounted) {
                      unavailable(context);
                    }
                  } catch (_) {
                    if (context.mounted) unavailable(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      ),
    ),
  );
}
