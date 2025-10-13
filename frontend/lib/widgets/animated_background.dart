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

  @override
  void initState() {
    super.initState();
    // Reduced from 40 to 25 controllers
    _controllers = List.generate(25, (index) {
      return _VeggiePainterController(
        vsync: this,
        delay: Duration(milliseconds: index * 150), // Slightly longer delay
        duration: Duration(seconds: 5 + (index % 3)),
      );
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
    
    // Same theme adaptation as original
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

  _VeggieBackgroundPainter({
    required this.animations,
    required this.veggieColor,
  }) : super(repaint: Listenable.merge(animations));

  // Reduced and optimized food icons list
  final List<IconData> _foodIcons = [
    Icons.restaurant_outlined,        // Outlined version
    Icons.local_pizza_outlined,      // Pizza outline
    Icons.lunch_dining_outlined,     // Lunch box outline
    Icons.dinner_dining_outlined,    // Dinner plate outline
    Icons.coffee_outlined,           // Coffee outline
    Icons.local_cafe_outlined,       // Cafe outline
    Icons.cake_outlined,             // Cake outline
    Icons.fastfood_outlined,         // Fast food outline
    Icons.ramen_dining_outlined,     // Ramen outline
    Icons.rice_bowl_outlined,        // Rice bowl outline
    Icons.icecream_outlined,         // Ice cream outline
    Icons.emoji_food_beverage_outlined, // Food & beverage outline
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final List<_VeggieItem> veggieItems = [];
    
    // Reduced grid density - fewer items per row/column
    const int itemsPerRow = 8;  // Reduced from 12
    const int itemsPerCol = 6;  // Reduced from 10
    final double cellWidth = size.width / itemsPerRow;
    final double cellHeight = size.height / itemsPerCol;

    // Generate fewer items with more spacing
    for (int row = -1; row <= itemsPerCol; row++) {
      for (int col = -1; col <= itemsPerRow; col++) {
        int seed = row * itemsPerRow + col;
        final math.Random random = math.Random(seed);
        
        // Skip some items randomly to reduce density further
        if (random.nextDouble() < 0.3) continue; // Skip 30% of potential positions
        
        // Larger random offset for more irregular positioning
        double xOffset = random.nextDouble() * cellWidth * 0.8 - cellWidth * 0.4;
        double yOffset = random.nextDouble() * cellHeight * 0.8 - cellHeight * 0.4;
        
        double x = col * cellWidth + cellWidth / 2 + xOffset;
        double y = row * cellHeight + cellHeight / 2 + yOffset;
        
        // More varied irregular sizes (20-45px range)
        double itemSize = 20 + random.nextDouble() * 25;
        
        // Random rotation
        double rotation = random.nextDouble() * math.pi / 3 - math.pi / 6;
        
        // Select food icon type
        int iconType = random.nextInt(_foodIcons.length);
        
        veggieItems.add(_VeggieItem(
          position: Offset(x, y),
          size: itemSize,
          type: iconType,
          rotation: rotation,
          icon: _foodIcons[iconType],
        ));
      }
    }

    // Draw all food icons with thin outline style
    for (var item in veggieItems) {
      final int animationIndex = item.position.dx.toInt() % animations.length;
      final animation = animations[animationIndex];

      // Same floating animation
      final Offset animatedOffset = Offset(
        math.sin(animation.value * math.pi * 2) * 2,
        math.cos(animation.value * math.pi * 2) * 2,
      );

      final Offset finalPosition = item.position + animatedOffset;

      // Draw thin outline icon
      _drawThinOutlineIcon(canvas, item.icon, finalPosition, item.size, item.rotation);

      // Reduced decorative dots (less frequent)
      final math.Random dotRandom = math.Random(item.position.dx.toInt() + item.position.dy.toInt());
      if (dotRandom.nextDouble() > 0.85) { // More selective dots
        final Paint dotPaint = Paint()
          ..color = veggieColor.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          finalPosition + Offset(item.size * 0.7, -item.size * 0.4),
          1.0, // Smaller dots
          dotPaint,
        );
      }
    }
  }

  void _drawThinOutlineIcon(Canvas canvas, IconData icon, Offset position, double size, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Create text painter with thin weight for outlined appearance
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: veggieColor,
          fontWeight: FontWeight.w300, // Thin weight
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Center the icon
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );
    
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VeggieBackgroundPainter oldDelegate) => true;
}

// Same controller as before
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
