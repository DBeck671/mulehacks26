import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';

class FakePicker extends ImagePickerPlatform {
  XFile? next;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => next;
}

void main() {
  testWidgets(
    'repeat button starts fresh reflection with completion disabled',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      final q = state.quest(4);
      state.start(q);
      state.setReflection(
        q,
        'I learned something interesting about birds today.',
      );
      state.complete(q);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: QuestDetailScreen(state: state, quest: q),
        ),
      );
      await tester.ensureVisible(find.text('DO SIDEQUEST AGAIN'));
      await tester.tap(find.text('DO SIDEQUEST AGAIN'));
      await tester.pumpAndSettle();
      expect(q.isActive, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextField),
        'This is new evidence for my second learning activity.',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'photo picking previews valid evidence and handles cancellation, invalid files, and removal',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      final picker = FakePicker();
      ImagePickerPlatform.instance = picker;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final state = AppState();
      addTearDown(state.dispose);
      final q = state.quest(2);
      state.start(q);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: QuestDetailScreen(state: state, quest: q),
        ),
      );
      expect(q.verification.isSatisfied, isFalse);
      picker.next = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawRect(
          const ui.Rect.fromLTWH(0, 0, 10, 10),
          ui.Paint()..color = Colors.green,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(10, 10);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return XFile.fromData(data!.buffer.asUint8List(), name: 'evidence.png');
      });
      Future<void> pick(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.runAsync(() async {
          await tester.tap(find.text(label));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      await pick('Choose photo');
      expect(q.verification.photo, isNotNull);
      expect(find.byType(Image), findsOneWidget);
      final saved = q.verification.photo;
      picker.next = null;
      await pick('Replace photo');
      expect(q.verification.photo, same(saved));
      picker.next = XFile.fromData(
        utf8.encode('This is not an image.'),
        name: 'invalid.png',
      );
      await pick('Replace photo');
      expect(find.textContaining('Could not open that photo'), findsOneWidget);
      expect(q.verification.photo, same(saved));
      await tester.ensureVisible(find.text('Remove'));
      await tester.tap(find.text('Remove'));
      await tester.pump();
      expect(q.verification.isSatisfied, isFalse);
      expect(state.complete(q), isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reflection and checklist controls enable completion only when ready',
    (tester) async {
      final state = AppState();
      addTearDown(state.dispose);
      final learning = state.quest(4);
      state.start(learning);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: QuestDetailScreen(state: state, quest: learning),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Short');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextField),
        'I learned that migrating birds can navigate by the stars.',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNotNull,
      );
      final walk = state.quest(9);
      state.start(walk);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: QuestDetailScreen(
            key: const ValueKey('walk'),
            state: state,
            quest: walk,
          ),
        ),
      );
      for (final step in walk.verification.steps) {
        await tester.ensureVisible(find.text(step));
        await tester.tap(find.text(step));
        await tester.pump();
      }
      expect(walk.verification.isSatisfied, isTrue);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
