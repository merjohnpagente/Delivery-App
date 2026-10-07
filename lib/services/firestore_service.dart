import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/category.dart';
import '../models/food_item.dart';
import '../models/order.dart';

/// Reads menu data and writes orders in Firestore.
///
/// Collections:
///   categories/{id} -> { name, image }
///   foods/{id}      -> { name, description, price, rating, image,
///                        category, deliveryTime }
///   orders/{id}     -> { userId, items, total, deliveryFee, status,
///                        address, paymentMethod, createdAt,
///                        riderLat?, riderLng?, customerLat?, customerLng? }
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live list of categories, ordered by name.
  Stream<List<Category>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Category(
                  id: doc.id,
                  name: doc.data()['name'] ?? 'Unnamed',
                  image: doc.data()['image'] ?? '',
                ))
            .toList());
  }

  /// Live list of all foods.
  Stream<List<FoodItem>> foodsStream() {
    return _db.collection('foods').snapshots().map(_foodsFromSnapshot);
  }

  /// Live list of foods in one category.
  Stream<List<FoodItem>> foodsByCategoryStream(String category) {
    return _db
        .collection('foods')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(_foodsFromSnapshot);
  }

  List<FoodItem> _foodsFromSnapshot(QuerySnapshot snap) {
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FoodItem(
        id: doc.id,
        name: data['name'] ?? 'Unnamed',
        description: data['description'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        image: data['image'] ?? '',
        category: data['category'] ?? '',
        deliveryTime: data['deliveryTime'] ?? '',
      );
    }).toList();
  }

  /// Place an order. Returns the new order document id.
  Future<String> placeOrder(Order order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  /// Live list of one user's orders, newest first.
  ///
  /// Sorted client-side on purpose: a server-side orderBy would
  /// require a Firestore composite index, and orders would fail
  /// to load ("Failed to load orders") until the index exists.
  Stream<List<Order>> userOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final orders = snap.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Live stream of a single order (for the tracking screen).
  Stream<Order?> orderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? Order.fromMap(doc.id, doc.data()!) : null);
  }

  /// Live list of ALL orders, newest first (admin only).
  Stream<List<Order>> allOrdersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Admin: update order status.
  Future<void> updateOrderStatus(String orderId, String status) {
    return _db.collection('orders').doc(orderId).update({'status': status});
  }

  /// Admin: update rider live location on an order.
  Future<void> updateRiderLocation(
      String orderId, double lat, double lng) {
    return _db.collection('orders').doc(orderId).update({
      'riderLat': lat,
      'riderLng': lng,
    });
  }

  // ---------- Admin: foods ----------

  /// Admin: add a food item. Returns the new document id.
  Future<String> addFood(FoodItem food) async {
    final ref = await _db.collection('foods').add(food.toMap());
    return ref.id;
  }

  /// Admin: update a food item.
  Future<void> updateFood(String foodId, Map<String, dynamic> data) {
    return _db.collection('foods').doc(foodId).update(data);
  }

  /// Admin: delete a food item.
  Future<void> deleteFood(String foodId) {
    return _db.collection('foods').doc(foodId).delete();
  }

  // ---------- Admin: categories ----------

  /// Admin: add a category. Returns the new document id.
  Future<String> addCategory(String name, String image) async {
    final ref = await _db
        .collection('categories')
        .add({'name': name, 'image': image});
    return ref.id;
  }

  /// Admin: delete a category.
  Future<void> deleteCategory(String categoryId) {
    return _db.collection('categories').doc(categoryId).delete();
  }
}
