import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sidequest/app_state.dart';
import 'package:sidequest/models/location_check_in.dart';
import 'package:sidequest/services/location_service.dart';
import 'package:sidequest/screens/quest_detail_screen.dart';

class FakeLocations extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? next;
  int reads = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    reads++;
    return next!;
  }
}

LocationCheckIn point(double latitude, int seconds, {double accuracy = 5}) =>
    LocationCheckIn(
      latitude: latitude,
      longitude: 0,
      accuracy: accuracy,
      recordedAt: DateTime(2026, 10, 4).add(Duration(seconds: seconds)),
    );
Position position(double latitude) => Position(
  latitude: latitude,
  longitude: 0,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  test('location evidence requires a usable start, later finish, and real displacement', () {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(6);
    state.start(q);
    expect(state.saveLocation(q, point(.003, 2), start: false), isFalse);
    expect(
      state.saveLocation(q, point(0, 1, accuracy: 200), start: true),
      isFalse,
    );
    expect(state.saveLocation(q, point(0, 1), start: true), isTrue);
    expect(state.saveLocation(q, point(.003, 1), start: false), isFalse);
    state.saveLocation(q, point(.0004, 2), start: false);
    expect(q.verification.locationVerified, isFalse);
    state.confirmHonor(q, true);
    expect(q.verification.honorConfirmed, isFalse);
    expect(q.verification.locationFailed, isTrue);
    expect(state.complete(q), isNull);
    state.saveLocation(q, point(.001, 3, accuracy: 40), start: false);
    expect(q.verification.displacement, greaterThan(100));
    expect(q.verification.locationVerified, isFalse); // Noise margin matters.
    state.saveLocation(q, point(.003, 4), start: false);
    expect(q.verification.locationVerified, isTrue);
    expect(state.complete(q), isNotNull);
    expect(state.you.xp, 1225);
    expect(state.saveLocation(q, point(0, 5), start: true), isFalse);
  });
  test('reset clears evidence and location service handles denial without reading coordinates', () async {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(6);
    state.start(q);
    state.saveLocation(q, point(0, 1), start: true);
    state.saveLocation(q, point(.003, 2), start: false);
    state.resetLocation(q);
    expect(q.verification.locationVerified, isFalse);
    expect(q.verification.startLocation, isNull);
    final previous = GeolocatorPlatform.instance;
    final fake = FakeLocations();
    GeolocatorPlatform.instance = fake;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    fake.enabled = false;
    await expectLater(LocationService.checkIn(), throwsFormatException);
    fake.enabled = true;
    fake.permission = LocationPermission.deniedForever;
    await expectLater(LocationService.checkIn(), throwsFormatException);
    expect(fake.reads, 0);
  });
  test('repeating location quest rejects evidence from previous attempt', () {
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(6);
    state.start(q);
    final first = q.attemptNumber;
    state.saveLocation(q, point(0, 1), start: true);
    state.saveLocation(q, point(.003, 2), start: false);
    state.complete(q);
    state.start(q);
    expect(q.verification.startLocation, isNull);
    expect(q.verification.finishLocation, isNull);
    expect(
      state.saveLocation(q, point(.003, 3), start: true, attempt: first),
      isFalse,
    );
    state.failLocation(q, 'old error', attempt: first);
    expect(q.verification.locationError, isNull);
    expect(state.complete(q), isNull);
    state.saveLocation(q, point(0, 4), start: true);
    state.saveLocation(q, point(.003, 5), start: false);
    expect(state.complete(q), isNotNull);
    expect(q.completionCount, 2);
  });
  testWidgets('denied location check fails and offers a working retry', (
    tester,
  ) async {
    final previous = GeolocatorPlatform.instance;
    final fake = FakeLocations()..enabled = false;
    GeolocatorPlatform.instance = fake;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(6);
    state.start(q);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: QuestDetailScreen(state: state, quest: q),
      ),
    );
    await tester.ensureVisible(find.text('Save start location'));
    await tester.tap(find.text('Save start location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('LOCATION CHECK FAILED'), findsOneWidget);
    expect(q.verification.locationFailed, isTrue);
    fake.enabled = true;
    fake.next = position(0);
    await tester.ensureVisible(find.text('RETRY VERIFICATION'));
    await tester.tap(find.text('RETRY VERIFICATION'));
    await tester.pumpAndSettle();
    expect(q.verification.startLocation, isNotNull);
    expect(q.verification.locationFailed, isFalse);
    expect(find.text('Check finish location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('location buttons collect two points and enable completion', (
    tester,
  ) async {
    final previous = GeolocatorPlatform.instance;
    final fake = FakeLocations();
    GeolocatorPlatform.instance = fake;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    final state = AppState();
    addTearDown(state.dispose);
    final q = state.quest(6);
    state.start(q);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: QuestDetailScreen(state: state, quest: q),
      ),
    );
    expect(fake.reads, 0);
    fake.next = position(0);
    await tester.ensureVisible(find.text('Save start location'));
    await tester.tap(find.text('Save start location'));
    await tester.pumpAndSettle();
    expect(q.verification.startLocation, isNotNull);
    fake.next = position(.0004);
    await tester.ensureVisible(find.text('Check finish location'));
    await tester.tap(find.text('Check finish location'));
    await tester.pumpAndSettle();
    expect(q.verification.locationFailed, isTrue);
    expect(find.textContaining('DISTANCE NOT MET'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
          )
          .onPressed,
      isNull,
    );
    fake.next = position(.003);
    await tester.ensureVisible(find.text('RETRY VERIFICATION'));
    await tester.tap(find.text('RETRY VERIFICATION'));
    await tester.pumpAndSettle();
    expect(q.verification.locationVerified, isTrue);
    expect(fake.reads, 3);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'COMPLETE SIDEQUEST'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
