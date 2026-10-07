import 'package:flutter/foundation.dart';
import '../models/food_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem(FoodItem food) {
    final index = _items.indexWhere((item) => item.food.id == food.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(food: food));
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    _items.removeWhere((item) => item.food.id == foodId);
    notifyListeners();
  }

  void incrementQuantity(String foodId) {
    final index = _items.indexWhere((item) => item.food.id == foodId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String foodId) {
    final index = _items.indexWhere((item) => item.food.id == foodId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
