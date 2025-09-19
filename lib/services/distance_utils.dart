import 'dart:math' as math;

/// Provides distance calculations and geofence checks.
class DistanceUtils {
  /// Returns distance in meters between two coordinates using Haversine formula.
  static double distanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusMeters = 6371000; // mean Earth radius in meters

    final double dLat = _toRadians(endLat - startLat);
    final double dLng = _toRadians(endLng - startLng);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLat)) *
            math.cos(_toRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Returns true if within [radiusMeters] of the target coordinate.
  static bool isWithinRadius({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    double radiusMeters = 50,
  }) {
    final distance = distanceMeters(
      startLat: currentLat,
      startLng: currentLng,
      endLat: targetLat,
      endLng: targetLng,
    );
    return distance <= radiusMeters;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
