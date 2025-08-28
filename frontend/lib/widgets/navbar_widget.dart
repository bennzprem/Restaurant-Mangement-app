import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_provider.dart';
import '../favorites_screen.dart';
import '../cart_screen.dart';

class NavbarWidget extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<bool>? onSearchExpansionChanged;
  final bool? isSearchExpanded;
  final VoidCallback? onFilterPressed;
  final String? tableSessionId;

  const NavbarWidget({
    super.key,
    this.searchController,
    this.onSearchExpansionChanged,
    this.isSearchExpanded,
    this.onFilterPressed,
    this.tableSessionId,
  });

  @override
  State createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int _activeIndex = 0;
  int _hoverIndex = -1;
  final List<String> _navItems = ['Home', 'Menu', 'About', 'Contact'];
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndexWithRoute();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndexWithRoute();
  }

  void _syncIndexWithRoute() {
    final routeName = ModalRoute.of(context)?.settings.name ?? '/';
    setState(() {
      if (routeName == '/menu') {
        _activeIndex = 1;
      } else if (routeName == '/about') {
        _activeIndex = 2;
      } else if (routeName == '/contact') {
        _activeIndex = 3;
      } else {
        _activeIndex = 0;
      }
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _activeIndex = index;
    });
    String route = '/';
    switch (index) {
      case 1:
        route = '/menu';
        break;
      case 2:
        route = '/about';
        break;
      case 3:
        route = '/contact';
        break;
      default:
        route = '/';
        break;
    }
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Left side - Navigation items
          Expanded(
            child: Row(
              children: List.generate(_navItems.length, (index) {
                bool isActive = index == _activeIndex;
                bool isHover = index == _hoverIndex;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoverIndex = index),
                  onExit: (_) => setState(() => _hoverIndex = -1),
                  child: InkWell(
                    onTap: () => _onNavTap(index),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Text(
                            _navItems[index],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                              color: isActive
                                  ? const Color(0xFFDAE952)
                                  : isHover
                                      ? const Color(0xFFDAE952)
                                      : (isDark ? Colors.white : Colors.black87),
                              letterSpacing: 1.3,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 210),
                            height: 4,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: (isActive || isHover)
                                  ? const Color(0xFFDAE952)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            width: (isActive || isHover) ? 28 : 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Right side - Search, Filter, Favorites, Cart
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expandable Search
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSearchExpanded ? 260 : 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDAE952), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_isSearchExpanded) ...[
                      Expanded(
                        child: TextField(
                          controller: widget.searchController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search for dishes...',
                            hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black45),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = false;
                          });
                          widget.onSearchExpansionChanged?.call(false);
                        },
                      ),
                    ] else ...[
                      IconButton(
                        icon: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: const Color(0xFFDAE952),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = true;
                          });
                          widget.onSearchExpansionChanged?.call(true);
                        },
                                              style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Filter button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDAE952), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 22,
                    color: const Color(0xFFDAE952),
                  ),
                  onPressed: widget.onFilterPressed,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Favorites button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDAE952), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.favorite_rounded,
                    size: 22,
                    color: const Color(0xFFDAE952),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Cart button with badge
              Consumer<CartProvider>(
                builder: (_, cart, ch) => Badge(
                  label: Text(
                    cart.items.values.fold(0, (sum, item) => sum + item.quantity).toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  isLabelVisible: cart.items.isNotEmpty,
                  backgroundColor: const Color(0xFFDAE952),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDAE952), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.shopping_cart_rounded,
                        size: 22,
                        color: const Color(0xFFDAE952),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CartScreen(tableSessionId: widget.tableSessionId),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
