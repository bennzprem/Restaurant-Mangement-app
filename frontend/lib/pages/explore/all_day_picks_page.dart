import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/header_widget.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class AllDayPicksPage extends StatefulWidget {
  const AllDayPicksPage({super.key});

  @override
  State<AllDayPicksPage> createState() => _AllDayPicksPageState();
}

class _AllDayPicksPageState extends State<AllDayPicksPage> {
  int _selectedCategoryIndex = 0;
  final ApiService _apiService = ApiService();
  Future<List<MenuCategory>>? _menuFuture;
  String? _selectedRightCategoryName;
  final GlobalKey _headerTitleKey = GlobalKey();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = const [
    {
      "title": "Breakfast Delights",
      "icon": Icons.free_breakfast,
      "subtitle": "Wholesome starts for fresh mornings"
    },
    {
      "title": "Lunch Favorites", 
      "icon": Icons.lunch_dining,
      "subtitle": "Hearty plates to power your day"
    },
    {
      "title": "Evening Snacks",
      "icon": Icons.emoji_food_beverage,
      "subtitle": "Crunchy, chatpata pick-me-ups"
    },
    {
      "title": "Dinner Specials",
      "icon": Icons.restaurant,
      "subtitle": "Slow-cooked comfort for cosy nights"
    },
  ];

  String _currentMealTimeKey() {
    // Maps the left list selection to DB meal_time values
    switch (_selectedCategoryIndex) {
      case 0:
        return 'breakfast';
      case 1:
        return 'lunch';
      case 2:
        return 'snacks';
      case 3:
      default:
        return 'dinner';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleInitialCategory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleInitialCategory() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['initialCategory'] != null) {
      final initialCategory = args['initialCategory'] as String;
      final index = categories.indexWhere((cat) => cat['title'] == initialCategory);
      if (index != -1) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      }
    }
  }

  Future<void> _loadMenu() async {
    try {
      final menu = await _apiService.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
        mealTime: _currentMealTimeKey(),
      );
      setState(() {
        _menuFuture = Future.value(menu);
        _selectedRightCategoryName = menu.isNotEmpty ? menu.first.name : null;
      });
    } catch (e) {
      setState(() {
        _menuFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 75),
            child: FutureBuilder<List<MenuCategory>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final menuCategories = snapshot.data!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left category list
                    _buildGlassContainer(
                      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      dense: true,
                      child: _buildLeftCategoryList(),
                    ),
                    
                    // Right menu items
                    Expanded(
                      child: _buildGlassContainer(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        dense: true,
                        child: _buildRightMenuList(menuCategories),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.menu,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/explore-menu');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required EdgeInsets margin, bool dense = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: Container(
            decoration: BoxDecoration(
              color: dense
                  ? (isDark
                      ? Colors.black.withOpacity(0.72)
                      : Colors.white.withOpacity(0.97))
                  : (isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: dense
                    ? (isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.45))
                    : (isDark
                        ? Colors.white.withOpacity(0.22)
                        : Colors.white.withOpacity(0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftCategoryList() {
    return Container(
      width: 280,
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All-Day Picks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Filters',
                onPressed: () => Navigator.pushNamed(context, '/menu'),
                icon: const Icon(Icons.filter_list),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryItem(
                  category,
                  index,
                  isSelected: index == _selectedCategoryIndex,
                  onTap: () async {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                    await _loadMenu();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> category,
    int index, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  category['icon'],
                  size: 20,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.black87)
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.black87)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightMenuList(List<MenuCategory> menuCategories) {
    final selectedCategory = categories[_selectedCategoryIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableCategoryNames = menuCategories.map((c) => c.name).toList();
    final selectedRightName = _selectedRightCategoryName ?? (availableCategoryNames.isNotEmpty ? availableCategoryNames.first : null);
    final filteredItems = selectedRightName == null
        ? <MenuItem>[]
        : (menuCategories.firstWhere(
                (c) => c.name == selectedRightName,
                orElse: () => MenuCategory(id: -1, name: selectedRightName, items: const []))
            .items);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          actions: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isSearching ? 240 : 0,
              child: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    )
                  : null,
            ),
            IconButton(
              tooltip: _isSearching ? 'Close search' : 'Search',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchController.clear();
                });
              },
              icon: Icon(_isSearching ? Icons.close : Icons.search),
            ),
            IconButton(
              tooltip: 'Cart',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark
                          ? Colors.black.withOpacity(0.35)
                          : Colors.white.withOpacity(0.65)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        selectedCategory['icon'],
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  if (selectedRightName != null) {
                                    Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': selectedRightName});
                                  }
                                },
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                  child: Container(
                                    key: _headerTitleKey,
                                    child: Text(selectedRightName ?? 'Select Category'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (availableCategoryNames.isNotEmpty)
                              IconButton(
                                tooltip: 'Change category',
                                onPressed: () async {
                                  // Position the menu right below the category name
                                  final RenderBox? box = _headerTitleKey.currentContext?.findRenderObject() as RenderBox?;
                                  final Offset pos = box?.localToGlobal(Offset.zero) ?? const Offset(200, 140);
                                  final Size size = box?.size ?? const Size(200, 24);
                                  final selected = await showMenu<String>(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      pos.dx,
                                      pos.dy + size.height + 6,
                                      pos.dx + size.width,
                                      0,
                                    ),
                                    items: [
                                      for (final name in availableCategoryNames)
                                        PopupMenuItem<String>(value: name, child: Text(name)),
                                    ],
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      _selectedRightCategoryName = selected;
                                    });
                                  }
                                },
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (filteredItems.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items found for ${selectedCategory['title']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredItems[index];
                  return _buildMenuItemCard(item);
                },
                childCount: filteredItems.length,
              ),
            ),
          ),
      ],
    );
  }

  List<MenuItem> _filterMenuItemsByCategory(List<MenuCategory> menuCategories, String categoryTitle) {
    List<MenuItem> allItems = [];
    for (var category in menuCategories) {
      allItems.addAll(category.items);
    }
    
    // Filter based on category title - you can customize this logic
    return allItems.where((item) {
      // Simple filtering - you can enhance this based on your data structure
      return item.name.toLowerCase().contains(categoryTitle.toLowerCase().split(' ')[0]) ||
             item.description.toLowerCase().contains(categoryTitle.toLowerCase().split(' ')[0]);
    }).toList();
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.restaurant,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMenu,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No menu items available'),
    );
  }
}