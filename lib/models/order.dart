import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

/// A placed food order stored in the `orders` collection.
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final double deliveryFee;
  final String status;
  final String address;
  final String paymentMethod;
  final DateTime createdAt;
  // Live delivery tracking (set by admin; customer location saved at checkout).
  final double? riderLat;
  final double? riderLng;
  final double? customerLat;
  final double? customerLng;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    this.deliveryFee = 2.99,
    this.status = 'pending',
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    this.riderLat,
    this.riderLng,
    this.customerLat,
    this.customerLng,
  });

  double get grandTotal => total + deliveryFee;

  bool get hasRiderLocation => riderLat != null && riderLng != null;
  bool get hasCustomerLocation =>
      customerLat != null && customerLng != null;

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final createdAt = map['createdAt'];
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 2.99,
      status: map['status'] ?? 'pending',
      address: map['address'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse('$createdAt') ?? DateTime.now(),
      riderLat: (map['riderLat'] as num?)?.toDouble(),
      riderLng: (map['riderLng'] as num?)?.toDouble(),
      customerLat: (map['customerLat'] as num?)?.toDouble(),
      customerLng: (map['customerLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'deliveryFee': deliveryFee,
      'status': status,
      'address': address,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      if (riderLat != null) 'riderLat': riderLat,
      if (riderLng != null) 'riderLng': riderLng,
      if (customerLat != null) 'customerLat': customerLat,
      if (customerLng != null) 'customerLng': customerLng,
    };
  }
}

class OrderItem {
  final String foodId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const OrderItem({
    required this.foodId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromCart(CartItem cartItem) {
    return OrderItem(
      foodId: cartItem.food.id,
      name: cartItem.food.name,
      image: cartItem.food.image,
      price: cartItem.food.price,
      quantity: cartItem.quantity,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodId: map['foodId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;
}
