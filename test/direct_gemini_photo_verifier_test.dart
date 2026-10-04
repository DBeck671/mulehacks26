import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sidequest/services/direct_gemini_photo_verifier.dart';
import 'package:sidequest/services/photo_verifier.dart';

void main() {
  Future<PhotoReview> call(http.Client client) =>
      DirectGeminiPhotoVerifier(
        client: client,
        endpoint: Uri.parse('http://localhost:8084/api/photo-review'),
      ).review(
        title: 'Cook',
        description: 'Prepare a meal',
        evidencePrompt: 'Show your dish',
        image: Uint8List.fromList([1, 2, 3]),
      );

  test(
    'sends photo and task context only to backend; requires explicit match',
    () async {
      for (final verdict in ['match', 'mismatch', 'unclear']) {
        final result = await call(
          MockClient((request) async {
            expect(request.url.host, 'localhost');
            expect(request.headers.containsKey('x-goog-api-key'), isFalse);
            final data = jsonDecode(request.body);
            expect(data['title'], 'Cook');
            expect(base64Decode(data['image']), [1, 2, 3]);
            return http.Response(
              jsonEncode({
                'verdict': verdict,
                'reason': 'Show a prepared dish.',
              }),
              200,
            );
          }),
        );
        expect(result.matches, verdict == 'match');
      }
    },
  );
  test('configuration, quota, provider failure and malformed responses never approve', () async {
    for (final code in [400, 403, 413, 429, 503, 502]) {
      await expectLater(
        call(
          MockClient(
            (_) async => http.Response('sensitive provider detail', code),
          ),
        ),
        throwsA(isA<PhotoReviewException>()),
      );
    }
    for (final body in [
      'not json',
      '{"verdict":"match"}',
      '{"verdict":"yes","reason":"okay"}',
      '{"verdict":"match","reason":""}',
    ]) {
      await expectLater(
        call(MockClient((_) async => http.Response(body, 200))),
        throwsA(isA<PhotoReviewException>()),
      );
    }
    await expectLater(
      call(MockClient((_) async => throw http.ClientException('unreachable'))),
      throwsA(isA<PhotoReviewException>()),
    );
  });
}
