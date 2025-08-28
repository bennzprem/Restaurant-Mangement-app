// lib/ch/recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../auth_provider.dart';
import '../cart_provider.dart';
import '../models.dart';

class RecommendationCard extends StatefulWidget {
  const RecommendationCard({super.key});

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  Future<MenuItem?>? _recommendationFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendation();
    });
  }

  void _fetchRecommendation() {
    final apiService = ApiService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      // If user is not logged in, no need to do anything
      setState(() {
        _recommendationFuture = Future.value(null);
      });
      return;
    }

    // We set the future here, so the FutureBuilder can listen to it
    setState(() {
      _recommendationFuture = _getRecommendation(apiService, userId);
    });
  }

  Future<MenuItem?> _getRecommendation(ApiService apiService, String userId) async {
    try {
      // 1. Fetch both the full menu and the user's order history at the same time
      final results = await Future.wait([
        apiService.fetchMenu(vegOnly: false, veganOnly: false, glutenFreeOnly: false, nutsFree: false),
        apiService.fetchOrderHistory(userId),
      ]);

      final List<MenuCategory> menu = results[0] as List<MenuCategory>;
      final List<Order> history = results[1] as List<Order>;

      if (history.isEmpty || menu.isEmpty) {
        return null; // Not enough data to make a recommendation
      }
      
      // In a real app, you'd get order_items. Here we simplify.
      // For this project, we'll find the most ordered *item* and recommend something from the same *category*.
      
      // This is a simplified analysis logic.
      // Let's assume the first item in the user's most recent order is representative.
      // A more complex analysis would count all items across all orders.
      final mostRecentOrder = history.first; 
      
      // We don't have items in the order model, so we'll just pick a popular category for demo.
      // Let's find the "Pizzas" category as a stand-in for a real recommendation.
      final popularCategory = menu.firstWhere(
        (cat) => cat.name.contains('Pizzas'),
        orElse: () => menu.first // fallback to the first category
      );
      
      // Find a pizza the user hasn't ordered (for demo, we'll just pick the first one)
      if (popularCategory.items.isNotEmpty) {
        return popularCategory.items.first;
      }

      return null;
    } catch (e) {
      print("Error fetching recommendation: $e");
      return null; // Return null on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MenuItem?>(
      future: _recommendationFuture,
      builder: (context, snapshot) {
        // --- Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 2,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // --- No Recommendation State ---
        if (!snapshot.hasData || snapshot.data == null) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Order a few meals to get personalized recommendations!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        // --- Success State: Show Recommendation ---
        final item = snapshot.data!;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recommended For You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false).addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} added to cart!'), duration: const Duration(seconds: 2)),
                      );
                    },
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}