import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/quest.dart';
import 'package:sidequest/models/location_check_in.dart';

void verifyGPS(AppState state, Quest q) {
  final now = DateTime.now();
  LocationCheckIn at(double latitude, int seconds) => LocationCheckIn(
    latitude: latitude,
    longitude: 0,
    accuracy: 5,
    recordedAt: now.add(Duration(seconds: seconds)),
  );
  if (q.verification.tracksRoute) {
    state.beginRoute(q, at(0, 0), attempt: q.attemptNumber);
    for (var i = 1; i <= 3; i++) {
      state.recordRoute(q, at(.0011 * i, 30 * i), attempt: q.attemptNumber);
    }
    state.finishRoute(q, at(.0033, 91), attempt: q.attemptNumber);
  } else {
    state.saveLocation(q, at(0, 0), start: true);
    state.saveLocation(q, at(.01, 1), start: false);
  }
}
