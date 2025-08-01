// lib/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_provider.dart';
import 'menu_screen.dart'; // We reuse the MenuItemCard
import 'theme.dart';

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
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                child: MenuItemCard(item: item),
              );
            },
          );
        },
      ),
    );
  }
}
