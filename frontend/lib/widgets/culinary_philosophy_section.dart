import 'package:flutter/material.dart';
import '../theme.dart'; // Assuming your theme file is in the parent directory

class CulinaryPhilosophySection extends StatelessWidget {
  const CulinaryPhilosophySection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF14181C) : const Color(0xFFF8FAFF);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: bgColor,
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
              children: [
                const TextSpan(text: "The "),
                TextSpan(
                  text: "ByteEat Experience",
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What makes every dish, every visit, and every moment special.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: textColor),
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  _PhilosophyCard(
                    icon: Icons.eco_outlined,
                    title: "Farm to Table",
                    description: "We source our ingredients from local farms to ensure peak freshness and quality.",
                    isWide: isWide,
                  ),
                  _PhilosophyCard(
                    icon: Icons.restaurant_menu_outlined,
                    title: "Authentic Flavors",
                    description: "Honoring traditional recipes while embracing a modern culinary twist for a unique taste.",
                    isWide: isWide,
                  ),
                  _PhilosophyCard(
                    icon: Icons.celebration_outlined,
                    title: "Unforgettable Ambiance",
                    description: "More than a meal, it's an experience. We've crafted a space perfect for any occasion.",
                    isWide: isWide,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhilosophyCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isWide;

  const _PhilosophyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isWide,
  });

  @override
  __PhilosophyCardState createState() => __PhilosophyCardState();
}

class __PhilosophyCardState extends State<_PhilosophyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Flexible(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(
            horizontal: widget.isWide ? 16 : 0,
            vertical: widget.isWide ? 0 : 16,
          ),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D21) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? AppTheme.primaryColor : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : (isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
