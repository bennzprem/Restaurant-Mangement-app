import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../theme.dart'; // Make sure you have your AppTheme import
import '../menu_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCulinaryCuratorSection extends StatefulWidget {
  const AiCulinaryCuratorSection({super.key});

  @override
  State<AiCulinaryCuratorSection> createState() => _AiCulinaryCuratorSectionState();
}

class _AiCulinaryCuratorSectionState extends State<AiCulinaryCuratorSection> {
  // State for the recommendation loaded initially
  Map<String, dynamic>? _initialDish;
  String? _initialReason;
  bool _isLoadingInitial = true;

  // State for the user's custom search
  Map<String, dynamic>? _searchedDish;
  String? _searchedReason;
  bool _isSearching = false;
  String? _searchError;

  final TextEditingController _prefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialRecommendation();
    });
  }

  Future<void> _fetchInitialRecommendation() async {
    // This is called once when the widget loads
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? "guest";

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/recommendation/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"taste_preference": null}), // No preference, so backend uses history/trending
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _initialDish = data["dish"];
          _initialReason = data["reason"];
        });
      } else {
        setState(() {
          _searchError = "Could not load a suggestion right now.";
        });
      }
    } catch (e) {
      setState(() {
        _searchError = "Server connection error.";
      });
    } finally {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _fetchCustomRecommendation() async {
    // This is called when the user clicks the button
    if (_prefController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? "guest";

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/recommendation/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"taste_preference": _prefController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchedDish = data["dish"];
          _searchedReason = data["reason"];
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _searchError = errorData['error'] ?? 'Could not find a match.';
          _searchedDish = null; // Clear previous search result on error
        });
      }
    } catch (e) {
      setState(() {
        _searchError = "Server error: $e";
        _searchedDish = null;
      });
    }

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);

    // Determine which dish and reason to display
    final Map<String, dynamic>? dishToDisplay = _searchedDish ?? _initialDish;
    final String? reasonToDisplay = _searchedReason ?? _initialReason;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                "AI Culinary Curator",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Get a personalized dish recommendation just for you.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              if (_isLoadingInitial)
                const Center(child: CircularProgressIndicator())
              else if (dishToDisplay != null)
                _buildRecommendationCard(
                  imageUrl: dishToDisplay['image_url'] ?? '',
                  dishName: dishToDisplay['name'] ?? 'No Name',
                  reason: dishToDisplay['description'] ?? reasonToDisplay ?? 'Our special pick.',
                  price: dishToDisplay['price']?.toDouble() ?? 0.0,
                  dishId: dishToDisplay['id'],
                )
              else if (_searchError != null)
                 Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 16)),

              const SizedBox(height: 40),

              // Search Section
              Text(
                "Or, Find Your Own Craving",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: titleColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prefController,
                      decoration: const InputDecoration(
                        labelText: "e.g., 'Something spicy but healthy'",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _fetchCustomRecommendation(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _fetchCustomRecommendation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Get Suggestion"),
                  ),
                ],
              ),
               if (_searchError != null && !_isLoadingInitial)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(_searchError!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String imageUrl,
    required String dishName,
    required String reason,
    required double price,
    int? dishId,
  }) {
    return _AnimatedFoodCard(
      imageUrl: imageUrl,
      dishName: dishName,
      reason: reason,
      price: price,
      dishId: dishId,
    );
  }
}

class _AnimatedFoodCard extends StatefulWidget {
  final String imageUrl;
  final String dishName;
  final String reason;
  final double price;
  final int? dishId;

  const _AnimatedFoodCard({
    required this.imageUrl,
    required this.dishName,
    required this.reason,
    required this.price,
    this.dishId,
  });

  @override
  State<_AnimatedFoodCard> createState() => _AnimatedFoodCardState();
}

class _AnimatedFoodCardState extends State<_AnimatedFoodCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _floatingController;
  late AnimationController _flipController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _flipAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_floatingController);
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _flipController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _flipController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          // Navigate to menu page with specific dish
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                initialCategory: widget.dishName,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 250,
          height: 350,
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _floatingAnimation, _flipAnimation]),
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final isFlipped = _flipAnimation.value > 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value * 3.14159),
                  child: isFlipped ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: _buildBackCard(),
                  ) : _buildFrontCard(),
                );
              },
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated circles background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              children: [
                // Circle 1
                Positioned(
                  top: 20,
                  left: 20,
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value * 10),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBB66),
                            shape: BoxShape.circle,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFBB66).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Circle 2 (bottom)
                Positioned(
                  top: 0,
                  left: 50,
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (_floatingAnimation.value - 0.3) * 10),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8866),
                            shape: BoxShape.circle,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8866).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Circle 3 (right)
                Positioned(
                  top: -80,
                  left: 160,
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (_floatingAnimation.value - 0.7) * 10),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2233),
                            shape: BoxShape.circle,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF2233).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Food image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF151515),
                    child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          // Top left badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                "OUR SUGGESTION",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(
                widget.dishName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blurred dish image background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF151515),
                      child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top section with badge and favorite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "OUR SUGGESTION",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dish name
                  Text(
                    widget.dishName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.reason, // This is the actual description from the database
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '₹${widget.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add to cart button
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          // Add to cart logic would go here
                          // This preserves the existing functionality
                        },
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                color: Colors.black,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Add to Cart",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}