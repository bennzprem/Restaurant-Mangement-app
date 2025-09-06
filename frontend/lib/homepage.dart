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
    // Simple suggestion banner to go to role dashboard

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth < 720
                ? 12
                : constraints.maxWidth < 1100
                    ? 20
                    : 0;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    HeroSection(
                      onOrderNow: () => _handleNavigation(context, 'Delivery'),
                      onExplore: () => _handleNavigation(context, 'Dine-In'),
                      onPickup: () => _handleNavigation(context, 'Takeaway'),
                    ),
                    if (authProvider.isLoggedIn) _RoleQuickAccess(),
                    _MenuCategoryCarousel(),
                    AboutSection(),
                    TestimonialsSection(),
                    NewsletterSection(),
                    FooterWidget(),
                  ],
                ),
              ),
            );
          }),

          // Fixed header always visible
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                HeaderWidget(),
                const NavbarWidget(),
              ],
            ),
          ),

          // Positioned login/profile button can be added if needed here,
          // but the original home_page used AppBar for this - we can optionally add a floating or header widget for that separately if needed
        ],
      ),
    );
  }
}

class _RoleQuickAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    String? route;
    if (auth.isAdmin) {
      route = '/admin_dashboard';
    } else if (auth.isManager)
      route = '/manager_dashboard';
    else if (auth.isKitchen)
      route = '/kitchen_dashboard';
    else if (auth.isDelivery)
      route = '/delivery_dashboard';
    else if (auth.isEmployee) route = '/employee_dashboard';

    if (route == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, route!),
          icon: const Icon(Icons.dashboard_customize),
          label: const Text('Go to your dashboard'),
        ),
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
              Icon(icon, size: 40, color: AppTheme.primaryColor),
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
                        color: AppTheme.customBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style:
                          const TextStyle(fontSize: 16, color: AppTheme.customGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
            ],
          ),
        ), 
      ),
    );
  }
}

class _MenuCategoryCarousel extends StatefulWidget {
  const _MenuCategoryCarousel();

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
  Timer? _autoScrollTimer;
  int _currentScrollIndex = 0;
  int _hoveredIndex = -1;

  final Map<String, IconData> categoryIcons = {
    'Appetizers': Icons.fastfood,
    'Soups & Salads': Icons.ramen_dining,
    'Pizzas (11-inch)': Icons.local_pizza,
    'Pasta': Icons.restaurant_menu,
    'Sandwiches & Wraps': Icons.lunch_dining,
    'Main Course - Indian': Icons.dinner_dining,
    'Main Course - Global': Icons.public,
    'Desserts': Icons.icecream,
    'Beverages': Icons.local_cafe,
  };

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    
    // Add scroll listener to track position and ensure smooth looping
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        
        // Update current index based on scroll position
        _currentScrollIndex = (currentOffset / 160.0).round();
        if (_currentScrollIndex >= categories.length) {
          _currentScrollIndex = categories.length - 1;
        }
        
        // Ensure we stay within bounds
        if (_currentScrollIndex < 0) {
          _currentScrollIndex = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _autoScrollToNext();
      }
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _autoScrollToNext() {
    if (_scrollController.hasClients) {
      // Move to the next category in circular motion
      _currentScrollIndex = (_currentScrollIndex + 1) % categories.length;
      
      // Calculate the target offset for smooth scrolling
      double targetOffset;
      
      if (_currentScrollIndex == 0) {
        // When we reach the end, smoothly scroll back to the beginning
        targetOffset = 0;
      } else {
        targetOffset = _currentScrollIndex * 160.0; // 140 (width) + 20 (separator)
      }
      
      // Ensure smooth circular scrolling
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void scrollLeft() {
    if (_scrollController.hasClients) {
      _currentScrollIndex = (_currentScrollIndex - 1 + categories.length) % categories.length;
      
      // Calculate the target offset for smooth circular scrolling
      double targetOffset;
      if (_currentScrollIndex == categories.length - 1) {
        // When going left from first item, smoothly scroll to the end
        targetOffset = (categories.length - 1) * 160.0;
      } else {
        targetOffset = _currentScrollIndex * 160.0;
      }
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
    _resetAutoScrollTimer();
  }

  void scrollRight() {
    if (_scrollController.hasClients) {
      _currentScrollIndex = (_currentScrollIndex + 1) % categories.length;
      
      // Calculate the target offset for smooth circular scrolling
      double targetOffset;
      if (_currentScrollIndex == 0) {
        // When we reach the end, smoothly scroll back to the beginning
        targetOffset = 0;
      } else {
        targetOffset = _currentScrollIndex * 160.0;
      }
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
    _resetAutoScrollTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Text('Menu Categories',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 24),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left, size: 32, color: isDark ? AppTheme.white.withOpacity(0.7) : AppTheme.customBlack),
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
                                                 child: MouseRegion(
                           onEnter: (_) => setState(() => _hoveredIndex = index),
                           onExit: (_) => setState(() => _hoveredIndex = -1),
                           child: AnimatedContainer(
                             duration: const Duration(milliseconds: 400),
                             decoration: BoxDecoration(
                               color: _hoveredIndex == index 
                                   ? AppTheme.primaryColor.withOpacity(0.2)
                                   : (isDark ? AppTheme.white.withOpacity(0.06) : AppTheme.white.withOpacity(0.7)),
                               borderRadius: BorderRadius.circular(24),
                               border: Border.all(
                                 color: _hoveredIndex == index 
                                     ? AppTheme.primaryColor
                                     : AppTheme.white.withOpacity(isDark ? 0.12 : 0.2),
                                 width: _hoveredIndex == index ? 2 : 1,
                               ),
                               boxShadow: [
                                 BoxShadow(
                                   color: _hoveredIndex == index
                                       ? AppTheme.primaryColor.withOpacity(0.3)
                                       : AppTheme.black.withOpacity(isDark ? 0.5 : 0.06),
                                   blurRadius: 18,
                                   offset: const Offset(0, 8),
                                 ),
                               ],
                             ),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                                                                                  Icon(
                                   icon, 
                                   size: 36, 
                                   color: _hoveredIndex == index 
                                       ? AppTheme.black
                                       : (isDark ? AppTheme.white : AppTheme.black),
                                 ),
                                 const SizedBox(height: 16),
                                 Text(
                                   name,
                                   textAlign: TextAlign.center,
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                     color: _hoveredIndex == index 
                                         ? AppTheme.black
                                         : (isDark ? AppTheme.white : AppTheme.black),
                                   ),
                                 ),
                                const SizedBox(height: 10),
                                const Icon(Icons.arrow_forward,
                                    color: AppTheme.primaryColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),);
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right, size: 32, color: isDark ? AppTheme.white.withOpacity(0.7) : AppTheme.customBlack),
                onPressed: scrollRight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
