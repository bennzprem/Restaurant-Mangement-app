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
  double pulsePhase; // For the pulsing animation
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
    this.glowIntensity = 1.0,
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
  late AnimationController _pulseController;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4), // Slightly slower pulse
      vsync: this,
    )..repeat(reverse: true);
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

      const int numberOfParticles = 20;
      for (int i = 0; i < numberOfParticles; i++) {
        _particles.add(_create3DBubble(size));
      }
      
      setState(() {}); // Trigger a repaint with the new particles.
    });
  }

  // Helper method to create 3D bubble particles
  Particle _create3DBubble(Size size) {
    return Particle(
      x: _random.nextDouble() * size.width,
      y: _random.nextDouble() * size.height,
      radius: _random.nextDouble() * 20 + 10, // Increased size: radius between 10 and 30
      speed: _random.nextDouble() * 0.7 + 0.3, // Speed between 0.3 and 1.0
      angle: _random.nextDouble() * 2 * pi, // Random direction.
      color: widget.particleColor,
      opacity: _random.nextDouble() * 0.5 + 0.3, // Opacity between 0.3 and 0.8
      pulsePhase: _random.nextDouble() * 2 * pi, // Random start for pulse animation
      glowIntensity: _random.nextDouble() * 0.6 + 0.4, // Glow between 0.4 and 1.0
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
            pulseAnimationValue: _pulseController.value,
            backgroundColor: widget.backgroundColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

// The CustomPainter that handles drawing the 3D bubbles.
class _BubblePainter extends CustomPainter {
  final List<Particle> particles;
  final double pulseAnimationValue;
  final Color backgroundColor;
  final Random _random = Random();

  _BubblePainter({
    required this.particles,
    required this.pulseAnimationValue,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (var particle in particles) {
      _draw3DBubble(canvas, particle, size);
    }
  }

  void _draw3DBubble(Canvas canvas, Particle particle, Size size) {
    // Update particle position for continuous motion
    particle.x += cos(particle.angle) * particle.speed;
    particle.y += sin(particle.angle) * particle.speed;

    // Wrap particles around the screen for a seamless loop
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

    // Calculate pulsing effect using the dedicated controller
    final pulseEffect = 1.0 + 0.15 * (sin(pulseAnimationValue * 2 * pi + particle.pulsePhase));
    final currentRadius = particle.radius * pulseEffect;
    final currentOpacity = particle.opacity * (0.8 + 0.2 * pulseEffect);

    final center = Offset(particle.x, particle.y);

    // Draw a soft outer glow
    final glowPaint = Paint()
      ..color = particle.color.withOpacity(currentOpacity * 0.1 * particle.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
    canvas.drawCircle(center, currentRadius * 1.5, glowPaint);

    // Draw the main bubble body with a gradient for a 3D effect
    final bubblePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.3), // Light source from top-left
        colors: [
          Colors.white.withOpacity(currentOpacity * 0.5),
          particle.color.withOpacity(currentOpacity),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));
    canvas.drawCircle(center, currentRadius, bubblePaint);

    // Draw a sharp highlight to complete the 3D look
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(currentOpacity * 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(particle.x - currentRadius * 0.4, particle.y - currentRadius * 0.4),
      currentRadius * 0.25,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

