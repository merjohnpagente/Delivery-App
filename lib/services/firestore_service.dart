import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/food_item.dart';
import '../models/order.dart';

/// Reads menu data and writes orders in Firestore.
///
/// Collections:
///   categories/{id} -> { name, image }
///   foods/{id}      -> { name, description, price, rating, image,
///                        category, deliveryTime }
///   orders/{id}     -> { userId, items, total, status, address,
///                        paymentMethod, createdAt }
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
  Stream<List<Order>> userOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList());
  }
}
