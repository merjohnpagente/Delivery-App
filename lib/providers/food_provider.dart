import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../data/sample_data.dart';
import '../models/category.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';

/// Loads menu data from Firestore, falling back to bundled
/// [SampleData] when Firestore is unreachable (e.g. empty DB).
class FoodProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Category> _categories = [];
  List<FoodItem> _foods = [];
  bool _usingFallback = true;
  StreamSubscription? _catSub;
  StreamSubscription? _foodSub;

  List<Category> get categories => _categories;
  List<FoodItem> get foods => _foods;

  /// True while showing bundled sample data instead of Firestore data.
  bool get usingFallback => _usingFallback;

  FoodProvider() {
    // Show something immediately, then replace with live data.
    _categories = SampleData.categories;
    _foods = SampleData.foods;
    _listen();
  }

  void _listen() {
    _catSub = _service.categoriesStream().listen((cats) {
      if (cats.isNotEmpty) {
        _categories = cats;
        _checkFallback();
        notifyListeners();
      }
    }, onError: (_) {});
    _foodSub = _service.foodsStream().listen((foods) {
      if (foods.isNotEmpty) {
        _foods = foods;
        _checkFallback();
        notifyListeners();
      }
    }, onError: (_) {});
  }

  void _checkFallback() {
    // Fallback ends once Firestore returns real foods.
    if (_foods.isNotEmpty && _foods != SampleData.foods) {
      _usingFallback = false;
    }
  }

  List<FoodItem> foodsByCategory(String category) {
    if (category == 'All') return _foods;
    return _foods.where((f) => f.category == category).toList();
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _foodSub?.cancel();
    super.dispose();
  }
}
