import 'dart:math';
import 'package:flutter/material.dart';

// --- Food Emojis ---
// An expanded and curated list for a clean and appealing visual.
const List<String> _foodEmojis = [
  // Savory
  '🍕', '🍔', '🍟', '🌭', '🍿', '🥓', '🍳', '🧇', '🥞', '🍞', '🥐', '🥨',
  '🥯', '🥖', '🧀', '🥗', '🥙', '🥪', '🌮', '🌯', '🍱', '🍙', '🍚', '🍛',
  '🍜', '🍝', '🍣', '🍤', '🥟', '🥡',
  // Sweet
  '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', '🍫', '🍬', '🍭',
  '🍮', '🍯',
  // Drinks
  '☕️', '🍵', '🥤', '🧋', '🍷', '🍸', '🍹', '🍺', '🍻',
  // Fruits & Veggies
  '🍇', '🍉', '🍊', '🍋', '🍌', '🍍', '🥭', '🍎', '🍏', '🍐', '🍑', '🍒',
  '🍓', '🥝', '🥥', '🥑', '🍆', '🌽', '🌶️', '🥬', '🥦', '🍄', '🧅',
];

// --- Theme Palette ---
// Using your app's green for a subtle, cohesive glow effect.
const Color _themeColor = Color(0xFFB2D871);

// --- Particle Model ---
// Each emoji is a particle with its own physics properties.
class FoodParticle {
  final String emoji;
  Offset position;
  Offset velocity;
  final double depth; // For the parallax effect (0.0 deep to 1.0 close)
  double targetSize;
  double currentSize;
  double rotation;
  final double rotationSpeed;

  FoodParticle({
    required this.emoji,
    required this.position,
    required this.velocity,
    required this.depth,
    required this.rotation,
    required this.rotationSpeed,
  })  : targetSize = 20 + depth * 30,
        currentSize = 0.0; // Start at 0 for a smooth "pop-in" effect
}

// The main widget that displays the animated background.
class AnimatedBackground extends StatefulWidget {
  final Color backgroundColor;
  final Color? particleColor; // Kept for compatibility

  const AnimatedBackground({
    super.key,
    required this.backgroundColor,
    this.particleColor,
  });

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FoodParticle> _particles = [];
  final Random _random = Random();
  Offset _pointerPosition = Offset.infinite; // Use infinite to signify no pointer
  Size? _size;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 16), // Target 60fps
      vsync: this,
    )..addListener(_updateAnimation);
  }

  void _initialize(Size size) {
    _size = size;
    const particleCount = 40; // Increased particle count
    for (int i = 0; i < particleCount; i++) {
      _particles.add(_createParticle(size, isInitial: true));
    }
    _controller.repeat();
    _isInitialized = true;
  }

  void _updateAnimation() {
    if (!_isInitialized || !mounted) return;

    const double interactionRadius = 80.0;
    const double repulsionForce = 1.5;
    const double friction = 0.98; // Reduced friction for smoother, longer drifts

    setState(() {
      for (int i = 0; i < _particles.length; i++) {
        var particle = _particles[i];

        // --- Gentle Swirling Motion ---
        final swirl = Offset(
          sin(particle.position.dy * 0.005 + particle.depth * pi) * 0.07,
          cos(particle.position.dx * 0.005 + particle.depth * pi) * 0.07,
        );
        particle.velocity += swirl;

        // --- Interaction Logic ---
        if (_pointerPosition.isFinite) {
          final distance = (particle.position - _pointerPosition).distance;
          if (distance < interactionRadius) {
            final vector = particle.position - _pointerPosition;
            final force = repulsionForce * (1 - distance / interactionRadius);
            particle.velocity += vector.scale(force, force);
          }
        }
        
        // --- Physics Update ---
        particle.velocity *= friction;
        particle.position += particle.velocity;
        particle.rotation += particle.rotationSpeed;

        // --- Smooth Size Transition ---
        particle.currentSize += (particle.targetSize - particle.currentSize) * 0.1;

        // --- Reset Logic ---
        // If a particle goes too far off-screen, replace it with a new one.
        if (particle.position.dx < -50 ||
            particle.position.dx > _size!.width + 50 ||
            particle.position.dy < -50 ||
            particle.position.dy > _size!.height + 50) {
          _particles[i] = _createParticle(_size!);
        }
      }
    });
  }

  FoodParticle _createParticle(Size size, {bool isInitial = false}) {
    final depth = _random.nextDouble();
    Offset position;

    if (isInitial) {
      // Start initial particles anywhere on screen
      position = Offset(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
      );
    } else {
      // Create new particles just off-screen to drift in
      final edge = _random.nextInt(4);
      switch (edge) {
        case 0: // Top
          position = Offset(_random.nextDouble() * size.width, -50);
          break;
        case 1: // Right
          position = Offset(size.width + 50, _random.nextDouble() * size.height);
          break;
        case 2: // Bottom
          position = Offset(_random.nextDouble() * size.width, size.height + 50);
          break;
        default: // Left
          position = Offset(-50, _random.nextDouble() * size.height);
          break;
      }
    }

    return FoodParticle(
      emoji: _foodEmojis[_random.nextInt(_foodEmojis.length)],
      position: position,
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.5,
        (_random.nextDouble() - 0.5) * 0.5,
      ),
      depth: depth,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.01,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!_isInitialized) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width > 0 && size.height > 0) {
          _initialize(size);
        }
      }

      return MouseRegion(
        onHover: (event) => setState(() => _pointerPosition = event.localPosition),
        onExit: (event) => setState(() => _pointerPosition = Offset.infinite),
        child: GestureDetector(
          onPanUpdate: (details) => setState(() => _pointerPosition = details.localPosition),
          onPanEnd: (details) => setState(() => _pointerPosition = Offset.infinite),
          child: CustomPaint(
            painter: _EmojiPainter(
              particles: _particles,
              backgroundColor: widget.backgroundColor,
            ),
            child: Container(),
          ),
        ),
      );
    });
  }
}

class _EmojiPainter extends CustomPainter {
  final List<FoodParticle> particles;
  final Color backgroundColor;

  _EmojiPainter({required this.particles, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = backgroundColor);

    // Sort particles by depth to draw farther ones first
    particles.sort((a, b) => a.depth.compareTo(b.depth));
    
    for (final particle in particles) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.emoji,
          style: TextStyle(
            fontSize: particle.currentSize,
            shadows: [
              Shadow(
                color: _themeColor.withOpacity(0.5 * particle.depth),
                blurRadius: 10.0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      textPainter.paint(canvas, -Offset(textPainter.width / 2, textPainter.height / 2));
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiPainter oldDelegate) {
    // The animation controller handles repainting.
    return true;
  }
}

