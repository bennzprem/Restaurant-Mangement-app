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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center in white part
        children: List.generate(_navItems.length, (index) {
          bool isActive = index == _activeIndex;
          bool isHover = index == _hoverIndex;
          return MouseRegion(
            onEnter: (_) => setState(() => _hoverIndex = index),
            onExit: (_) => setState(() => _hoverIndex = -1),
            child: InkWell(
              onTap: () => _onNavTap(index),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 14),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Text(
                      _navItems[index],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFFDAE952)
                            : isHover
                                ? const Color(0xFFDAE952)
                                : Colors.black87,
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
    );
  }
}
