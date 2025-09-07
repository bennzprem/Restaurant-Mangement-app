import 'dart:math';
import 'package:flutter/material.dart';

// A model class to hold information about each particle.
class Particle {
  double x;
  double y;
  double radius;
  double speed;
  double angle;
  Color color;
  double opacity;
  double pulsePhase;
  double rotationSpeed;
  double glowIntensity;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.angle,
    required this.color,
    this.opacity = 1.0,
    this.pulsePhase = 0.0,
    this.rotationSpeed = 0.0,
    this.glowIntensity = 1.0,
  });
}

// A model class for floating geometric shapes
class FloatingShape {
  double x;
  double y;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  double opacity;
  String shapeType; // 'circle', 'triangle', 'square', 'hexagon'

  FloatingShape({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.opacity,
    required this.shapeType,
  });
}

// The main widget that will display the animated background.
class AnimatedBackground extends StatefulWidget {
  final Color particleColor;
  final Color backgroundColor;

  const AnimatedBackground({
    super.key,
    required this.particleColor,
    required this.backgroundColor,
  });

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _shapeController;
  late AnimationController _pulseController;
  final List<Particle> _particles = [];
  final List<FloatingShape> _shapes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize particles once we have the context to get the size.
    if (_particles.isEmpty) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    // Wait for the layout to be built to get the size.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size == null) return;

      // Create only 3D bubble particles
      const int numberOfParticles = 20;
      for (int i = 0; i < numberOfParticles; i++) {
        _particles.add(_create3DBubble(size));
      }
      
      setState(() {}); // Trigger a repaint with the new particles and shapes.
    });
  }

  // Helper method to create 3D bubble particles with continuous motion
  Particle _create3DBubble(Size size) {
    return Particle(
      x: _random.nextDouble() * size.width,
      y: _random.nextDouble() * size.height,
      radius: _random.nextDouble() * 15 + 8, // Radius between 8 and 23 (much bigger)
      speed: _random.nextDouble() * 0.8 + 0.3, // Speed between 0.3 and 1.1 (smooth)
      angle: _random.nextDouble() * 2 * pi, // Random direction.
      color: widget.particleColor,
      opacity: _random.nextDouble() * 0.6 + 0.4, // Opacity between 0.4 and 1.0 (brighter)
      pulsePhase: _random.nextDouble() * 2 * pi, // Random pulse phase
      rotationSpeed: _random.nextDouble() * 0.08 + 0.02, // Smooth rotation
      glowIntensity: _random.nextDouble() * 0.7 + 0.3, // Strong glow
    );
  }

  // Helper method to create 3D floating shapes
  FloatingShape _create3DFloatingShape(Size size) {
    final shapeTypes = ['circle', 'triangle', 'square', 'hexagon'];
    return FloatingShape(
      x: _random.nextDouble() * size.width,
      y: _random.nextDouble() * size.height,
      size: _random.nextDouble() * 80 + 40, // Size between 40 and 120 (bigger)
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: _random.nextDouble() * 0.03 + 0.01, // Very slow rotation
      color: widget.particleColor,
      opacity: _random.nextDouble() * 0.3 + 0.1, // Subtle opacity
      shapeType: shapeTypes[_random.nextInt(shapeTypes.length)],
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblePainter(
            particles: _particles,
            particleAnimationValue: _particleController.value,
            pulseAnimationValue: _pulseController.value,
            backgroundColor: widget.backgroundColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

// The simplified CustomPainter that handles only 3D bubbles
class _BubblePainter extends CustomPainter {
  final List<Particle> particles;
  final double particleAnimationValue;
  final double pulseAnimationValue;
  final Color backgroundColor;
  final Random _random = Random();

  _BubblePainter({
    required this.particles,
    required this.particleAnimationValue,
    required this.pulseAnimationValue,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background with gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          backgroundColor,
          backgroundColor.withOpacity(0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw only 3D bubbles
    for (var particle in particles) {
      _draw3DBubble(canvas, particle, size);
    }
  }

  void _draw3DBubble(Canvas canvas, Particle particle, Size size) {
    // Update particle position continuously
    particle.x += cos(particle.angle) * particle.speed;
    particle.y += sin(particle.angle) * particle.speed;

    // Wrap particles around screen seamlessly
    if (particle.x < -particle.radius) {
      particle.x = size.width + particle.radius;
      particle.y = _random.nextDouble() * size.height;
    } else if (particle.x > size.width + particle.radius) {
      particle.x = -particle.radius;
      particle.y = _random.nextDouble() * size.height;
    }
    if (particle.y < -particle.radius) {
      particle.y = size.height + particle.radius;
      particle.x = _random.nextDouble() * size.width;
    } else if (particle.y > size.height + particle.radius) {
      particle.y = -particle.radius;
      particle.x = _random.nextDouble() * size.width;
    }

    // Calculate continuous pulsing effect
    final pulseEffect = 1.0 + 0.3 * sin(pulseAnimationValue * 2 * pi + particle.pulsePhase);
    final currentRadius = particle.radius * pulseEffect;
    final currentOpacity = particle.opacity * (0.8 + 0.2 * pulseEffect);

    final center = Offset(particle.x, particle.y);

    // Draw outer glow
    final outerGlowPaint = Paint()
      ..color = particle.color.withOpacity(currentOpacity * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, currentRadius * 2.5, outerGlowPaint);

    // Draw inner glow
    final innerGlowPaint = Paint()
      ..color = particle.color.withOpacity(currentOpacity * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(center, currentRadius * 1.8, innerGlowPaint);

    // Draw main 3D bubble
    final bubblePaint = Paint()
      ..color = particle.color.withOpacity(currentOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentRadius, bubblePaint);

    // Draw 3D highlight (top-left)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(currentOpacity * 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(particle.x - currentRadius * 0.3, particle.y - currentRadius * 0.3),
      currentRadius * 0.4,
      highlightPaint,
    );

    // Draw secondary highlight (smaller, more subtle)
    final secondaryHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(currentOpacity * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(particle.x - currentRadius * 0.1, particle.y - currentRadius * 0.1),
      currentRadius * 0.2,
      secondaryHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
