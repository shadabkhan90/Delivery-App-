import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Handles location permissions and periodic location updates.
class LocationService {
  static const Duration defaultUpdateInterval = Duration(seconds: 10);

  final Duration updateInterval;
  StreamSubscription<Position>? _subscription;

  LocationService({Duration? updateInterval})
    : updateInterval = updateInterval ?? defaultUpdateInterval;

  /// Ensures location services are enabled and permissions are granted.
  /// Returns true if ready to access location.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Returns the current position once.
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  /// Subscribes to position updates every [updateInterval].
  Stream<Position> getPositionStream() {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      timeLimit: null,
    );
    // Geolocator throttles by distanceFilter; we'll manually throttle via timer in UI if needed.
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Starts logging updates to console every [updateInterval].
  void startConsoleLogging() {
    _subscription?.cancel();
    _subscription = getPositionStream().listen((position) {
      final now = DateTime.now().toIso8601String();
      // Simulate sending to server
      // ignore: avoid_print
      print(
        '[LocationUpdate $now] lat=${position.latitude}, lng=${position.longitude}, acc=${position.accuracy}m',
      );
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
