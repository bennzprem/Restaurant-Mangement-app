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
    _controllers = List.generate(25, (index) {
      return _VeggiePainterController(
        vsync: this,
        delay: Duration(milliseconds: index * 150),
        duration: Duration(seconds: 5 + (index % 3)),
      );
    });
  }

  @override
  void didUpdateWidget(AnimatedVeggieBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Generate new random seed on widget update
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
          randomSeed: _randomSeed, // Pass the dynamic seed
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
  final int randomSeed; // Dynamic seed for random positioning

  _VeggieBackgroundPainter({
    required this.animations,
    required this.veggieColor,
    required this.randomSeed,
  }) : super(repaint: Listenable.merge(animations));

  // Food icons list
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
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final List<_VeggieItem> veggieItems = [];
    
    // Use the dynamic seed for completely random positioning
    final math.Random masterRandom = math.Random(randomSeed);
    
    // Generate completely random positions instead of grid-based
    const int totalIcons = 30; // Fixed number of icons
    
    for (int i = 0; i < totalIcons; i++) {
      // Completely random position across the entire canvas
      double x = masterRandom.nextDouble() * size.width;
      double y = masterRandom.nextDouble() * size.height;
      
      // Ensure icons don't go too close to edges
      x = math.max(30, math.min(size.width - 30, x));
      y = math.max(30, math.min(size.height - 30, y));
      
      // Random irregular sizes
      double itemSize = 18 + masterRandom.nextDouble() * 28; // 18-46px range
      
      // Random rotation
      double rotation = masterRandom.nextDouble() * math.pi / 2 - math.pi / 4;
      
      // Random icon selection
      int iconType = masterRandom.nextInt(_foodIcons.length);
      
      veggieItems.add(_VeggieItem(
        position: Offset(x, y),
        size: itemSize,
        type: iconType,
        rotation: rotation,
        icon: _foodIcons[iconType],
      ));
    }

    // Sort items by size so smaller icons don't get hidden behind larger ones
    veggieItems.sort((a, b) => b.size.compareTo(a.size));

    // Draw all food icons with animation
    for (int i = 0; i < veggieItems.length; i++) {
      final item = veggieItems[i];
      final int animationIndex = i % animations.length;
      final animation = animations[animationIndex];

      // Floating animation with different patterns for variety
      final double animPhase = (i % 4) * math.pi / 2; // Different phase for each icon
      final Offset animatedOffset = Offset(
        math.sin(animation.value * math.pi * 2 + animPhase) * 2.5,
        math.cos(animation.value * math.pi * 2 + animPhase) * 2.5,
      );

      final Offset finalPosition = item.position + animatedOffset;

      // Draw thin outline icon
      _drawThinOutlineIcon(canvas, item.icon, finalPosition, item.size, item.rotation);

      // Occasional decorative dots with random placement
      if (masterRandom.nextDouble() > 0.85) {
        final Paint dotPaint = Paint()
          ..color = veggieColor.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          finalPosition + Offset(
            (masterRandom.nextDouble() - 0.5) * item.size,
            (masterRandom.nextDouble() - 0.5) * item.size,
          ),
          0.8 + masterRandom.nextDouble() * 0.4,
          dotPaint,
        );
      }
    }
  }

  void _drawThinOutlineIcon(Canvas canvas, IconData icon, Offset position, double size, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Thin outlined appearance
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: veggieColor,
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
    // Repaint when the random seed changes (new positions)
    return oldDelegate.randomSeed != randomSeed;
  }
}

// Enhanced controller with position regeneration capability
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

// Optional: Add this method to your parent widget to trigger position changes
class RandomVeggieBackground extends StatefulWidget {
  final Widget child;
  
  const RandomVeggieBackground({
    super.key,
    required this.child,
  });

  @override
  State<RandomVeggieBackground> createState() => _RandomVeggieBackgroundState();
}

class _RandomVeggieBackgroundState extends State<RandomVeggieBackground> {
  final GlobalKey<_AnimatedVeggieBackgroundState> _backgroundKey = GlobalKey();

  void regeneratePositions() {
    // Force regeneration of positions
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedVeggieBackground(key: _backgroundKey),
        widget.child,
      ],
    );
  }
}
