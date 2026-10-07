/// App-wide configuration.
///
/// Maps are 100% FREE: OpenStreetMap tiles + OSRM routing.
/// No API key, no billing, no account needed.
class AppConfig {
  /// Free OpenStreetMap tile server.
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Free OSRM demo routing server (driving routes, no key).
  static const String osrmHost = 'router.project-osrm.org';

  // Default store location (Cebu City). Change to your store.
  static const double storeLat = 10.3157;
  static const double storeLng = 123.8854;
  static const String storeName = 'Dodo Main Store';

  // Average rider speed used for ETA estimate (km/h).
  static const double riderSpeedKmh = 30.0;
}
