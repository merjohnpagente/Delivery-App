import 'package:geolocator/geolocator.dart';

/// Wraps geolocator: permissions + current position for delivery tracking.
class LocationService {
  /// Request permission; returns true when location access is granted.
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Current device position, or null when unavailable/denied.
  Future<Position?> currentPosition() async {
    try {
      final granted = await ensurePermission();
      if (!granted) return null;
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  /// Live position stream (used by future rider app / testing).
  Stream<Position> positionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
