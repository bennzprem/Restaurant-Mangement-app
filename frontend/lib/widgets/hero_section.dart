import 'package:flutter/material.dart';

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

  final List<Map<String, String>> modes = [
    {
      'title': 'Dine-In',
      'description':
          'Enjoy your meal in our cozy restaurant with excellent service and ambiance.',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?fit=crop&w=700&q=80',
      'button': 'Explore',
    },
    {
      'title': 'Delivery',
      'description':
          'Get your favorite food delivered fresh and fast, right to your doorstep.',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?fit=crop&w=700&q=80',
      'button': 'Order Now',
    },
    {
      'title': 'Takeaway',
      'description':
          'Grab and go! Order ahead and pick up your food at your convenience.',
      'image':
          'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?fit=crop&w=700&q=80',
      'button': 'Pickup',
    },
  ];

  void scrollLeft() {
    setState(() {
      selectedIndex = (selectedIndex - 1 + modes.length) % modes.length;
    });
  }

  void scrollRight() {
    setState(() {
      selectedIndex = (selectedIndex + 1) % modes.length;
    });
  }

  void _onButtonPressed() {
    // Call the callback matching the selected index
    switch (selectedIndex) {
      case 0:
        widget.onExplore();
        break;
      case 1:
        widget.onOrderNow();
        break;
      case 2:
        widget.onPickup();
        break;
    }
  }

  Widget _buildNavItem(String title, int index, bool isActive) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      child: InkWell(
        onTap: () {
          if (index == 1) {
            Navigator.pushNamed(context, '/menu');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/about');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/contact');
          }
        },
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
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFFDAE952)
                      : _hoverIndex == index
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
                  color: (isActive || _hoverIndex == index)
                      ? const Color(0xFFDAE952)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: (isActive || _hoverIndex == index) ? 28 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final minHeight = 665.0;
    final selected = modes[selectedIndex];

    return SizedBox(
      width: double.infinity,
      height: minHeight, // <-- FIX: constrain height
      child: Stack(
        children: [

          // LEFT WHITE BACKGROUND (60%)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: screenW * 0.4,
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Navigation bar positioned on the left side
                  Positioned(
                    top: 80,
                    left: 36,
                    child: Row(
                      children: [
                        _buildNavItem('Home', 0, true),
                        const SizedBox(width: 20),
                        _buildNavItem('Menu', 1, false),
                        const SizedBox(width: 20),
                        _buildNavItem('About', 2, false),
                        const SizedBox(width: 20),
                        _buildNavItem('Contact', 3, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT GREEN BACKGROUND (40%)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: screenW * 0.4,
            child: Container(color: const Color(0xFFDAE952)),
          ),
          // IMAGE perfectly centered in the green bg:
          Positioned(
            right: 0,
            top: 0,
            width: screenW * 0.4,
            height: minHeight,
            child: Center(
              child: ClipOval(
                child: Image.network(
                  selected["image"]!,
                  width: 370,
                  height: 370,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    width: 370,
                    height: 370,
                  ),
                ),
              ),
            ),
          ),
          // FOREGROUND CONTENT (Row, but no image here)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: screenW * 0.4,
            //height: minHeight - 150,
            child: Stack(
              children: [
                // Left arrow at absolute left
                Positioned(
                  top: minHeight / 2 -
                      24, // vertically center (24 = half of icon size)
                  left: 16, // some padding from the edge
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 36, color: Colors.black87),
                    onPressed: scrollLeft,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 28,
                  ),
                ),
                // Main content centered horizontally
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            56), // Padding so content doesn't collide with arrows
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Service names near top
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 18.0),
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
                                    },
                                    child: Text(
                                      modes[i]['title']!,
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: i == selectedIndex
                                            ? FontWeight.bold
                                            : FontWeight.w400,
                                        color: i == selectedIndex
                                            ? Colors.black
                                            : Colors.black45,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Description and Button
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            selected['description']!,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black87,
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 38),
                        ElevatedButton(
                          onPressed: _onButtonPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 34, vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(selected['button']!),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right arrow at absolute right (beside image)
                Positioned(
                  top: minHeight / 2 - 24, // vertically center
                  right: 16, // stick to the extreme right
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 36, color: Colors.black87),
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
