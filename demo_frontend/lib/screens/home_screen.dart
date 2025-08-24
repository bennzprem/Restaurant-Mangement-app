import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/menu_section.dart';
import '../widgets/about_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/newsletter_section.dart';
import '../widgets/footer_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main scrollable content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Remove HeaderWidget here!
                  HeroSection(),
                  _MenuCategoryCarousel(),
                  AboutSection(),
                  TestimonialsSection(),
                  NewsletterSection(),
                  FooterWidget(),
                ],
              ),
            ),
          // Glassmorphic fixed header
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(),
          ),
        ],
      ),
    );
  }
}

class _MenuCategoryCarousel extends StatefulWidget {
  @override
  State<_MenuCategoryCarousel> createState() => _MenuCategoryCarouselState();
}

class _MenuCategoryCarouselState extends State<_MenuCategoryCarousel> {
  final List<String> categories = [
    'Appetizers',
    'Soup & Salad',
    'Pizza',
    'Pasta',
    'Sandwich & Wrap',
    'Maincourse - Indian',
    'Maincourse - Global',
    'Dessert',
    'Beverage',
  ];

  final ScrollController _scrollController = ScrollController();

  // You can assign custom icons or colors as needed.
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
      _scrollController.offset - 300, // Adjust scroll jump as needed
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
                          Navigator.pushNamed(
                            context,
                            '/menu',
                            arguments: {'category': name},
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
