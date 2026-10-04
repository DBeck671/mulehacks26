import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'photo_verifier.dart';

/// Calls our backend. The Gemini credential never enters the Flutter client.
class DirectGeminiPhotoVerifier implements PhotoVerifier {
  const DirectGeminiPhotoVerifier({this.client, this.endpoint});
  final http.Client? client;
  final Uri? endpoint;

  Uri? get reviewEndpoint {
    if (endpoint != null) return endpoint;
    const configured = String.fromEnvironment('PHOTO_REVIEW_URL');
    if (configured.isNotEmpty) return Uri.parse(configured);
    if (kIsWeb && {'localhost', '127.0.0.1', '::1'}.contains(Uri.base.host)) {
      return Uri(
        scheme: 'http',
        host: '127.0.0.1',
        port: 8084,
        path: '/api/photo-review',
      );
    }
    return null;
  }

  @override
  Future<PhotoReview> review({
    required String title,
    required String description,
    required String evidencePrompt,
    required Uint8List image,
  }) async {
    final url = reviewEndpoint;
    if (url == null) {
      throw const PhotoReviewException(
        'Photo checking needs a server connection. Your photo has not been verified.',
      );
    }
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'description': description,
              'evidence': evidencePrompt,
              'image': base64Encode(image),
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        final message = switch (response.statusCode) {
          503 => 'Photo checking is not ready. The local server needs its Gemini API key.',
          429 => 'Photo checking has reached its usage limit. Try again later.',
          401 || 403 => 'The photo server’s Gemini API key needs attention.',
          400 || 413 =>
            'This photo could not be checked. Choose a smaller, clear image.',
          _ => 'Photo checking is temporarily unavailable. Please try again.',
        };
        throw PhotoReviewException(message);
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> ||
          !{'match', 'mismatch', 'unclear'}.contains(data['verdict']) ||
          data['reason'] is! String ||
          (data['reason'] as String).trim().isEmpty ||
          (data['reason'] as String).length > 240) {
        throw const PhotoReviewException(
          'The photo check returned no clear result. Please try again.',
        );
      }
      return PhotoReview(
        matches: data['verdict'] == 'match',
        reason: data['reason'],
      );
    } on http.ClientException {
      throw const PhotoReviewException(
        'Could not reach the photo server. Please try again when connected.',
      );
    } on FormatException {
      throw const PhotoReviewException(
        'The photo check returned no clear result. Please try again.',
      );
    } finally {
      if (client == null) transport.close();
    }
  }
}
