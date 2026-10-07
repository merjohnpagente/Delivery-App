import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../theme/responsive.dart';
import '../widgets/food_image.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _placingOrder = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'GCash',
    'Maya',
    'Credit/Debit Card',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _nameController.text = profile.name;
      if (profile.phone != null) _phoneController.text = profile.phone!;
      if (profile.address != null) {
        _addressController.text = profile.address!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    if (auth.firebaseUser == null || cart.items.isEmpty) return;

    setState(() => _placingOrder = true);
    try {
      // Capture customer GPS location for live delivery tracking.
      // Non-blocking: never delay the order more than ~2.5s for GPS.
      final position = await LocationService()
          .currentPosition()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          )
          .catchError((_) => null);
      final order = Order(
        id: '',
        userId: auth.firebaseUser!.uid,
        items: cart.items.map(OrderItem.fromCart).toList(),
        total: cart.totalPrice,
        address:
            '${_nameController.text.trim()}, ${_phoneController.text.trim()}, ${_addressController.text.trim()}',
        paymentMethod: _paymentMethod,
        createdAt: DateTime.now(),
        customerLat: position?.latitude,
        customerLng: position?.longitude,
      );
      await FirestoreService().placeOrder(order);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed! Thank you for ordering from Dodo food.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Responsive.centered(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Order Summary'),
              const SizedBox(height: 12),
              ...cart.items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      FoodImage(
                        image: item.food.image,
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.food.name}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Delivery Details'),
              const SizedBox(height: 12),
              _textField(
                _nameController,
                'Full name',
                Icons.person_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              _textField(
                _phoneController,
                'Phone number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your phone' : null,
              ),
              const SizedBox(height: 12),
              _textField(
                _addressController,
                'Delivery address',
                Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your address' : null,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Payment Method'),
              const SizedBox(height: 12),
              ..._paymentMethods.map(
                (method) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _paymentMethod == method
                          ? Colors.deepOrange
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: method,
                    groupValue: _paymentMethod,
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v!),
                    title: Text(
                      method,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    activeColor: Colors.deepOrange,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Subtotal',
                      '\$${cart.totalPrice.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow('Delivery Fee', '\$2.99'),
                    const Divider(height: 24),
                    _summaryRow(
                      'Total',
                      '\$${(cart.totalPrice + 2.99).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _placingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _placingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Place Order • \$${(cart.totalPrice + 2.99).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: isTotal ? Colors.deepOrange : Colors.black87,
          ),
        ),
      ],
    );
  }
}
