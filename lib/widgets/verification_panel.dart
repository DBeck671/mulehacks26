import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../models/quest.dart';
import '../models/verification.dart';
import 'common.dart';
import 'location_verification.dart';

class VerificationPanel extends StatefulWidget {
  const VerificationPanel({
    super.key,
    required this.state,
    required this.quest,
  });
  final AppState state;
  final Quest quest;
  @override
  State<VerificationPanel> createState() => _VerificationPanelState();
}

class _VerificationPanelState extends State<VerificationPanel> {
  late final text = TextEditingController(
    text: widget.quest.verification.reflection,
  );
  bool picking = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> pickPhoto(ImageSource source) async {
    final attempt = widget.quest.attemptNumber;
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) return; // Cancellation leaves existing evidence intact.
      if (await file.length() > 10 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 10 MB.');
      }
      final bytes = await file.readAsBytes();
      // Browser file filters are hints: decode to reject non-image uploads.
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1400);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      if (mounted && attempt == widget.quest.attemptNumber) {
        widget.state.setPhoto(widget.quest, bytes);
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not open that photo. Check permissions or choose a JPG or PNG image.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest, v = q.verification;
    final editable = q.isActive;
    final cameraSupported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return Panel(
      color: q.color,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(v.method.icon, color: q.color, size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v.method.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (v.isSatisfied)
                  Icon(Icons.check_circle_outline, color: q.color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              v.prompt,
              style: const TextStyle(color: muted, fontSize: 13, height: 1.6),
            ),
            if (!editable && !q.isCompleted) ...[
              const SizedBox(height: 12),
              const Text(
                'Start this SideQuest to add your evidence.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
            if (v.method == VerificationMethod.location)
              LocationVerification(state: widget.state, quest: q),
            if (v.method == VerificationMethod.photo) ...[
              if (v.photo != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    v.photo!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Photo preview unavailable.'),
                  ),
                ),
              ],
              if (editable) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: picking
                          ? null
                          : () => pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        v.photo == null ? 'Choose photo' : 'Replace photo',
                      ),
                    ),
                    if (cameraSupported)
                      OutlinedButton.icon(
                        onPressed: picking
                            ? null
                            : () => pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Take photo'),
                      ),
                    if (v.photo != null)
                      TextButton(
                        onPressed: picking
                            ? null
                            : () => widget.state.setPhoto(q, null),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
                if (picking)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B8A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Photos stay on this device. Photo content is not automatically checked.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.5),
                ),
              ],
            ],
            if (v.method == VerificationMethod.reflection &&
                (editable || v.reflection.isNotEmpty)) ...[
              const SizedBox(height: 16),
              TextField(
                controller: text,
                readOnly: !editable,
                minLines: 3,
                maxLines: 5,
                maxLength: 600,
                onChanged: (value) => widget.state.setReflection(q, value),
                decoration: const InputDecoration(
                  hintText: 'A moment, an observation, a new idea…',
                  helperText: 'Write at least 20 characters.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
              ),
            ],
            if (v.method == VerificationMethod.checklist &&
                (editable || q.isCompleted)) ...[
              const SizedBox(height: 10),
              ...v.steps.asMap().entries.map(
                (step) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    step.value,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                  value: v.checkedSteps.contains(step.key),
                  onChanged: editable
                      ? (value) =>
                            widget.state.setStep(q, step.key, value ?? false)
                      : null,
                ),
              ),
            ],
            if (editable && v.method != VerificationMethod.location) ...[
              const SizedBox(height: 12),
              const Divider(color: raised),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: const Text(
                  'Use honor-based confirmation',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'I completed this activity and prefer not to add evidence.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                value: v.honorConfirmed,
                onChanged: (value) =>
                    widget.state.confirmHonor(q, value ?? false),
              ),
              const SizedBox(height: 8),
              Text(
                v.isSatisfied
                    ? 'Ready to complete and earn +${q.rewardXP} XP.'
                    : 'Add evidence or confirm on your honor to finish.',
                style: TextStyle(
                  fontSize: 11,
                  color: v.isSatisfied ? q.color : muted,
                ),
              ),
            ],
            if (q.isCompleted && !q.isActive) ...[
              const SizedBox(height: 14),
              Text(
                'Recorded with ${v.recordedMethod.toLowerCase()}.',
                style: TextStyle(color: q.color, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
