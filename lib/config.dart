/// App-wide configuration.
///
/// Replace [googleMapsApiKey] with a key that has
/// "Maps SDK for Android" + "Directions API" enabled,
/// restricted to the app package (com.bings.app).
/// The same key must also be set in
/// android/app/src/main/AndroidManifest.xml
/// (com.google.android.geo.API_KEY).
class AppConfig {
  static const String googleMapsApiKey = 'YOUR_MAPS_API_KEY';

  // Default store location (Cebu City). Change to your store.
  static const double storeLat = 10.3157;
  static const double storeLng = 123.8854;
  static const String storeName = 'Bings Main Store';

  // Average rider speed used for ETA estimate (km/h).
  static const double riderSpeedKmh = 30.0;
}
