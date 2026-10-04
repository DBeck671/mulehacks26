import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../models/location_check_in.dart';

// Foreground tracking starts only after an explicit user action.
class LocationService {
  static Future<LocationCheckIn> checkIn() async {
    try {
      // Browser getCurrentPosition prompts for permission itself. The web
      // requestPermission implementation makes an unbounded, low-accuracy
      // location request and converts every failure to deniedForever.
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const FormatException(
            'Turn on location services, then try again.',
          );
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw const PermissionDeniedException('Location access denied.');
        }
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      ).timeout(const Duration(seconds: 25));
      final reading = LocationCheckIn(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        recordedAt: position.timestamp,
        isMocked: position.isMocked,
      );
      if (reading.isMocked) {
        throw const FormatException(
          'Simulated location is not accepted. Use your device GPS and retry.',
        );
      }
      if (!reading.isUsable) {
        throw FormatException(
          'Location accuracy is ±${reading.accuracy.isFinite ? reading.accuracy.round() : 'unknown'} m. Try outdoors with precise location enabled; accuracy must be within 50 m.',
        );
      }
      if (DateTime.now().difference(reading.recordedAt).abs() >
          const Duration(seconds: 30)) {
        throw const FormatException(
          'That location reading is out of date. Try again.',
        );
      }
      return reading;
    } on PermissionDeniedException {
      throw const FormatException(
        'Location access is denied. Allow location for this app in device or browser settings, then retry.',
      );
    } on LocationServiceDisabledException {
      throw const FormatException('Turn on location services, then retry.');
    } on PositionUpdateException {
      throw const FormatException(
        'This device or browser could not provide a GPS fix. Try outdoors on a phone with precise location enabled. A phone-sized desktop preview does not supply phone GPS.',
      );
    } on TimeoutException {
      throw const FormatException(
        'Could not find your location in time. Try again outdoors.',
      );
    }
  }

  static Stream<LocationCheckIn> watch() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).map((p) {
        if (DateTime.now().difference(p.timestamp).abs() >
            const Duration(seconds: 30)) {
          throw const FormatException(
            'GPS readings are stale. Pause and retry outdoors.',
          );
        }
        return LocationCheckIn(
          latitude: p.latitude,
          longitude: p.longitude,
          accuracy: p.accuracy,
          recordedAt: p.timestamp,
          isMocked: p.isMocked,
        );
      });
}
