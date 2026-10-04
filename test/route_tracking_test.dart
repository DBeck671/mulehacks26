import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/location_check_in.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';

import 'location_tree_test.dart' show FakeLocations, position;

LocationCheckIn reading(
  double lat,
  int seconds, {
  double accuracy = 5,
  bool mocked = false,
}) => LocationCheckIn(
  latitude: lat,
  longitude: 0,
  accuracy: accuracy,
  recordedAt: DateTime(2026).add(Duration(seconds: seconds)),
  isMocked: mocked,
);

class StreamingLocations extends FakeLocations {
  final controller = StreamController<Position>.broadcast();
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      controller.stream;
}

Position streamPosition(double latitude, DateTime time) => Position(
  latitude: latitude,
  longitude: 0,
  timestamp: time,
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  test('walks around a loop count route length despite zero displacement', () {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(1);
    state.start(q);
    final attempt = q.attemptNumber;
    expect(state.beginRoute(q, reading(0, 0), attempt: attempt), isTrue);
    state.recordRoute(q, reading(.0006, 10), attempt: attempt);
    state.recordRoute(q, reading(0, 20), attempt: attempt);
    expect(q.verification.routeDistance, greaterThan(100));
    expect(state.complete(q), isNull); // Explicit finish is still required.
    state.finishRoute(q, reading(0, 21), attempt: attempt);
    expect(q.verification.displacement, 0);
    expect(q.verification.locationVerified, isTrue);
    expect(state.complete(q), isNotNull);
  });

  test('stationary jitter, jumps, weak GPS, mocked readings and gaps do not award distance', () {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(1);
    state.start(q);
    final attempt = q.attemptNumber;
    state.beginRoute(q, reading(0, 0), attempt: attempt);
    for (var i = 1; i < 20; i++) {
      state.recordRoute(
        q,
        reading(i.isEven ? .00002 : -.00002, i),
        attempt: attempt,
      );
    }
    expect(q.verification.routeDistance, 0);
    state.recordRoute(q, reading(.03, 20), attempt: attempt);
    expect(q.verification.routeDistance, 0);
    state.recordRoute(q, reading(.0006, 30, accuracy: 90), attempt: attempt);
    state.recordRoute(q, reading(.01, 40), attempt: attempt);
    expect(q.verification.routeDistance, 0);
    state.recordRoute(q, reading(.02, 100), attempt: attempt);
    expect(q.verification.routeDistance, 0);
    state.recordRoute(q, reading(.0206, 110, mocked: true), attempt: attempt);
    state.finishRoute(q, reading(.02, 111), attempt: attempt);
    expect(q.verification.locationFailed, isTrue);
    expect(state.complete(q), isNull);
  });

  test(
    'a short-distance failure can retry and retain verified movement only',
    () {
      final state = AppState();
      addTearDown(state.dispose);
      final q = state.quest(1);
      state.start(q);
      final attempt = q.attemptNumber;
      state.beginRoute(q, reading(0, 0), attempt: attempt);
      state.recordRoute(q, reading(.0006, 10), attempt: attempt);
      state.finishRoute(q, reading(.0006, 11), attempt: attempt);
      expect(q.verification.locationFailed, isTrue);
      final saved = q.verification.routeDistance;
      state.beginRoute(q, reading(.003, 60), attempt: attempt);
      expect(
        q.verification.routeDistance,
        saved,
      ); // The untracked gap is excluded.
      state.recordRoute(q, reading(.0036, 70), attempt: attempt);
      state.finishRoute(q, reading(.0036, 71), attempt: attempt);
      expect(state.complete(q), isNotNull);
      state.start(q);
      expect(q.verification.routeDistance, 0);
      expect(
        state.recordRoute(q, reading(.0042, 80), attempt: attempt),
        isFalse,
      );
    },
  );

  testWidgets(
    'GPS starts on demand, streams progress, retries failures and pauses on leaving',
    (tester) async {
      final old = GeolocatorPlatform.instance;
      final fake = StreamingLocations()..enabled = false;
      GeolocatorPlatform.instance = fake;
      addTearDown(() {
        GeolocatorPlatform.instance = old;
        fake.controller.close();
      });
      final state = AppState();
      addTearDown(state.dispose);
      final q = state.quest(1);
      state.start(q);
      await tester.pumpWidget(
        MaterialApp(
          home: QuestDetailScreen(state: state, quest: q),
        ),
      );
      expect(fake.reads, 0);
      await tester.ensureVisible(find.text('START GPS TRACKING'));
      await tester.tap(find.text('START GPS TRACKING'));
      await tester.pumpAndSettle();
      expect(find.text('RETRY VERIFICATION'), findsOneWidget);
      fake.enabled = true;
      fake.next = position(0);
      await tester.ensureVisible(find.text('RETRY VERIFICATION'));
      await tester.tap(find.text('RETRY VERIFICATION'));
      await tester.pumpAndSettle();
      expect(q.verification.routeTracking, isTrue);
      expect(fake.controller.hasListener, isTrue);
      final startTime = q.verification.lastRouteReading!.recordedAt;
      fake.controller.add(
        streamPosition(.0002, startTime.add(const Duration(seconds: 3))),
      );
      await tester.pumpAndSettle();
      expect(q.verification.routeDistance, inInclusiveRange(12, 13));
      expect(find.text('12 / 100 m verified route'), findsOneWidget);
      fake.next = streamPosition(
        .0002,
        startTime.add(const Duration(seconds: 4)),
      );
      await tester.ensureVisible(find.text('FINISH TRACKING'));
      await tester.tap(find.text('FINISH TRACKING'));
      await tester.pumpAndSettle();
      expect(q.verification.locationFailed, isTrue);
      expect(fake.controller.hasListener, isFalse);
      expect(find.textContaining('DISTANCE NOT MET'), findsOneWidget);
      await tester.ensureVisible(find.text('RETRY VERIFICATION'));
      await tester.tap(find.text('RETRY VERIFICATION'));
      await tester.pumpAndSettle();
      expect(fake.controller.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(q.verification.routeTracking, isFalse);
      expect(fake.controller.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
