import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedVeggieBackground extends StatefulWidget {
  const AnimatedVeggieBackground({super.key});

  @override
  State<AnimatedVeggieBackground> createState() => _AnimatedVeggieBackgroundState();
}

class _AnimatedVeggieBackgroundState extends State<AnimatedVeggieBackground> 
    with TickerProviderStateMixin {
  late List<_VeggiePainterController> _controllers;
  
  // Same color as your original file
  final Color _veggieColor = const Color(0xFF7FBF7F);
  
  // Random seed that changes on each rebuild/transition
  int _randomSeed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(35, (index) { // Increased controllers
      return _VeggiePainterController(
        vsync: this,
        delay: Duration(milliseconds: index * 120),
        duration: Duration(seconds: 4 + (index % 4)),
      );
    });
  }

  @override
  void didUpdateWidget(AnimatedVeggieBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _randomSeed = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animations = _controllers.map((c) => c.animation).toList();
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color adaptedColor = isDark 
        ? _veggieColor.withOpacity(0.6) 
        : _veggieColor;

    return Container(
      color: isDark ? Colors.black12 : Colors.white,
      child: CustomPaint(
        painter: _VeggieBackgroundPainter(
          animations: animations,
          veggieColor: adaptedColor,
          randomSeed: _randomSeed,
        ),
        child: Container(),
      ),
    );
  }
}

class _VeggieItem {
  final Offset position;
  final double size;
  final int type;
  final double rotation;
  final IconData icon;

  _VeggieItem({
    required this.position,
    required this.size,
    required this.type,
    required this.rotation,
    required this.icon,
  });
}

class _VeggieBackgroundPainter extends CustomPainter {
  final List<Animation<double>> animations;
  final Color veggieColor;
  final int randomSeed;

  _VeggieBackgroundPainter({
    required this.animations,
    required this.veggieColor,
    required this.randomSeed,
  }) : super(repaint: Listenable.merge(animations));

  // Expanded food icons list
  final List<IconData> _foodIcons = [
    Icons.restaurant_outlined,
    Icons.local_pizza_outlined,
    Icons.lunch_dining_outlined,
    Icons.dinner_dining_outlined,
    Icons.coffee_outlined,
    Icons.local_cafe_outlined,
    Icons.cake_outlined,
    Icons.fastfood_outlined,
    Icons.ramen_dining_outlined,
    Icons.rice_bowl_outlined,
    Icons.icecream_outlined,
    Icons.emoji_food_beverage_outlined,
    Icons.local_drink_outlined,
    Icons.wine_bar_outlined,
    Icons.bakery_dining_outlined,
    Icons.set_meal_outlined,
    Icons.breakfast_dining_outlined,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final List<_VeggieItem> veggieItems = [];
    final math.Random masterRandom = math.Random(randomSeed);
    
    // Use a more sophisticated placement algorithm
    _generatePackedIcons(veggieItems, size, masterRandom);

    // Draw all food icons with animation
    for (int i = 0; i < veggieItems.length; i++) {
      final item = veggieItems[i];
      final int animationIndex = i % animations.length;
      final animation = animations[animationIndex];

      // Floating animation
      final double animPhase = (i % 6) * math.pi / 3;
      final Offset animatedOffset = Offset(
        math.sin(animation.value * math.pi * 2 + animPhase) * 1.2,
        math.cos(animation.value * math.pi * 2 + animPhase) * 1.2,
      );

      final Offset finalPosition = item.position + animatedOffset;

      // Draw thin outline icon
      _drawThinOutlineIcon(canvas, item.icon, finalPosition, item.size, item.rotation);

      // Occasional decorative dots
      if (masterRandom.nextDouble() > 0.85) {
        final Paint dotPaint = Paint()
          ..color = veggieColor.withOpacity(0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          finalPosition + Offset(
            (masterRandom.nextDouble() - 0.5) * item.size * 0.8,
            (masterRandom.nextDouble() - 0.5) * item.size * 0.8,
          ),
          0.6 + masterRandom.nextDouble() * 0.4,
          dotPaint,
        );
      }
    }
  }

  // Advanced icon packing algorithm for better space utilization
  void _generatePackedIcons(List<_VeggieItem> items, Size size, math.Random random) {
    const int maxAttempts = 200; // Maximum placement attempts
    const double minIconSize = 16.0;
    const double maxIconSize = 42.0;
    const double padding = 15.0;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate random icon properties
      double iconSize = minIconSize + random.nextDouble() * (maxIconSize - minIconSize);
      double x = padding + random.nextDouble() * (size.width - 2 * padding - iconSize);
      double y = padding + random.nextDouble() * (size.height - 2 * padding - iconSize);
      double rotation = random.nextDouble() * math.pi / 4 - math.pi / 8;
      int iconType = random.nextInt(_foodIcons.length);

      Offset position = Offset(x + iconSize / 2, y + iconSize / 2);

      // Check for overlaps with existing icons
      bool hasOverlap = false;
      for (var existingItem in items) {
        double distance = (position - existingItem.position).distance;
        double minDistance = (iconSize + existingItem.size) / 2 + 3; // Small buffer
        
        if (distance < minDistance) {
          hasOverlap = true;
          break;
        }
      }

      // If no overlap, add the icon
      if (!hasOverlap) {
        items.add(_VeggieItem(
          position: position,
          size: iconSize,
          type: iconType,
          rotation: rotation,
          icon: _foodIcons[iconType],
        ));
      }

      // Stop when we have enough icons or running out of space
      if (items.length >= 45) break; // Increased target count
    }

    // Fill remaining empty areas with smaller icons
    _fillEmptySpaces(items, size, random);
  }

  // Fill remaining gaps with smaller icons
  void _fillEmptySpaces(List<_VeggieItem> items, Size size, math.Random random) {
    const int maxFillAttempts = 100;
    const double smallIconSize = 12.0;
    const double mediumIconSize = 20.0;
    
    for (int attempt = 0; attempt < maxFillAttempts; attempt++) {
      // Try to place smaller icons in gaps
      double iconSize = smallIconSize + random.nextDouble() * (mediumIconSize - smallIconSize);
      double x = iconSize + random.nextDouble() * (size.width - 2 * iconSize);
      double y = iconSize + random.nextDouble() * (size.height - 2 * iconSize);
      
      Offset position = Offset(x, y);

      // Check for overlaps
      bool hasOverlap = false;
      for (var existingItem in items) {
        double distance = (position - existingItem.position).distance;
        double minDistance = (iconSize + existingItem.size) / 2 + 2; // Tighter spacing for small icons
        
        if (distance < minDistance) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap && items.length < 60) { // Maximum total icons
        items.add(_VeggieItem(
          position: position,
          size: iconSize,
          type: random.nextInt(_foodIcons.length),
          rotation: random.nextDouble() * math.pi / 6 - math.pi / 12,
          icon: _foodIcons[random.nextInt(_foodIcons.length)],
        ));
      }
    }
  }

  void _drawThinOutlineIcon(Canvas canvas, IconData icon, Offset position, double size, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Adjust opacity based on size for visual hierarchy
    double opacity = 0.7 + (size / 42.0) * 0.3; // Larger icons slightly more opaque

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: veggieColor.withOpacity(opacity),
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );
    
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VeggieBackgroundPainter oldDelegate) {
    return oldDelegate.randomSeed != randomSeed;
  }
}

class _VeggiePainterController {
  final AnimationController _controller;
  late final Animation<double> animation;
  bool _disposed = false;

  _VeggiePainterController({
    required TickerProvider vsync,
    required Duration duration,
    Duration? delay,
  }) : _controller = AnimationController(vsync: vsync, duration: duration) {
    animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
    
    if (delay != null) {
      Future.delayed(delay, () {
        if (_disposed) return;
        _controller.repeat(reverse: true);
      });
    } else {
      _controller.repeat(reverse: true);
    }
  }

  void dispose() {
    _disposed = true;
    _controller.dispose();
  }
}
