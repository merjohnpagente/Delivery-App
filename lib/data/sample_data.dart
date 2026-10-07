import '../models/category.dart';
import '../models/food_item.dart';

class SampleData {
  static const List<Category> categories = [
    Category(id: '1', name: 'Pizza', image: 'assets/images/pizza.png'),
    Category(id: '2', name: 'Burger', image: 'assets/images/burger.png'),
    Category(id: '3', name: 'Biryani', image: 'assets/images/biryani.png'),
    Category(id: '4', name: 'Drinks', image: 'assets/images/drink.png'),
    Category(id: '5', name: 'Salan', image: 'assets/images/salan.png'),
  ];

  static const List<FoodItem> foods = [
    FoodItem(
      id: '1',
      name: 'Cheese Pizza',
      description:
          'Loaded cheese pizza with mozzarella, fresh basil and our signature tomato sauce on a crispy golden crust.',
      price: 12.99,
      rating: 4.8,
      image: 'assets/images/pizza.png',
      category: 'Pizza',
      deliveryTime: '25-30 min',
    ),
    FoodItem(
      id: '2',
      name: 'Classic Burger',
      description:
          'Juicy grilled beef patty with cheddar, lettuce, tomato and house sauce in a toasted brioche bun.',
      price: 8.99,
      rating: 4.6,
      image: 'assets/images/burger.png',
      category: 'Burger',
      deliveryTime: '15-20 min',
    ),
    FoodItem(
      id: '3',
      name: 'Chicken Biryani',
      description:
          'Fragrant basmati rice layered with spiced chicken, saffron and fried onions. Served with raita.',
      price: 10.49,
      rating: 4.9,
      image: 'assets/images/biryani.png',
      category: 'Biryani',
      deliveryTime: '30-35 min',
    ),
    FoodItem(
      id: '4',
      name: 'Fresh Drink',
      description:
          'Chilled refreshing beverage made with fresh fruits. The perfect companion for any meal.',
      price: 3.99,
      rating: 4.5,
      image: 'assets/images/drink.png',
      category: 'Drinks',
      deliveryTime: '10-15 min',
    ),
    FoodItem(
      id: '5',
      name: 'Chicken Salan',
      description:
          'Traditional slow-cooked chicken curry with rich spices and gravy. Best enjoyed with rice or naan.',
      price: 9.99,
      rating: 4.7,
      image: 'assets/images/salan.png',
      category: 'Salan',
      deliveryTime: '25-30 min',
    ),
    FoodItem(
      id: '6',
      name: 'Deluxe Combo 1',
      description:
          'Our chef special combo meal with a mix of customer favorites. Great value for sharing.',
      price: 15.99,
      rating: 4.6,
      image: 'assets/images/Product 1.png',
      category: 'Pizza',
      deliveryTime: '20-25 min',
    ),
    FoodItem(
      id: '7',
      name: 'Deluxe Combo 2',
      description:
          'Premium combo platter with sides and a drink. Perfect for lunch or a hearty dinner.',
      price: 18.99,
      rating: 4.7,
      image: 'assets/images/Product 2.png',
      category: 'Burger',
      deliveryTime: '20-25 min',
    ),
    FoodItem(
      id: '8',
      name: 'Family Pack',
      description:
          'A generous family-sized pack with multiple mains and sides. Feeds 3-4 people easily.',
      price: 24.99,
      rating: 4.8,
      image: 'assets/images/Product 3.png',
      category: 'Biryani',
      deliveryTime: '35-40 min',
    ),
    FoodItem(
      id: '9',
      name: 'Party Platter',
      description:
          'The ultimate party platter loaded with bestsellers. Made for celebrations and gatherings.',
      price: 29.99,
      rating: 4.9,
      image: 'assets/images/Product 4.png',
      category: 'Pizza',
      deliveryTime: '40-45 min',
    ),
  ];

  static List<FoodItem> foodsByCategory(String category) {
    return foods.where((food) => food.category == category).toList();
  }
}
