import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

/// Live tracking screen on FREE OpenStreetMap tiles (no API key):
/// rider marker (live), customer marker, store marker,
/// driving route via free OSRM, ETA and status timeline.
class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Order?>? _orderSub;
  Order? _order;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _orderSub = FirestoreService()
        .orderStream(widget.orderId)
        .listen(_onOrderUpdate);
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onOrderUpdate(Order? order) async {
    if (order == null || !mounted) return;
    final moved = _order == null ||
        _order!.riderLat != order.riderLat ||
        _order!.riderLng != order.riderLng;
    setState(() => _order = order);
    if (moved) {
      await _updateRoute(order);
      _moveCamera(order);
    }
  }

  Future<void> _updateRoute(Order order) async {
    if (!order.hasRiderLocation || !order.hasCustomerLocation) {
      if (mounted) setState(() => _routePoints = []);
      return;
    }
    final origin =
        LatLng(order.riderLat!, order.riderLng!);
    final dest =
        LatLng(order.customerLat!, order.customerLng!);
    List<LatLng> points = [origin, dest]; // straight-line fallback
    try {
      if (mounted) setState(() => _loadingRoute = true);
      final fetched = await _fetchRoute(origin, dest);
      if (fetched.isNotEmpty) points = fetched;
    } catch (_) {
      // Keep straight-line fallback.
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
    if (!mounted) return;
    setState(() => _routePoints = points);
  }

  /// Free OSRM routing (no key). Note OSRM uses lng,lat order.
  /// Returns empty list on any failure.
  Future<List<LatLng>> _fetchRoute(
      LatLng origin, LatLng dest) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${dest.longitude},${dest.latitude}',
      {'overview': 'full', 'geometries': 'polyline'},
    );
    final response =
        await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final json =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (json['code'] != 'Ok') return [];
    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) return [];
    final encoded = routes.first['geometry'];
    if (encoded is! String || encoded.isEmpty) return [];
    return _decodePolyline(encoded);
  }

  /// Decode a Google/OSRM encoded polyline into coordinates.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Center the camera on all known points with a zoom
  /// picked from the spread (no overflow, no plugin guessing).
  void _moveCamera(Order order) {
    if (!_mapReady) return;
    final points = <LatLng>[
      const LatLng(AppConfig.storeLat, AppConfig.storeLng),
      if (order.hasCustomerLocation)
        LatLng(order.customerLat!, order.customerLng!),
      if (order.hasRiderLocation)
        LatLng(order.riderLat!, order.riderLng!),
    ];
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    final center =
        LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final span = max(maxLat - minLat, maxLng - minLng);
    double zoom;
    if (span > 0.5) {
      zoom = 10;
    } else if (span > 0.2) {
      zoom = 12;
    } else if (span > 0.05) {
      zoom = 14;
    } else {
      zoom = 15.5;
    }
    _mapController.move(center, zoom);
  }

  /// ETA text: delivered/cancelled get a final message,
  /// otherwise haversine distance at average rider speed.
  String _etaText(Order order) {
    final status = order.status.toLowerCase();
    if (status == 'delivered' || status == 'completed') {
      return 'Delivered! Enjoy your meal 🎉';
    }
    if (status == 'cancelled') {
      return 'This order was cancelled.';
    }
    if (!order.hasRiderLocation || !order.hasCustomerLocation) {
      return 'Waiting for rider...';
    }
    const earthKm = 6371.0;
    final dLat = _rad(order.customerLat! - order.riderLat!);
    final dLng = _rad(order.customerLng! - order.riderLng!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(order.riderLat!)) *
            cos(_rad(order.customerLat!)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final distKm = 2 * earthKm * asin(sqrt(a));
    final mins =
        (distKm / AppConfig.riderSpeedKmh * 60).ceil();
    if (mins < 1) return 'Arriving now!';
    return '~$mins min away (${distKm.toStringAsFixed(1)} km)';
  }

  double _rad(double deg) => deg * pi / 180;

  List<Marker> _markers(Order order) {
    return [
      const Marker(
        point: LatLng(AppConfig.storeLat, AppConfig.storeLng),
        width: 40,
        height: 40,
        child: Icon(
          Icons.store,
          color: Colors.deepOrange,
          size: 32,
        ),
      ),
      if (order.hasCustomerLocation)
        Marker(
          point: LatLng(
              order.customerLat!, order.customerLng!),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 36,
          ),
        ),
      if (order.hasRiderLocation)
        Marker(
          point:
              LatLng(order.riderLat!, order.riderLng!),
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                    AppConfig.storeLat, AppConfig.storeLng),
                initialZoom: 14,
                onMapReady: () {
                  _mapReady = true;
                  if (order != null) _moveCamera(order);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: 'com.bings.app',
                ),
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.deepOrange,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (order != null)
                  MarkerLayer(markers: _markers(order)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            // Scrollable bottom sheet: short/landscape screens
            // never overflow.
            child: order == null
                ? const Center(
                    child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              color: Colors.deepOrange,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _loadingRoute
                                    ? 'Loading route...'
                                    : _etaText(order),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _statusTimeline(order.status),
                        if (!order.hasRiderLocation &&
                            order.status.toLowerCase() !=
                                'delivered' &&
                            order.status.toLowerCase() !=
                                'cancelled') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Rider location not yet available. The store will assign your rider soon.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Map © OpenStreetMap contributors',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        color = Colors.green;
        break;
      case 'preparing':
      case 'on the way':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusTimeline(String status) {
    const steps = ['pending', 'preparing', 'on the way', 'delivered'];
    final current =
        steps.indexOf(status.toLowerCase()).clamp(0, steps.length - 1);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < current;
          return Expanded(
            child: Container(
              height: 3,
              color: done
                  ? Colors.deepOrange
                  : Colors.grey.shade300,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx <= current;
        // Flexible + FittedBox so the 4 steps never overflow
        // narrow phones: labels shrink instead of striping yellow.
        return Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done
                      ? Colors.deepOrange
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  idx == 0
                      ? Icons.receipt
                      : idx == 1
                          ? Icons.restaurant
                          : idx == 2
                              ? Icons.delivery_dining
                              : Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  steps[idx],
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color:
                        done ? Colors.deepOrange : Colors.grey,
                    fontWeight: done
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
