import 'package:flutter/material.dart';
import 'dart:math';

// --- DATA MODELS ---
// Represents a single menu item
class MenuItem {
  final String name;
  final String category;
  final double price;
  final bool isVeg;
  final String description;

  MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.isVeg,
    this.description = 'A delicious and popular Indian dish.',
  });
}

// Represents a category that contains a list of menu items
class MenuCategory {
  final String name;
  final List<MenuItem> items;

  MenuCategory({required this.name, required this.items});
}

// --- FAKE DATABASE / REPOSITORY ---
// This class simulates fetching data from a database.
// You can replace this with your actual Firebase/backend calls.
class MenuRepository {
  static final List<MenuCategory> _menu = [
    MenuCategory(name: 'Starters', items: [
      MenuItem(name: 'Samosa (Vegetable)', category: 'Starters', price: 150.00, isVeg: true),
      MenuItem(name: 'Paneer Tikka', category: 'Starters', price: 280.00, isVeg: true),
      MenuItem(name: 'Chicken 65', category: 'Starters', price: 320.00, isVeg: false),
      MenuItem(name: 'Tandoori Chicken', category: 'Starters', price: 450.00, isVeg: false),
      MenuItem(name: 'Gobi 65', category: 'Starters', price: 220.00, isVeg: true),
      MenuItem(name: 'Mutton Seekh Kebab', category: 'Starters', price: 380.00, isVeg: false),
    ]),
    MenuCategory(name: 'Main Course', items: [
      MenuItem(name: 'Paneer Butter Masala', category: 'Main Course', price: 350.00, isVeg: true),
      MenuItem(name: 'Dal Makhani', category: 'Main Course', price: 300.00, isVeg: true),
      MenuItem(name: 'Butter Chicken', category: 'Main Course', price: 420.00, isVeg: false),
      MenuItem(name: 'Rogan Josh (Mutton)', category: 'Main Course', price: 480.00, isVeg: false),
      MenuItem(name: 'Mixed Vegetable Curry', category: 'Main Course', price: 290.00, isVeg: true),
    ]),
    MenuCategory(name: 'Biryani', items: [
      MenuItem(name: 'Vegetable Biryani', category: 'Biryani', price: 320.00, isVeg: true),
      MenuItem(name: 'Chicken Dum Biryani', category: 'Biryani', price: 380.00, isVeg: false),
      MenuItem(name: 'Mutton Biryani', category: 'Biryani', price: 450.00, isVeg: false),
      MenuItem(name: 'Hyderabadi Paneer Biryani', category: 'Biryani', price: 340.00, isVeg: true),
    ]),
    MenuCategory(name: 'Breads', items: [
      MenuItem(name: 'Butter Naan', category: 'Breads', price: 60.00, isVeg: true),
      MenuItem(name: 'Tandoori Roti', category: 'Breads', price: 40.00, isVeg: true),
      MenuItem(name: 'Garlic Naan', category: 'Breads', price: 75.00, isVeg: true),
      MenuItem(name: 'Lachha Paratha', category: 'Breads', price: 65.00, isVeg: true),
    ]),
    MenuCategory(name: 'Desserts', items: [
      MenuItem(name: 'Gulab Jamun', category: 'Desserts', price: 120.00, isVeg: true),
      MenuItem(name: 'Rasmalai', category: 'Desserts', price: 150.00, isVeg: true),
      MenuItem(name: 'Gajar Ka Halwa', category: 'Desserts', price: 180.00, isVeg: true),
    ]),
    MenuCategory(name: 'Fitness Meals', items: [
      MenuItem(name: 'Grilled Paneer Salad', category: 'Fitness Meals', price: 280.00, isVeg: true, description: 'High-protein, low-carb salad.'),
      MenuItem(name: 'Grilled Chicken Salad', category: 'Fitness Meals', price: 320.00, isVeg: false, description: 'Lean protein with fresh greens.'),
      MenuItem(name: 'Quinoa Pulao', category: 'Fitness Meals', price: 250.00, isVeg: true, description: 'A healthy and fibrous alternative to rice.'),
    ]),
  ];

  // In a real app, this would be an async call to your backend
  Future<List<MenuCategory>> getMenu() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return _menu;
  }
}

// --- MAIN UI WIDGET ---
// This is the screen you will navigate to.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuRepository _menuRepository = MenuRepository();
  late Future<List<MenuCategory>> _menuFuture;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _menuFuture = _menuRepository.getMenu();
  }
  
  // This method is called after the future completes to set the initial category
  void _setInitialCategory(List<MenuCategory> categories) {
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = 'All'; // Add 'All' as the first category
    }
  }

  @override
  Widget build(BuildContext context) {
    // We get the passed category, but it's optional.
    // The main logic will be handled by the state of this widget.
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final passedCategory = args != null ? args['category'] as String? : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E6), // Light beige background
      appBar: AppBar(
        title: const Text('Our Menu'),
        backgroundColor: const Color(0xFFDAE952), // Your theme color
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<MenuCategory>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }

          final categories = snapshot.data!;
          // Set initial category if it's not set yet
          if (_selectedCategory == null) {
              _selectedCategory = passedCategory ?? 'All';
          }
          
          List<MenuItem> itemsToShow = [];
          if (_selectedCategory == 'All') {
              itemsToShow = categories.expand((cat) => cat.items).toList();
          } else {
              itemsToShow = categories.firstWhere((cat) => cat.name == _selectedCategory, orElse: () => categories.first).items;
          }

          return Column(
            children: [
              _buildCategorySelector(categories),
              Expanded(
                child: _buildMenuItemsGrid(itemsToShow),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(List<MenuCategory> categories) {
    List<String> categoryNames = ['All', ...categories.map((c) => c.name)];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: const Color(0xFFF7F5E6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: categoryNames.map((name) {
            final isSelected = _selectedCategory == name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = name;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFDAE952) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFDAE952) : Colors.grey.shade300,
                    width: 1.5
                  ),
                  boxShadow: isSelected ? [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.1),
                       blurRadius: 5,
                       offset: const Offset(0, 2)
                     )
                  ] : [],
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItemsGrid(List<MenuItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items in this category.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400.0, // Responsive item width
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 2.8, // Adjust for item height
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(items[index]);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 2)
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add item to cart logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                      )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xFFDAE952),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                  ),
                  child: const Text('ADD'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
