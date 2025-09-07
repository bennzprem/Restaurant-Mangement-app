import 'dart:math';
import 'package:flutter/material.dart';

// A model class to hold information about each wave.
class Wave {
  final double amplitude; // How high the wave is
  final double frequency; // How compressed the wave is
  final double speed;     // How fast the wave moves horizontally
  final double yOffset;   // Vertical position of the wave
  final Color color;
  final double opacity;

  Wave({
    required this.amplitude,
    required this.frequency,
    required this.speed,
    required this.yOffset,
    required this.color,
    required this.opacity,
  });
}

// The main widget that will display the animated background.
class LoginAnimatedBackground extends StatefulWidget {
  final Color waveColor;
  final Color backgroundColor;

  const LoginAnimatedBackground({
    super.key,
    required this.waveColor,
    required this.backgroundColor,
  });

  @override
  _LoginAnimatedBackgroundState createState() => _LoginAnimatedBackgroundState();
}

class _LoginAnimatedBackgroundState extends State<LoginAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Wave> _waves = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 40), // Much slower animation for calmer effect
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize waves once we have the context to get the size.
    if (_waves.isEmpty) {
      _initializeWaves();
    }
  }

  void _initializeWaves() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size;
      if (size == null) return;

      // Create multiple waves with different properties for a layered parallax effect.
      const int numberOfWaves = 4;
      for (int i = 0; i < numberOfWaves; i++) {
        _waves.add(
          Wave(
            amplitude: _random.nextDouble() * 20 + 10, // Amplitude from 10 to 30
            frequency: _random.nextDouble() * 0.02 + 0.01, // Low frequency for wide waves
            speed: _random.nextDouble() * 0.3 + 0.2, // Much slower speed from 0.2 to 0.5
            yOffset: size.height * (0.4 + (i * 0.15)), // Stagger waves vertically
            color: widget.waveColor,
            opacity: _random.nextDouble() * 0.2 + 0.1, // Very subtle opacity
          ),
        );
      }
      
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            waves: _waves,
            animationValue: _controller.value,
            backgroundColor: widget.backgroundColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

// The CustomPainter that handles drawing the flowing waves.
class _WavePainter extends CustomPainter {
  final List<Wave> waves;
  final double animationValue;
  final Color backgroundColor;

  _WavePainter({
    required this.waves,
    required this.animationValue,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (var wave in waves) {
      final wavePaint = Paint()
        ..color = wave.color.withOpacity(wave.opacity)
        ..style = PaintingStyle.fill;
      
      final path = Path();
      path.moveTo(0, size.height); // Start at bottom-left

      // The animationValue and wave.speed create the horizontal movement.
      final horizontalOffset = animationValue * size.width * wave.speed;

      for (double x = 0; x <= size.width; x++) {
        // Calculate y using a sine function for the wave shape.
        final y = wave.yOffset + sin((x * wave.frequency) + horizontalOffset) * wave.amplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height); // Line to bottom-right
      path.close(); // Close the path to form a fillable shape

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint on every frame for animation
  }
}
