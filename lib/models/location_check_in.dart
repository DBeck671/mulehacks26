import 'dart:math';

class LocationCheckIn {
  const LocationCheckIn({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.isMocked = false,
  });
  final double latitude, longitude, accuracy;
  final DateTime recordedAt;
  final bool isMocked;
  bool get isUsable =>
      !isMocked &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      accuracy.isFinite &&
      accuracy >= 0 &&
      accuracy <= 50;
  double distanceTo(LocationCheckIn other) {
    double radians(double degrees) => degrees * pi / 180;
    final dLat = radians(other.latitude - latitude),
        dLon = radians(other.longitude - longitude);
    final a =
        pow(sin(dLat / 2), 2) +
        cos(radians(latitude)) *
            cos(radians(other.latitude)) *
            pow(sin(dLon / 2), 2);
    return 6371000 * 2 * asin(sqrt(a.clamp(0, 1)));
  }
}
