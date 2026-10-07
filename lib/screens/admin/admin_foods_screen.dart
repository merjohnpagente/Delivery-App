import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/food_image.dart';

/// Admin: list, add, edit and delete food items.
class AdminFoodsScreen extends StatelessWidget {
  const AdminFoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foodProvider = context.watch<FoodProvider>();
    final foods = foodProvider.foods;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // While showing bundled sample data (Firestore menu empty
          // or unreachable), admin edits would target fake IDs, so
          // explain instead of failing silently.
          if (foodProvider.usingFallback)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outlined,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing sample menu. Add foods to the Firestore '
                      'collection to manage the live menu.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: foods.isEmpty
                ? Center(
                    child: Text(
                      'No foods yet.',
                      style:
                          GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: foods.length,
                    itemBuilder: (context, i) =>
                        _foodTile(context, foods[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showFoodDialog(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _foodTile(BuildContext context, FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          FoodImage(
            image: food.image,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${food.category} • \$${food.price.toStringAsFixed(2)} • ⭐ ${food.rating}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _showFoodDialog(context, food),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined, color: Colors.red),
            onPressed: () =>
                _confirmDelete(context, food),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FoodItem food) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete ${food.name}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteFood(food.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodDialog(BuildContext context, FoodItem? food) {
    final name = TextEditingController(text: food?.name ?? '');
    final desc =
        TextEditingController(text: food?.description ?? '');
    final price =
        TextEditingController(text: food?.price.toString() ?? '');
    final rating =
        TextEditingController(text: food?.rating.toString() ?? '4.5');
    final image =
        TextEditingController(text: food?.image ?? '');
    final category =
        TextEditingController(text: food?.category ?? '');
    final time =
        TextEditingController(text: food?.deliveryTime ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          food == null ? 'Add food' : 'Edit food',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'Name'),
              _field(desc, 'Description', maxLines: 2),
              _field(price, 'Price (e.g. 9.99)',
                  numeric: true),
              _field(rating, 'Rating (e.g. 4.5)',
                  numeric: true),
              _field(image,
                  'Image (asset path or URL)'),
              _field(category, 'Category'),
              _field(time, 'Delivery time (e.g. 20-25 min)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': name.text.trim(),
                'description': desc.text.trim(),
                'price':
                    double.tryParse(price.text.trim()) ?? 0.0,
                'rating':
                    double.tryParse(rating.text.trim()) ?? 4.5,
                'image': image.text.trim(),
                'category': category.text.trim(),
                'deliveryTime': time.text.trim(),
              };
              if ((data['name'] as String).isEmpty) return;
              if (food == null) {
                await FirestoreService().addFood(
                  FoodItem(
                    id: '',
                    name: data['name'] as String,
                    description: data['description'] as String,
                    price: data['price'] as double,
                    rating: data['rating'] as double,
                    image: data['image'] as String,
                    category: data['category'] as String,
                    deliveryTime: data['deliveryTime'] as String,
                  ),
                );
              } else {
                await FirestoreService()
                    .updateFood(food.id, data);
              }
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

  Widget _field(TextEditingController controller, String label,
      {bool numeric = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
