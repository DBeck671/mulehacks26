import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/verification.dart';
import 'package:sidequest/services/photo_verifier.dart';
import 'package:sidequest/services/firebase_photo_verifier.dart';

class PendingPhotoVerifier implements PhotoVerifier {
  final requests = <Completer<PhotoReview>>[];
  String? title, prompt;
  @override
  Future<PhotoReview> review({
    required String title,
    required String description,
    required String evidencePrompt,
    required Uint8List image,
  }) {
    this.title = title;
    prompt = evidencePrompt;
    final result = Completer<PhotoReview>();
    requests.add(result);
    return result.future;
  }
}

void main() {
  test('only approved photos award XP; mismatch and outage fail closed, retry succeeds', () async {
    final verifier = PendingPhotoVerifier();
    final state = AppState(photoVerifier: verifier);
    addTearDown(state.dispose);
    final q = state.quest(5);
    state.start(q);
    state.setPhoto(q, Uint8List.fromList([1]));
    state.confirmHonor(q, true);
    expect(q.verification.honorConfirmed, isFalse);
    expect(state.complete(q), isNull);
    final request = state.reviewPhoto(q);
    await state.reviewPhoto(q); // Double tap never makes a second request.
    expect(verifier.requests.length, 1);
    expect(verifier.title, q.title);
    expect(verifier.prompt, q.verification.prompt);
    expect(q.verification.photoReviewStatus, PhotoReviewStatus.checking);
    expect(state.complete(q), isNull);
    verifier.requests.last.complete(
      const PhotoReview(matches: false, reason: 'Show a prepared dish.'),
    );
    await request;
    expect(q.verification.photoReviewStatus, PhotoReviewStatus.rejected);
    expect(q.verification.photoReviewMessage, contains('Choose a new photo'));
    expect(state.complete(q), isNull);
    expect(state.totalXP, 0);
    expect(state.completedActivities, isEmpty);
    state.setPhoto(q, Uint8List.fromList([2]));
    final failed = state.reviewPhoto(q);
    verifier.requests.last.completeError(
      const PhotoReviewException('Network unavailable.'),
    );
    await failed;
    expect(q.verification.photoReviewStatus, PhotoReviewStatus.error);
    expect(state.complete(q), isNull);
    final retry = state.reviewPhoto(q);
    verifier.requests.last.complete(
      const PhotoReview(matches: true, reason: 'A prepared dish is visible.'),
    );
    await retry;
    expect(q.verification.isSatisfied, isTrue);
    expect(state.complete(q), isNotNull);
    expect(state.totalXP, q.xp);
    expect(state.completedActivities.length, 1);
    state.start(q);
    expect(q.verification.photo, isNull);
    expect(q.verification.photoReviewStatus, PhotoReviewStatus.unchecked);
    expect(state.complete(q), isNull);
  });
  test(
    'late responses cannot approve replaced, removed or abandoned evidence',
    () async {
      final verifier = PendingPhotoVerifier();
      final state = AppState(photoVerifier: verifier);
      addTearDown(state.dispose);
      final q = state.quest(2);
      state.start(q);
      for (final action in ['replace', 'remove', 'abandon']) {
        state.setPhoto(q, Uint8List.fromList([1]));
        final request = state.reviewPhoto(q);
        if (action == 'replace') {
          state.setPhoto(q, Uint8List.fromList([2]));
        }
        if (action == 'remove') {
          state.setPhoto(q, null);
        }
        if (action == 'abandon') {
          state.stop(q);
          state.start(q);
        }
        verifier.requests.last.complete(
          const PhotoReview(matches: true, reason: 'Matches.'),
        );
        await request;
        expect(q.verification.photoReviewStatus, PhotoReviewStatus.unchecked);
        expect(state.complete(q), isNull);
      }
    },
  );
  test(
    'disposing account session while checking ignores the response',
    () async {
      final verifier = PendingPhotoVerifier();
      final state = AppState(photoVerifier: verifier);
      final q = state.quest(2);
      state.start(q);
      state.setPhoto(q, Uint8List.fromList([1]));
      final request = state.reviewPhoto(q);
      state.dispose();
      verifier.requests.last.complete(
        const PhotoReview(matches: true, reason: 'Matches.'),
      );
      await request;
      expect(q.verification.isSatisfied, isFalse);
    },
  );
  test(
    'parser requires a well-formed explicit match and rejects ambiguous output',
    () {
      expect(
        FirebasePhotoVerifier.parseResponse(
          '{"verdict":"match","reason":"A sketch is visible."}',
        ).matches,
        isTrue,
      );
      expect(
        FirebasePhotoVerifier.parseResponse(
          '{"verdict":"unclear","reason":"Use a sharper photo."}',
        ).matches,
        isFalse,
      );
      for (final text in [
        null,
        '',
        '{}',
        '{"verdict":"match"}',
        '{"verdict":"yes","reason":"Yes"}',
        '{"verdict":"match","reason":""}',
      ]) {
        expect(
          () => FirebasePhotoVerifier.parseResponse(text),
          throwsFormatException,
        );
      }
    },
  );
}
