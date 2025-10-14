// lib/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../utils/theme.dart';
import '../widgets/header_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tell the provider to fetch the latest favorites when the screen loads
      Provider.of<FavoritesProvider>(context, listen: false).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Fixed Header
          HeaderWidget(
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          // Main content
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                  );
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Text(
                      provider.error,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.red[300] 
                            : Colors.red, 
                        fontSize: 18
                      ),
                    ),
                  );
                }

                if (provider.favoriteItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'You have no favorite items yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore the menu and tap the heart to add favorites.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[500]
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to menu screen
                            Navigator.pushNamed(context, '/menu');
                          },
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Browse Menu'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // We use a ListView for a cleaner look on the favorites page
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: provider.favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = provider.favoriteItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildFavoriteItemCard(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItemCard(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                item.isAvailable ? Colors.transparent : Colors.grey,
                BlendMode.saturation,
              ),
              child: Image.network(
                item.imageUrl,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: 120,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // Content section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with favorite button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Heart icon to unlike
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            padding: const EdgeInsets.all(8),
                            iconSize: 18,
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              Provider.of<FavoritesProvider>(
                                context,
                                listen: false,
                              ).toggleFavorite(item);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]!,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Price and action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),

                      // Action button
                      Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          if (!item.isAvailable) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[700] : Colors.grey[100]!,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Unavailable',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          final quantity = cart.getItemQuantity(item.id);
                          return quantity == 0
                              ? MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: ElevatedButton(
                                    onPressed: () => cart.addItem(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : _buildQuantityCounter(item);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCounter(MenuItem item) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getItemQuantity(item.id);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).primaryColor.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: Icon(Icons.remove, size: 16, color: Theme.of(context).primaryColor),
              onPressed: () => cart.removeSingleItem(item.id),
              splashRadius: 16,
              constraints: const BoxConstraints(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
              onPressed: () => cart.addItem(item),
              splashRadius: 16,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
