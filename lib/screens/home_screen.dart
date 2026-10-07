import 'package:flutter/material.dart' hide Category;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cart_provider.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/food_provider.dart';
import '../theme/responsive.dart';
import '../widgets/category_chip.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'food_detail_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (_navIndex == 1) return const OrdersScreen(showAppBar: true);
    if (_navIndex == 2) return const CartScreen(showAppBar: true);
    if (_navIndex == 3) return const ProfileScreen(showAppBar: true);

    final foodProvider = context.watch<FoodProvider>();
    final auth = context.watch<AuthProvider>();
    final userName = auth.profile?.name ??
        auth.firebaseUser?.displayName ??
        'Guest';

    final categoryNames = [
      'All',
      ...foodProvider.categories.map((c) => c.name)
    ];

    final filteredFoods =
        foodProvider.foodsByCategory(_selectedCategory).where((food) {
      return _searchQuery.isEmpty ||
          food.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final homeTab = Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: auth.profile?.photoUrl != null
                  ? Image.network(
                      auth.profile!.photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Welcome to Dodo food',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Responsive.centered(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.pagePadding(
                  MediaQuery.sizeOf(context).width),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const SizedBox(height: 8),
              Text(
                'What would you like\nto eat today?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categoryNames.map((name) {
                    final matches = foodProvider.categories
                        .where((c) => c.name == name);
                    final cat = matches.isNotEmpty
                        ? matches.first
                        : const Category(
                            id: '0',
                            name: 'All',
                            image: 'assets/images/cover-image.png',
                          );
                    return CategoryChip(
                      category: cat,
                      isSelected: _selectedCategory == name,
                      onTap: () =>
                          setState(() => _selectedCategory = name),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Foods',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${filteredFoods.length} items',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredFoods.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No food found.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = Responsive.columnsForWidth(
                        constraints.maxWidth);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio:
                            columns > 2 ? 0.78 : 0.72,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                  itemCount: filteredFoods.length,
                  itemBuilder: (context, index) {
                    final food = filteredFoods[index];
                    return FoodCard(
                      food: food,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FoodDetailScreen(food: food),
                          ),
                        );
                      },
                    );
                  },
                    );
                  },
                ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
    // IndexedStack keeps every tab alive (scroll position + state),
    // one shared nav bar, and back button returns to Home.
    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _navIndex != 0) {
          setState(() => _navIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: IndexedStack(
          index: _navIndex,
          children: [
            homeTab,
            const OrdersScreen(showAppBar: true),
            const CartScreen(showAppBar: true),
            const ProfileScreen(showAppBar: true),
          ],
        ),
        bottomNavigationBar: _bottomNav(),
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (index) => setState(() => _navIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.deepOrange,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              Consumer<CartProvider>(
                builder: (_, cart, __) => cart.itemCount > 0
                    ? Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Image.asset(
      'assets/images/avatar.jpg',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person),
    );
  }
}
