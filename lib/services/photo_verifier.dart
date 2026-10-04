import 'dart:typed_data';

class PhotoReview {
  const PhotoReview({required this.matches, required this.reason});
  final bool matches;
  final String reason;
}

class PhotoReviewException implements Exception {
  const PhotoReviewException(this.message);
  final String message;
}

abstract interface class PhotoVerifier {
  Future<PhotoReview> review({
    required String title,
    required String description,
    required String evidencePrompt,
    required Uint8List image,
  });
}

class UnavailablePhotoVerifier implements PhotoVerifier {
  const UnavailablePhotoVerifier();
  @override
  Future<PhotoReview> review({
    required String title,
    required String description,
    required String evidencePrompt,
    required Uint8List image,
  }) async => throw const PhotoReviewException(
    'Photo checking is not connected yet. Your photo has not been verified.',
  );
}
