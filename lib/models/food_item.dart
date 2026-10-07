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
}

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({required this.food, this.quantity = 1});

  double get totalPrice => food.price * quantity;
}
