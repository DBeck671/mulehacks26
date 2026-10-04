import 'dart:typed_data';

import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/quest.dart';
import 'package:sidequest/models/verification.dart';

/// An explicit approved AI result fixture, never a production bypass.
void verifyNonLocation(AppState state, Quest quest) {
  if (quest.verification.method == VerificationMethod.photo) {
    state.setPhoto(quest, Uint8List.fromList([1]));
    quest.verification.photoReviewStatus = PhotoReviewStatus.approved;
  } else {
    state.confirmHonor(quest, true);
  }
}
