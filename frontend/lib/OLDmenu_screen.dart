// lib/menu_screen.dart
/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'theme.dart';
import 'cart_screen.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart';
import 'favorites_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<MenuCategory>> _menuFuture;
  TabController? _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _menuFuture = _apiService.fetchMenu().then((menu) {
      setState(() {
        _tabController = TabController(length: menu.length, vsync: this);
      });
      return menu;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<MenuCategory>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _tabController == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }

          final menuCategories = snapshot.data!;
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.darkTextColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                tabs: menuCategories.map((cat) => Tab(text: cat.name)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: menuCategories.map((category) {
                    return /*ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: category.items.length,
                      itemBuilder: (context, index) {
                        final item = category.items[index];
                        return MenuItemCard(item: item);
                      },
                    );*/
                    // Inside TabBarView...
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // How many items per row
                            childAspectRatio:
                                0.75, // Adjusts the height of the card
                            crossAxisSpacing:
                                16, // Horizontal space between cards
                            mainAxisSpacing: 16, // Vertical space between cards
                          ),
                      itemCount: category.items.length,
                      itemBuilder: (context, index) {
                        final item = category.items[index];
                        return MenuItemCard(item: item);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
/*
class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.fastfood, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.buttonColor,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorited = favoritesProvider.isFavorite(item.id);
                    return IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.redAccent : Colors.grey,
                      ),
                      onPressed: () {
                        favoritesProvider.toggleFavorite(item);
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: AppTheme.buttonColor,
                  ),
                  onPressed: () {
                    cart.addItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppTheme.darkTextColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
// Replace the ENTIRE existing MenuItemCard class with this new one

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Ensures content respects the rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack allows us to place widgets on top of each other (image, price, favorite icon)
          Stack(
            children: [
              // The main image
              Image.network(
                item.imageUrl,
                height: 150, // Give the image a fixed height
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fastfood, size: 150, color: Colors.grey),
              ),
              // Favorite Icon (top right)
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorited = favoritesProvider.isFavorite(item.id);
                    return CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(
                          isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorited ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () {
                          favoritesProvider.toggleFavorite(item);
                        },
                      ),
                    );
                  },
                ),
              ),
              // Price Tag (bottom left)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkTextColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${item.price.toInt()}', // Using toInt() to match '$12'
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Text content below the image
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/
