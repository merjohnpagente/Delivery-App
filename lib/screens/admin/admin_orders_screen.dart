import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order.dart';
import '../../services/firestore_service.dart';

const _statuses = [
  'pending',
  'preparing',
  'on the way',
  'delivered',
  'cancelled',
];

/// Admin: all orders, update status, set rider live location.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirestoreService().allOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No orders yet.',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, i) =>
              _adminOrderCard(context, orders[i]),
        );
      },
    );
  }

  Widget _adminOrderCard(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '\$${order.grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.address,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '${order.items.length} item(s) • ${order.paymentMethod}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statuses.contains(order.status.toLowerCase())
                      ? order.status.toLowerCase()
                      : 'pending',
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _statuses
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      FirestoreService()
                          .updateOrderStatus(order.id, value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showRiderDialog(context, order),
                  icon: const Icon(Icons.location_on, size: 18),
                  label: Text(
                    order.hasRiderLocation ? 'Update rider' : 'Set rider',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          if (order.hasRiderLocation)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Rider at ${order.riderLat!.toStringAsFixed(5)}, ${order.riderLng!.toStringAsFixed(5)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRiderDialog(BuildContext context, Order order) {
    final latController = TextEditingController(
      text: order.riderLat?.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: order.riderLng?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Rider location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g. 10.3157',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g. 123.8854',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter valid coordinates.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await FirestoreService()
                  .updateRiderLocation(order.id, lat, lng);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
