import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'auth_provider.dart'; // keep your auth provider import
import 'menu_screen.dart';
import 'dine_in_page.dart';
import 'takeaway_page.dart';

import '../widgets/header_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/menu_section.dart';
import '../widgets/about_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/newsletter_section.dart';
import '../widgets/footer_widget.dart';
import '../widgets/navbar_widget.dart';

import 'theme.dart'; // Your AppTheme

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _handleNavigation(BuildContext context, String serviceType) {
    switch (serviceType) {
      case 'Delivery':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
        break;
      case 'Dine-In':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DineInPage()),
        );
        break;
      case 'Takeaway':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TakeawayPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                HeroSection(
                  onOrderNow: () => _handleNavigation(context, 'Delivery'),
                  onExplore: () => _handleNavigation(context, 'Dine-In'),
                  onPickup: () => _handleNavigation(context, 'Takeaway'),
                ),

                // Continuing the home_screen.dart sections
                _MenuCategoryCarousel(),
                AboutSection(),
                TestimonialsSection(),
                NewsletterSection(),
                FooterWidget(),
              ],
            ),
          ),

          // Fixed header always visible
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(),
          ),

          // Positioned login/profile button can be added if needed here,
          // but the original home_page used AppBar for this - we can optionally add a floating or header widget for that separately if needed
        ],
      ),
    );
  }
}

class _ServiceSelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Color(0xFFDAE952)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFFDAE952)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCategoryCarousel extends StatefulWidget {
  final String searchQuery;

  const _MenuCategoryCarousel({this.searchQuery = ''});

  @override
  State<_MenuCategoryCarousel> createState() => _MenuCategoryCarouselState();
}

class _MenuCategoryCarouselState extends State<_MenuCategoryCarousel> {
  final List<String> categories = [
    'Appetizers',
    'Soups & Salads',
    'Pizzas (11-inch)',
    'Pasta',
    'Sandwiches & Wraps',
    'Main Course - Indian',
    'Main Course - Global',
    'Desserts',
    'Beverages',
  ];

  final ScrollController _scrollController = ScrollController();

  final Map<String, IconData> categoryIcons = {
    'Appetizers': Icons.fastfood,
    'Soup & Salad': Icons.ramen_dining,
    'Pizza': Icons.local_pizza,
    'Pasta': Icons.restaurant_menu,
    'Sandwich & Wrap': Icons.lunch_dining,
    'Maincourse - Indian': Icons.dinner_dining,
    'Maincourse - Global': Icons.public,
    'Dessert': Icons.icecream,
    'Beverage': Icons.local_cafe,
  };

  void scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDAE952).withOpacity(0.08),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Menu Categories',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, size: 32),
                onPressed: scrollLeft,
              ),
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final name = categories[index];
                      final icon = categoryIcons[name] ?? Icons.restaurant_menu;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MenuScreen(initialCategory: name),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 5,
                          color: Colors.white,
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 36, color: Colors.black),
                                const SizedBox(height: 16),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Icon(Icons.arrow_forward,
                                    color: Color(0xFFDAE952), size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, size: 32),
                onPressed: scrollRight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
