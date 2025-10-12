import 'dart:ui';
import 'package:flutter/material.dart';
import '../menu_screen.dart';
import '../api_service.dart';

class AiCulinaryCuratorSection extends StatefulWidget {
  const AiCulinaryCuratorSection({super.key});

  @override
  State<AiCulinaryCuratorSection> createState() =>
      _AiCulinaryCuratorSectionState();
}

class _AiCulinaryCuratorSectionState extends State<AiCulinaryCuratorSection> {
  // State for recommendations
  List<Map<String, dynamic>> _dishes = [];
  String? _reason;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _searchError;

  final TextEditingController _prefController = TextEditingController();
  final ApiService _apiService = ApiService();
  // REMOVED: PageController and _currentPage are no longer needed.

  // ai_culinary_curator_section.dart

  // REPLACE the code from initState down to the end of _fetchCustomRecommendation
  // with this new, corrected block.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations(); // Load personalized recommendations from database
    });
  }
  
  @override
  void dispose() {
    _prefController.dispose();
    super.dispose();
  }

  // Fetch personalized recommendations from database
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _searchError = null;
    });

    try {
      // Get current user ID (you might need to adjust this based on your auth system)
      // For now, using a placeholder - in real app, get from auth provider
      final userId = "00000000-0000-0000-0000-000000000000"; // Placeholder for new users
      
      // Fetch personalized recommendations
      final recommendations = await _apiService.getRecommendations(userId);
      
      // Convert to the expected format
      final recommendationItems = recommendations
          .map((item) => {
            'id': item.id,
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'image_url': item.imageUrl,
            'is_veg': item.isVegetarian,
            'is_bestseller': item.isBestseller,
          })
          .toList();
      
      setState(() {
        _dishes = recommendationItems;
        _reason = recommendationItems.isNotEmpty 
            ? "Discover our chef's special recommendations!" 
            : "Check out our popular menu items!";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchError = "Failed to load recommendations. Please try again.";
        _dishes = [];
        _isLoading = false;
      });
    }
  }

  // AI-powered custom search using Groq LLM + Pinecone
  void _handleCustomSearch() async {
    final tastePreference = _prefController.text;
    if (tastePreference.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      // Use the new AI-powered craving search
      final searchResults = await _apiService.findCraving(tastePreference);
      
      // Convert to the expected format
      final searchItems = searchResults
          .map((item) => {
            'id': item.id,
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'image_url': item.imageUrl,
            'is_veg': item.isVegetarian,
            'is_bestseller': item.isBestseller,
          })
          .toList();
      
      setState(() {
        _dishes = searchItems;
        _reason = searchItems.isNotEmpty 
            ? "AI found these perfect matches for your craving!" 
            : "No matches found. Try browsing our menu categories!";
        _isSearching = false;
        _searchError = null; // Clear any previous errors
      });
    } catch (e) {
      setState(() {
        _searchError = "Search failed. Please try again or browse our menu categories.";
        _dishes = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 64),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 48),
            child: Column(
              children: [
                Text(
                  "AI Culinary Curator",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: titleColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "Get personalized dish recommendations just for you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 48),
                
                // --- Recommendations Section ---
                _buildRecommendationsView(),
                
                const SizedBox(height: 40),

                // --- Search Section ---
                Text(
                  "Or, Find Your Own Craving",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: titleColor),
                ),
                const SizedBox(height: 20),
                _buildSearchView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CHANGED: This method now uses a Wrap widget instead of a PageView.
  Widget _buildRecommendationsView() {
    if (_isLoading) {
      // Set a fixed height to prevent layout jumps while loading.
      return const SizedBox(height: 380, child: Center(child: CircularProgressIndicator()));
    }
    if (_searchError != null && _dishes.isEmpty) {
      return SizedBox(height: 380, child: Center(child: Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 16))));
    }
    
    // Using a Wrap widget makes the layout responsive automatically.
    // Cards will sit side-by-side and wrap to the next line on smaller screens.
    return Wrap(
      spacing: 24, // Horizontal space between cards.
      runSpacing: 24, // Vertical space between cards when they wrap.
      alignment: WrapAlignment.center,
      children: _dishes.map((dish) {
        return _buildRecommendationCard(
          imageUrl: dish['image_url'] ?? '',
          dishName: dish['name'] ?? 'No Name',
          reason: dish['description'] ?? _reason ?? 'Our special pick.',
          price: dish['price']?.toDouble() ?? 0.0,
          dishId: dish['id'],
        );
      }).toList(),
    );
  }

  // REMOVED: The _buildDot method is no longer needed.
  
  Widget _buildSearchView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: TextField(
                  controller: _prefController,
                  decoration: const InputDecoration(
                    labelText: "e.g., 'Something spicy but healthy'",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleCustomSearch(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isSearching ? null : _handleCustomSearch,
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
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(_searchError!, style: const TextStyle(color: Colors.red)),
          ),
      ],
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


// --- NO CHANGES NEEDED FOR THE WIDGET BELOW ---
// The existing _AnimatedFoodCard is perfect.

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
      duration: const Duration(milliseconds: 800),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                initialCategory: widget.dishName,
                initialItemId: widget.dishId,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              children: [
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.reason,
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

