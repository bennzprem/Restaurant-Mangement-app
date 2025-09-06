import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int _activeIndex = 0;
  int _hoverIndex = -1;
  final List<String> _navItems = ['Home', 'Menu', 'About', 'Contact'];

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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Left side - White content area (60% width)
            Expanded(
              flex: 6,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700), // Limit width within white area
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFDAE952), // Start with theme green
                        Color(0xFFB8D43A), // Slightly darker green
                        Color(0xFF9BC53D), // More saturated green
                        Color(0xFF7FB139), // Darker green
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),      // Left top sharp
                      bottomLeft: Radius.circular(50),  // Left bottom round (smaller)
                      topRight: Radius.circular(50),    // Right top round (smaller)
                      bottomRight: Radius.circular(0),  // Right bottom sharp
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDAE952).withOpacity(0.3),
                        blurRadius: 6, // Smaller shadow
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // Smaller padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Smaller padding
                            decoration: BoxDecoration(
                              color: (isActive || isHover) 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16), // Smaller radius
                            ),
                            child: Text(
                              _navItems[index],
                              style: TextStyle(
                                fontSize: 20, // Smaller font
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
                                letterSpacing: 1.0, // Smaller letter spacing
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            // Right side - Image area (40% width) - Empty space
            Expanded(
              flex: 4,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
