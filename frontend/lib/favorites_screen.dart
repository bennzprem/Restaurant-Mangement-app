// lib/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_provider.dart';
import 'models.dart';
import 'cart_provider.dart';

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
      appBar: AppBar(title: const Text('Your Favorites')),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDAE952)),
            );
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Text(
                provider.error,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          if (provider.favoriteItems.isEmpty) {
            return const Center(
              child: Text(
                'You have no favorite items yet.\nTap the heart icon to add some!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
    );
  }

  Widget _buildFavoriteItemCard(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  color: const Color(0xFFF3F8C5),
                  child: const Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Color(0xFFDAE952),
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
                  // Title
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDAE952),
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
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Unavailable',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          final quantity = cart.getItemQuantity(item.id);
                          return quantity == 0
                              ? ElevatedButton(
                                  onPressed: () => cart.addItem(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDAE952),
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDAE952).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDAE952)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16, color: Color(0xFFDAE952)),
            onPressed: () => cart.removeSingleItem(item.id),
            splashRadius: 16,
            constraints: const BoxConstraints(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: Color(0xFFDAE952)),
            onPressed: () => cart.addItem(item),
            splashRadius: 16,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
