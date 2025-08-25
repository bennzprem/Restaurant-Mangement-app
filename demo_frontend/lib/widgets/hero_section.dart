import 'package:flutter/material.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int selectedIndex = 0;

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

  @override
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 900;
    final selected = modes[selectedIndex];

    // Heights
    final double minHeight = 665;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // LEFT WHITE BACKGROUND (60%)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: screenW * 0.6,
            child: Container(color: Colors.white),
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
          SizedBox(
            height: minHeight,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // EXTREME LEFT ARROW
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 36, color: Colors.black87),
                    onPressed: scrollLeft,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 28,
                  ),
                ),
                // HEADINGS & DESCRIPTION COLUMN (as before)
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(modes.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: i < modes.length - 1 ? 22 : 0),
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
                            );
                          }),
                        ),
                        const SizedBox(height: 34),
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
                          onPressed: () {},
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
                // EXPANDED FOR GREEN, no image here!
                Expanded(flex: 5, child: SizedBox()),
                // EXTREME RIGHT ARROW
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 18),
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
          ),
        ],
      ),
    );
  }
}
