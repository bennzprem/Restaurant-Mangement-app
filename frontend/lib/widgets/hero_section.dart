import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'dart:ui'; // Added for ImageFilter
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';

//updated
class HeroSection extends StatefulWidget {
  final VoidCallback onOrderNow;
  final VoidCallback onExplore;
  final VoidCallback onPickup;

  const HeroSection({
    super.key,
    required this.onOrderNow,
    required this.onExplore,
    required this.onPickup,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int selectedIndex = 0;
  int _hoverIndex = -1;
  Timer? _autoScrollTimer;

  final List<Map<String, String>> modes = [
    {
      'title': 'Dine-In',
      'description':
          'Enjoy your meal in our cozy restaurant with excellent service and ambiance.',
      'image': 'assets/images/dine-in.jpg',
      'button': 'Explore',
    },
    {
      'title': 'Delivery',
      'description':
          'Get your favorite food delivered fresh and fast, right to your doorstep.',
      'image': 'assets/images/delivery.jpg',
      'button': 'Order Now',
    },
    {
      'title': 'Takeaway',
      'description':
          'Grab and go! Order ahead and pick up your food at your convenience.',
      'image': 'assets/images/takeaway.jpg',
      'button': 'Pickup',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          selectedIndex = (selectedIndex + 1) % modes.length;
        });
      }
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void scrollLeft() {
    setState(() {
      selectedIndex = (selectedIndex - 1 + modes.length) % modes.length;
    });
    _resetAutoScrollTimer();
  }

  void scrollRight() {
    setState(() {
      selectedIndex = (selectedIndex + 1) % modes.length;
    });
    _resetAutoScrollTimer();
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final minHeight = screenH; // Use full viewport height instead of fixed 665
    final selected = modes[selectedIndex];

    return SizedBox(
      width: double.infinity,
      height: minHeight, // Now uses full viewport height
      child: Stack(
        children: [

          // LEFT BACKGROUND (60%)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: screenW * 0.4,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Stack(
                children: [
                ],
              ),
            ),
          ),

          // DYNAMIC IMAGE BACKGROUND WITH CAPTIONS (40% right side)
Positioned(
  right: 0,
  top: 0,
  width: screenW * 0.4,
            height: minHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Stack(
                key: ValueKey(selected['image']),
                children: [
                  // Background Image with Blur
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: authProvider.isLoggedIn ? 0.0 : 3.0,
                        sigmaY: authProvider.isLoggedIn ? 0.0 : 3.0,
                      ),
  child: Container(
                        decoration: BoxDecoration(
      image: DecorationImage(
                            image: AssetImage(selected['image']!),
        fit: BoxFit.cover, 
      ),
    ),
  ),
),
                  ),
                  // Dark Overlay for better text readability (hidden if logged in)
                  if (!authProvider.isLoggedIn)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                  ),
                  // Caption Content (hidden if logged in)
                  if (!authProvider.isLoggedIn)
                    Positioned.fill(
                      child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDAE952).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color(0xFFDAE952),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                size: 32,
                                color: const Color(0xFFDAE952),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title
                            Text(
                              'Join ByteEat Today!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Subtitle
                            Text(
                              'Discover amazing food experiences\nand exclusive offers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to SignUp page
                                  Navigator.pushNamed(context, '/signup');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDAE952),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Sign Up Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Login Link
                            TextButton(
                              onPressed: () {
                                // Navigate to Login page
                                Navigator.pushNamed(context, '/login');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                              ),
                              child: const Text(
                                'Already have an account? Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
    ),
  ),
),

          // FOREGROUND CONTENT (Row, but no image here)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: screenW * 0.4,
            child: Stack(
              children: [
                // Left arrow at absolute left
                Positioned(
                  top: minHeight / 2 -
                      24, // vertically center (24 = half of icon size)
                  left: 16, // some padding from the edge
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 36,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87),
                    onPressed: scrollLeft,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 28,
                  ),
                ),
                // Main content positioned below header and navbar
                Positioned(
                  top: 200, // Position below the header and navbar
                  left: 56,
                  right: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Service names near top
                        Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(modes.length, (i) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    right: i < modes.length - 1 ? 22 : 0),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                                                      child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = i;
                                      });
                                      _resetAutoScrollTimer();
                                    },
                                    child: Text(
                                      modes[i]['title']!,
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: i == selectedIndex
                                            ? FontWeight.bold
                                            : FontWeight.w400,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? (i == selectedIndex ? Colors.white : Colors.white60)
                                            : (i == selectedIndex ? Colors.black : Colors.black45),
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      // Description
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            selected['description']!,
                            style: TextStyle(
                              fontSize: 22,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 50),
                      // Dynamic action buttons based on selected service
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.3, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _DynamicActionButtons(
                          key: ValueKey(selected['title']),
                          mode: selected['title']!,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right arrow at absolute right (beside image)
                Positioned(
                  top: minHeight / 2 - 24, // vertically center
                  right: 16, // stick to the extreme right
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios_rounded,
                        size: 36,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87),
                    onPressed: scrollRight,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 28,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
class _DynamicActionButtons extends StatefulWidget {
  final String mode;
  const _DynamicActionButtons({super.key, required this.mode});

  @override
  State<_DynamicActionButtons> createState() => _DynamicActionButtonsState();
}

class _DynamicActionButtonsState extends State<_DynamicActionButtons>
    with TickerProviderStateMixin {
  late List<AnimationController> _buttonControllers;
  late List<Animation<double>> _buttonAnimations;

  @override
  void initState() {
    super.initState();
    
    _buttonControllers = List.generate(3, (index) => 
      AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      )
    );
    
    _buttonAnimations = _buttonControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack)
      )
    ).toList();
    
    // Start animations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _startAnimations() {
    if (mounted) {
      for (int i = 0; i < _buttonControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 150), () {
          if (mounted && i < _buttonControllers.length) {
            _buttonControllers[i].forward();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> options = [];
    if (widget.mode == 'Dine-In') {
      options = [
        {'label': 'Reserve a Table', 'icon': Icons.event_seat, 'onTap': () { /*todo*/ }},
        {'label': 'Order from Table', 'icon': Icons.table_restaurant, 'onTap': () { /*todo*/ }},
        {'label': 'Explore Menu', 'icon': Icons.menu_book, 'onTap': () { /*todo*/ }},
      ];
    } else if (widget.mode == 'Delivery') {
      options = [
        {'label': 'Order Now', 'icon': Icons.delivery_dining, 'onTap': () { /*todo*/ }},
        {'label': 'Meal Subscription', 'icon': Icons.subscriptions, 'onTap': () { /*todo*/ }},
        {'label': 'Track Delivery', 'icon': Icons.location_on, 'onTap': () { /*todo*/ }},
      ];
    } else if (widget.mode == 'Takeaway') {
      options = [
        {'label': 'Pickup Option', 'icon': Icons.shopping_bag, 'onTap': () { /*todo*/ }},
        {'label': 'Pre Order', 'icon': Icons.timer, 'onTap': () { /*todo*/ }},
        {'label': 'Favourite Orders', 'icon': Icons.favorite, 'onTap': () { /*todo*/ }},
      ];
    }

    return SizedBox(
      height: 90, // Fixed height to prevent overflow
      child: Row(
        children: options.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> option = entry.value;
          
          return Expanded(
            child: AnimatedBuilder(
              animation: _buttonAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _buttonAnimations[index].value)),
                  child: Opacity(
                    opacity: _buttonAnimations[index].value.clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < options.length - 1 ? 12.0 : 0,
                      ),
                      child: _CompactActionCard(
                        label: option['label'],
                        icon: option['icon'],
                        onTap: option['onTap'],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CompactActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CompactActionCard> createState() => _CompactActionCardState();
}

class _CompactActionCardState extends State<_CompactActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered 
                      ? const Color(0xFFDAE952).withOpacity(0.8)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2)),
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAE952).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            widget.icon,
                            color: const Color(0xFFDAE952),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModernActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int delay;

  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_ModernActionButton> createState() => _ModernActionButtonState();
}

class _ModernActionButtonState extends State<_ModernActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut)
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 320,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered 
                      ? const Color(0xFFDAE952).withOpacity(0.8)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2)),
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAE952).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.icon,
                            color: const Color(0xFFDAE952),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isHovered ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: _isHovered 
                                ? const Color(0xFFDAE952)
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.black54),
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ),
        );
        },
      ),
    );
  }
}

