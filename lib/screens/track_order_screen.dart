import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

/// Live tracking screen: shows the rider marker moving on the map,
/// the customer location, the route between them, and the order status.
class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<Order?>? _orderSub;
  Order? _order;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _loadingRoute = false;

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
    super.dispose();
  }

  Future<void> _onOrderUpdate(Order? order) async {
    if (order == null || !mounted) return;
    setState(() => _order = order);
    _updateMarkers(order);
    await _updateRoute(order);
    _fitCamera(order);
  }

  void _updateMarkers(Order order) {
    final markers = <Marker>{};
    // Store marker.
    markers.add(
      const Marker(
        markerId: MarkerId('store'),
        position: LatLng(AppConfig.storeLat, AppConfig.storeLng),
        infoWindow: InfoWindow(title: AppConfig.storeName),
      ),
    );
    // Customer marker.
    if (order.hasCustomerLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: LatLng(order.customerLat!, order.customerLng!),
          infoWindow: const InfoWindow(title: 'Delivery address'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ),
      );
    }
    // Rider marker (live).
    if (order.hasRiderLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(order.riderLat!, order.riderLng!),
          infoWindow: const InfoWindow(title: 'Your rider'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
        ),
      );
    }
    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  Future<void> _updateRoute(Order order) async {
    if (!order.hasRiderLocation || !order.hasCustomerLocation) {
      setState(() => _polylines.clear());
      return;
    }
    final origin = LatLng(order.riderLat!, order.riderLng!);
    final dest = LatLng(order.customerLat!, order.customerLng!);
    List<LatLng> points = [origin, dest]; // straight-line fallback
    if (AppConfig.googleMapsApiKey != 'YOUR_MAPS_API_KEY') {
      try {
        setState(() => _loadingRoute = true);
        final polylinePoints = PolylinePoints();
        final result =
            await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: AppConfig.googleMapsApiKey,
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(dest.latitude, dest.longitude),
        );
        if (result.points.isNotEmpty) {
          points = result.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
        }
      } catch (_) {
        // Keep straight-line fallback.
      } finally {
        if (mounted) setState(() => _loadingRoute = false);
      }
    }
    if (!mounted) return;
    setState(() {
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.deepOrange,
            width: 5,
          ),
        );
    });
  }

  Future<void> _fitCamera(Order order) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    final points = <LatLng>[
      const LatLng(AppConfig.storeLat, AppConfig.storeLng),
      if (order.hasCustomerLocation)
        LatLng(order.customerLat!, order.customerLng!),
      if (order.hasRiderLocation)
        LatLng(order.riderLat!, order.riderLng!),
    ];
    if (points.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
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
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  /// Rough ETA from rider to customer at average rider speed.
  String _etaText(Order order) {
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
    final mins = (distKm / AppConfig.riderSpeedKmh * 60).ceil();
    if (mins < 1) return 'Arriving now!';
    return '~$mins min away (${distKm.toStringAsFixed(1)} km)';
  }

  double _rad(double deg) => deg * pi / 180;

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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(AppConfig.storeLat, AppConfig.storeLng),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (order != null) _fitCamera(order);
              },
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
            child: order == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(
                            _loadingRoute
                                ? 'Loading route...'
                                : _etaText(order),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _statusTimeline(order.status),
                      if (!order.hasRiderLocation) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rider location not yet available. The store will assign your rider soon.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              color: done ? Colors.deepOrange : Colors.grey.shade300,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx <= current;
        return Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done ? Colors.deepOrange : Colors.grey.shade300,
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
            Text(
              steps[idx],
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: done ? Colors.deepOrange : Colors.grey,
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}
