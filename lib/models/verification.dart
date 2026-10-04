import 'dart:typed_data';
import 'dart:math';

import 'location_check_in.dart';

import 'package:flutter/material.dart';

enum PhotoReviewStatus { unchecked, checking, approved, rejected, error }

enum VerificationMethod { photo, reflection, checklist, location }

extension VerificationStyle on VerificationMethod {
  String get label => switch (this) {
    VerificationMethod.location => 'GPS verification',
    VerificationMethod.photo => 'Photo evidence',
    VerificationMethod.reflection => 'Short reflection',
    VerificationMethod.checklist => 'Activity checklist',
  };
  IconData get icon => switch (this) {
    VerificationMethod.location => Icons.location_on_outlined,
    VerificationMethod.photo => Icons.add_a_photo_outlined,
    VerificationMethod.reflection => Icons.edit_note_rounded,
    VerificationMethod.checklist => Icons.fact_check_outlined,
  };
}

// Evidence belongs to its quest and survives navigation, but stays in memory.
class Verification {
  Verification({
    required this.method,
    required this.prompt,
    this.steps = const [],
    this.minimumDistance = 100,
    this.tracksRoute = false,
  });
  final double minimumDistance;
  final bool tracksRoute;
  double routeDistance = 0;
  bool routeTracking = false, routeFinished = false;
  LocationCheckIn? routeAnchor, lastRouteReading;
  String? routeSignalMessage;
  LocationCheckIn? startLocation, finishLocation;
  String? locationError;
  bool get locationFailed =>
      locationError != null ||
      (tracksRoute
          ? routeFinished && !locationVerified
          : finishLocation != null && !locationVerified);
  void resetLocations() {
    startLocation = null;
    finishLocation = null;
    locationError = null;
    routeDistance = 0;
    routeTracking = false;
    routeFinished = false;
    routeAnchor = null;
    lastRouteReading = null;
    routeSignalMessage = null;
  }

  void reset() {
    demoVerified = false;
    photo = null;
    photoReviewStatus = PhotoReviewStatus.unchecked;
    photoReviewMessage = null;
    photoRevision++;
    reflection = '';
    checkedSteps.clear();
    honorConfirmed = false;
    resetLocations();
  }

  double get displacement => startLocation == null || finishLocation == null
      ? 0
      : startLocation!.distanceTo(finishLocation!);
  // Subtract each reading's uncertainty so GPS jitter alone cannot pass.
  double get verifiedDistance => tracksRoute
      ? routeDistance
      : startLocation == null || finishLocation == null
      ? 0
      : max(
          0,
          displacement - startLocation!.accuracy - finishLocation!.accuracy,
        );
  bool get locationVerified =>
      locationError == null &&
      (!tracksRoute || routeFinished) &&
      startLocation != null &&
      finishLocation != null &&
      startLocation!.isUsable &&
      finishLocation!.isUsable &&
      finishLocation!.recordedAt.isAfter(startLocation!.recordedAt) &&
      verifiedDistance >= minimumDistance;

  // Conservative route length. Small noisy fixes keep the same anchor so
  // slow walking can accumulate; gaps and weak fixes never bridge distance.
  bool addRouteReading(LocationCheckIn reading) {
    if (!reading.isUsable || reading.accuracy > 25) {
      routeAnchor = null;
      lastRouteReading = null;
      routeSignalMessage = reading.isMocked
          ? 'Simulated GPS reading ignored.'
          : 'GPS is weak (${reading.accuracy.isFinite ? reading.accuracy.round() : 'unknown'} m accuracy). Move outdoors with precise location enabled.';
      return false;
    }
    final last = lastRouteReading;
    if (last != null && !reading.recordedAt.isAfter(last.recordedAt)) {
      return false;
    }
    final anchor = routeAnchor;
    if (anchor == null ||
        last == null ||
        reading.recordedAt.difference(last.recordedAt) >
            const Duration(seconds: 45)) {
      routeAnchor = reading;
      lastRouteReading = reading;
      routeSignalMessage = anchor == null
          ? null
          : 'GPS reconnected. Distance during the gap was not counted.';
      return true;
    }
    final elapsed =
        reading.recordedAt.difference(last.recordedAt).inMilliseconds / 1000;
    final distance = last.distanceTo(reading);
    if (distance > 8 * elapsed + last.accuracy + reading.accuracy) {
      routeSignalMessage = 'GPS jump ignored. Waiting for a reliable walking or running reading.';
      return false;
    }
    lastRouteReading = reading;
    final margin = anchor.accuracy + reading.accuracy;
    final segment = anchor.distanceTo(reading) - margin;
    if (segment >= 3) {
      routeDistance += segment;
      routeAnchor = reading;
    }
    routeSignalMessage = null;
    return true;
  }

  final VerificationMethod method;
  final String prompt;
  final List<String> steps;
  Uint8List? photo;
  PhotoReviewStatus photoReviewStatus = PhotoReviewStatus.unchecked;
  String? photoReviewMessage;
  int photoRevision = 0;
  String reflection = '';
  final Set<int> checkedSteps = {};
  bool honorConfirmed = false;
  bool demoVerified = false;
  bool get hasEvidence => switch (method) {
    VerificationMethod.location => locationVerified,
    VerificationMethod.photo =>
      photo != null &&
          photo!.isNotEmpty &&
          photoReviewStatus == PhotoReviewStatus.approved,
    VerificationMethod.reflection => reflection.trim().length >= 20,
    VerificationMethod.checklist =>
      steps.isNotEmpty &&
          List.generate(steps.length, (i) => i).every(checkedSteps.contains),
  };
  bool get isSatisfied =>
      demoVerified ||
      (method == VerificationMethod.location
          ? locationVerified
          : method == VerificationMethod.photo
          ? hasEvidence
          : honorConfirmed || hasEvidence);
  String get recordedMethod => demoVerified
      ? 'Demo simulation'
      : honorConfirmed && method != VerificationMethod.location
      ? 'Honor-based confirmation'
      : tracksRoute
      ? 'GPS route tracking'
      : method.label;
}
