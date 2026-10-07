class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String image;
  final String category;
  final String deliveryTime;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.image,
    required this.category,
    required this.deliveryTime,
  });

  /// Build from a Firestore document.
  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    return FoodItem(
      id: id,
      name: map['name'] ?? 'Unnamed',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] ?? '',
      category: map['category'] ?? '',
      deliveryTime: map['deliveryTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'image': image,
      'category': category,
      'deliveryTime': deliveryTime,
    };
  }

  /// True when the image is a bundled asset (offline fallback),
  /// false when it is a network URL from Firestore/Storage.
  bool get isAssetImage => !image.startsWith('http');
}

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({required this.food, this.quantity = 1});

  double get totalPrice => food.price * quantity;
}
