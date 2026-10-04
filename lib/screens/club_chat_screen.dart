import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/group.dart';
import '../widgets/common.dart';

class ClubChatScreen extends StatefulWidget {
  const ClubChatScreen({super.key, required this.state, required this.club});
  final AppState state;
  final Group club;
  @override
  State<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends State<ClubChatScreen> {
  final draft = TextEditingController();
  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  void send() {
    if (widget.state.sendClubMessage(widget.club.id, draft.text)) draft.clear();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (_, _) {
      final messages = widget.state.clubMessages(widget.club.id);
      final joined = widget.state.joinedGroupIds.contains(widget.club.id);
      return Scaffold(
        appBar: AppBar(title: Text(widget.club.name)),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.state.showcaseMode
                      ? 'Demo chat · bot replies'
                      : 'Local chat · on this device',
                  style: TextStyle(color: context.palette.muted, fontSize: 11),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'Say hello to your team.',
                          style: TextStyle(color: context.palette.muted),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (_, index) {
                          final message = messages[messages.length - 1 - index];
                          return Align(
                            alignment: message.isYou
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: message.isYou
                                    ? context.palette.green.withValues(
                                        alpha: .12,
                                      )
                                    : context.palette.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.isYou
                                        ? 'You'
                                        : '${message.sender}${message.isBot ? ' · bot' : ''}',
                                    style: TextStyle(
                                      color: context.palette.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    message.text,
                                    style: const TextStyle(height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: draft,
                        enabled: joined,
                        maxLength: 500,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        decoration: InputDecoration(
                          hintText: joined
                              ? 'Message your team…'
                              : 'You left this club',
                          hintStyle: TextStyle(
                            color: context.palette.muted.withValues(alpha: .6),
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: draft,
                      builder: (_, value, _) => IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: joined && value.text.trim().isNotEmpty
                            ? send
                            : null,
                        icon: const Icon(Icons.arrow_upward_rounded),
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
