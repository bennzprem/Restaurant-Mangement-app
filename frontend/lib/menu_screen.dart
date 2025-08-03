// lib/menu_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart';
import 'models.dart';
import 'theme.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'auth_provider.dart';

class MenuScreen extends StatefulWidget {
  // Add this property
  final String? tableSessionId;

  const MenuScreen({super.key, this.tableSessionId}); // Update constructor
  //const MenuScreen({super.key});
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<List<MenuCategory>>? _menuFuture;
  int _selectedCategoryIndex = 0;
  bool _isVegOnly = false;
  bool _isVegan = false; // <-- ADD THIS
  bool _isGlutenFree = false; // <-- ADD THIS
  bool _isNutsFree = false; // <-- ADD THIS
  String _searchQuery = '';
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  // In class _MenuScreenState...
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();

  /*final Map<String, String> categoryIcons = {
    'Together Combos': '🤝',
    'Comfort Meals': '🍲',
    'All-in-1-Meals': '🍱',
    'Mini Meals': '🍛',
    'Desi Box': '🥡',
    'Dum Biryani Thali': '🥘',
    'Main Course': '🍽️',
  };*/
  // In class _MenuScreenState...

  final Map<String, String> categoryIcons = {
    'Appetizers': '🍽️',
    'Soups & Salads': '🥗',
    'Pizzas (11-inch)': '🍕',
    'Pasta': '🍝',
    'Sandwiches & Wraps': '🥪',
    'Main Course - Indian': '🥘',
    'Main Course - Global': '🌍',
    'Desserts': '🍰',
    'Beverages': '🥤',
    // You can add more mappings here if needed
  };

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _loadMenu();
      }
    });
  }

  void _loadMenu() {
    setState(() {
      _menuFuture = _apiService.fetchMenu(
        vegOnly: _isVegOnly,
        veganOnly: _isVegan, // <-- ADD THIS
        glutenFreeOnly: _isGlutenFree, // <-- ADD THIS
        nutsFree: _isNutsFree, // <-- ADD THIS
        searchQuery: _searchQuery,
      );
      _selectedCategoryIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the layout mode at the top level of the build method.
    const double wideLayoutThreshold = 800;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > wideLayoutThreshold;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,

      // The AppBar's logic remains the same and uses the 'isWide' variable.
      appBar: AppBar(
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
        leading: !isWide
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Show Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: isWide ? const Text('Our Menu') : null,
        actions: [
          SizedBox(
            width: 250,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'More Filters',
            onPressed: () => _showFilterDialog(context),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Favorites',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(
                cart.items.values
                    .fold(0, (sum, item) => sum + item.quantity)
                    .toString(),
              ),
              isLabelVisible: cart.items.isNotEmpty,
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        CartScreen(tableSessionId: widget.tableSessionId)),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // The drawer for narrow screens now gets its content from the FutureBuilder.
      drawer: !isWide
          ? FutureBuilder<List<MenuCategory>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const SizedBox.shrink(); // Return empty if no data
                final menuCategories = snapshot.data!;
                return Container(
                  width: 280,
                  color: AppTheme.primaryLight,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 40,
                    ), // Extra padding for status bar
                    itemCount: menuCategories.length,
                    itemBuilder: (context, index) {
                      final category = menuCategories[index];
                      return CategoryListItem(
                        icon: categoryIcons[category.name] ?? '🍴',
                        title: category.name,
                        itemCount: category.items.length,
                        isSelected: index == _selectedCategoryIndex,
                        isExpanded: true,
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                          Navigator.of(context).pop(); // Close drawer
                        },
                      );
                    },
                  ),
                );
              },
            )
          : null,

      // The body contains the main content.
      body: FutureBuilder<List<MenuCategory>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No menu items found for your filter.'),
            );
          }

          final menuCategories = snapshot.data!;
          if (_selectedCategoryIndex >= menuCategories.length) {
            _selectedCategoryIndex = 0;
          }
          final selectedCategory = menuCategories[_selectedCategoryIndex];

          return Row(
            children: [
              // The side panel is only shown on wide screens.
              if (isWide)
                Container(
                  width: 280,
                  color: AppTheme.primaryLight,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 24),
                    itemCount: menuCategories.length,
                    itemBuilder: (context, index) {
                      final category = menuCategories[index];
                      return CategoryListItem(
                        icon: categoryIcons[category.name] ?? '🍴',
                        title: category.name,
                        itemCount: category.items.length,
                        isSelected: index == _selectedCategoryIndex,
                        isExpanded: true,
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                        },
                      );
                    },
                  ),
                ),
              if (isWide)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),

              // The menu item grid takes the remaining space.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        selectedCategory.name,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double cardWidth = 320;
                          final int crossAxisCount =
                              (constraints.maxWidth / cardWidth).floor().clamp(
                                    1,
                                    4,
                                  );

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              mainAxisExtent: 340,
                            ),
                            itemCount: selectedCategory.items.length,
                            itemBuilder: (context, index) {
                              return MenuItemCard(
                                item: selectedCategory.items[index],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  // In class _MenuScreenState...

  // In class _MenuScreenState...

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // Use a StatefulWidget to manage the state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dietary Filters'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ADDED THE VEGETARIAN OPTION HERE
                  SwitchListTile(
                    title: const Text('Vegetarian'),
                    value: _isVegOnly,
                    onChanged: (value) {
                      setDialogState(() {
                        _isVegOnly = value;
                      });
                    },
                  ),
                  // The other filters remain below
                  SwitchListTile(
                    title: const Text('Vegan'),
                    value: _isVegan,
                    onChanged: (value) {
                      setDialogState(() {
                        _isVegan = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Gluten-Free'),
                    value: _isGlutenFree,
                    onChanged: (value) {
                      setDialogState(() {
                        _isGlutenFree = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Nuts-Free'),
                    value: _isNutsFree,
                    onChanged: (value) {
                      setDialogState(() {
                        _isNutsFree = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply the filters and reload the menu
                    _loadMenu();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CategoryListItem extends StatelessWidget {
  final String icon;
  final String title;
  final int itemCount;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.itemCount,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The main container and gesture detector stay the same.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal:
              isExpanded ? 20 : 8, // Less horizontal padding when narrow
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.accentColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        // The child now changes based on the 'isExpanded' flag
        child: isExpanded ? _buildWideLayout(context) : _buildNarrowLayout(),
      ),
    );
  }

  // This is the icon-only layout for narrow screens.
  Widget _buildNarrowLayout() {
    return Tooltip(
      message: title, // Show the full name on hover
      waitDuration: const Duration(milliseconds: 300),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
    );
  }

  // This is your original layout, now extracted into a method.
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          itemCount.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// THIS IS THE FULLY CORRECTED WIDGET THAT FIXES THE CRASH
class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  /*@override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  item.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorited = favoritesProvider.isFavorite(item.id);
                    return CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => favoritesProvider.toggleFavorite(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // THE BUG WAS HERE: An 'Expanded' widget was wrongfully placed here.
          // It has now been removed.
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹ ${item.price.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 18),
                    ),
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        final quantity = cart.getItemQuantity(item.id);
                        return quantity == 0
                            ? ElevatedButton(
                                onPressed: () => cart.addItem(item),
                                child: const Text('ADD +'),
                              )
                            : QuantityCounter(item: item);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }*/
  // In class MenuItemCard...

  // In class MenuItemCard...

  /*@override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize
            .min, // <-- This allows the card to shrink to fit its content
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  item.imageUrl,
                  height:
                      160, // <-- INCREASE THIS VALUE TO MAKE THE IMAGE BIGGER
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 160,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorited = favoritesProvider.isFavorite(item.id);
                    return CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => favoritesProvider.toggleFavorite(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3, // <-- ALLOW MORE LINES FOR DESCRIPTION IF NEEDED
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹ ${item.price.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 18),
                    ),
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        final quantity = cart.getItemQuantity(item.id);
                        return quantity == 0
                            ? ElevatedButton(
                                onPressed: () => cart.addItem(item),
                                child: const Text('ADD +'),
                              )
                            : QuantityCounter(item: item);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }this works without available feature*/
  // In class MenuItemCard...

  @override
  Widget build(BuildContext context) {
    // We no longer wrap the whole card. The filter is now applied inside.
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // The ColorFiltered widget now wraps ONLY the image.
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  item.isAvailable ? Colors.transparent : Colors.grey,
                  BlendMode.saturation,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    item.imageUrl,
                    height: 150, // size of the image
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 120,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              // The favorite icon is outside the ColorFiltered widget, so it keeps its color.
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorited = favoritesProvider.isFavorite(item.id);
                    return CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.redAccent : Colors.white,
                        ),

                        // Inside MenuItemCard's build method, in the favorite IconButton...
                        onPressed: () {
                          // Check for login status before toggling favorite
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (authProvider.isLoggedIn) {
                            Provider.of<FavoritesProvider>(
                              context,
                              listen: false,
                            ).toggleFavorite(item);
                          } else {
                            showLoginPrompt(context);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // THIS 'EXPANDED' WIDGET IS THE FIX
                    Expanded(
                      child: Text(
                        '₹ ${item.price.toStringAsFixed(0)}',
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(fontSize: 18),
                      ),
                    ),
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        // THIS IS THE FIX: Check for availability first.
                        if (!item.isAvailable) {
                          return const Chip(
                            label: Text('Unavailable'),
                            backgroundColor: Colors.grey,
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }

                        // If the item is available, show the button or counter.
                        final quantity = cart.getItemQuantity(item.id);
                        return quantity == 0
                            ? ElevatedButton(
                                onPressed: () => cart.addItem(item),
                                child: const Text('ADD +'),
                              )
                            : QuantityCounter(item: item);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET FOR THE - 1 + COUNTER (No Changes)
class QuantityCounter extends StatelessWidget {
  const QuantityCounter({super.key, required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getItemQuantity(item.id);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => cart.removeSingleItem(item.id),
            splashRadius: 20,
            constraints: const BoxConstraints(),
          ),
          Text(
            quantity.toString(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => cart.addItem(item),
            splashRadius: 20,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
// Add this function at the bottom of lib/menu_screen.dart

void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Login Required'),
      content: const Text('You need to be logged in to perform this action.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        ElevatedButton(
          child: const Text('Login'),
          onPressed: () {
            Navigator.of(ctx).pop(); // Close the dialog
            Navigator.pushNamed(context, '/login'); // Go to login page
          },
        ),
      ],
    ),
  );
}
