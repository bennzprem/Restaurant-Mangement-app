import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../ch/user_dashboard_page.dart';
import 'dart:ui';
import 'dart:math';
import 'package:video_player/video_player.dart';
import '../theme.dart';
import '../voice_overlay.dart';
enum HeaderActive { none, home, menu, about, contact, login, signup }

class HeaderWidget extends StatelessWidget {
  final HeaderActive active;
  final bool showBack;
  final VoidCallback? onBack;
  const HeaderWidget({
    super.key,
    this.active = HeaderActive.none,
    this.showBack = false,
    this.onBack,
  });
  void _showVoiceOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Interaction',
      pageBuilder: (context, animation, secondaryAnimation) {
        return const VoiceInteractionOverlay();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), // glassmorphism
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Stack(
              children: [
                Positioned.fill(
                    child: _ModernAnimatedBackdrop(
                        isDark: themeProvider.isDarkMode)),
                Container(
                  decoration: BoxDecoration(
                    gradient: themeProvider.isDarkMode
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF000000), Color(0xFF000000)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border(
                      bottom: BorderSide(
                        color: themeProvider.isDarkMode
                            ? Colors.white12
                            : Colors.black12,
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.of(context).size.width < 700 ? 16 : 36,
                      vertical: 14),
                  child: Stack(
                    children: [
                      // Left side - Logo and Brand
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                  child: Row(
                    children: [
                      if (showBack)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                print('🔙 Back button tapped!'); // Debug print
                                try {
                                  if (onBack != null) {
                                    print('🔙 Using custom onBack callback');
                                    onBack!();
                                  } else {
                                    print('🔙 Using default Navigator.pop');
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  print('❌ Back button error: $e');
                                  // Fallback navigation
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Logo (MP4 animation)
                            const _LogoVideo(width: 62, height: 60, scale: 1.6),
                            const SizedBox(width: 10),
                      Text(
                        'ByteEat',
                        style: TextStyle(
                          fontFamily: 'StoryScript',
                          fontSize:
                                    MediaQuery.of(context).size.width < 700 ? 20 : 30,
                          fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontVariations: const [
                            FontVariation('ital', 0),
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                          ],
                        ),
                      ),

                      // Center - Navigation Bar Overlay
                      Center(
                        child: _AnimatedNavBackground(
                          isDark: themeProvider.isDarkMode,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavButton(
                                label: 'Home',
                                isActive: active == HeaderActive.home,
                                isDark: themeProvider.isDarkMode,
                                onPressed: () => Navigator.pushNamed(context, '/'),
                              ),
                              const SizedBox(width: 24),
                              _NavButton(
                                label: 'Menu',
                                isActive: active == HeaderActive.menu,
                                isDark: themeProvider.isDarkMode,
                                onPressed: () => Navigator.pushNamed(context, '/menu'),
                              ),
                              const SizedBox(width: 24),
                              _NavButton(
                                label: 'About',
                                isActive: active == HeaderActive.about,
                                isDark: themeProvider.isDarkMode,
                                onPressed: () => Navigator.pushNamed(context, '/about'),
                              ),
                              const SizedBox(width: 24),
                              _NavButton(
                                label: 'Contact',
                                isActive: active == HeaderActive.contact,
                                isDark: themeProvider.isDarkMode,
                                onPressed: () => Navigator.pushNamed(context, '/contact'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right side - Theme Toggle + Profile
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // New ByteBot Voice Button
                            Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFDAE952),
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: () => _showVoiceOverlay(context),
              icon: const Icon(
                Icons.android, // Using a bot icon
                color: Color(0xFFDAE952),
                size: 20,
              ),
              tooltip: 'Talk to ByteBot',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
                            // Theme toggle
                            Container(
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFDAE952),
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                              icon: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: const Color(0xFFDAE952),
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                      ),
                            const SizedBox(width: 8),
                            // Profile icon (only when logged in)
                      Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                if (!auth.isLoggedIn) return const SizedBox.shrink();
                                return Container(
                                    decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFDAE952),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                  onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const UserDashboardPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFDAE952),
                                      size: 20,
                                    ),
                                  ),
            );
          },
        ),
                          ],
                        ),
              ),
            ],
          ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModernAnimatedBackdrop extends StatefulWidget {
  final bool isDark;
  const _ModernAnimatedBackdrop({required this.isDark});

  @override
  State<_ModernAnimatedBackdrop> createState() =>
      _ModernAnimatedBackdropState();
}

class _ModernAnimatedBackdropState extends State<_ModernAnimatedBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _particleController;
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _particleController.dispose();
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveController,
        _particleController,
        _sweepController,
        _pulseController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _ModernHeaderPainter(
            waveProgress: _waveController.value,
            particleProgress: _particleController.value,
            sweepProgress: _sweepController.value,
            pulseProgress: _pulseController.value,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _ModernHeaderPainter extends CustomPainter {
  final double waveProgress;
  final double particleProgress;
  final double sweepProgress;
  final double pulseProgress;
  final bool isDark;

  _ModernHeaderPainter({
    required this.waveProgress,
    required this.particleProgress,
    required this.sweepProgress,
    required this.pulseProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Color accent = const Color(0xFFDAE952);
    final Color accent2 = const Color(0xFF4CAF50);
    final Color subtle = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    // Dynamic wave patterns
    _drawWaves(canvas, size, accent, accent2);

    // Floating particles
    _drawParticles(canvas, size, accent);

    // Diagonal sweep effect
    _drawDiagonalSweep(canvas, size, accent, accent2);

    // Pulsing radial glow
    _drawPulsingGlow(canvas, size, accent, subtle);

    // Geometric accent lines
    _drawGeometricAccents(canvas, size, accent, accent2);
  }

  void _drawWaves(Canvas canvas, Size size, Color accent, Color accent2) {
    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Primary wave
    final Path wave1 = Path();
    wave1.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 5) {
      final double y = size.height * 0.7 +
          sin((x / size.width * 4 * pi) + (waveProgress * 2 * pi)) * 15 +
          sin((x / size.width * 8 * pi) + (waveProgress * 4 * pi)) * 8;
      wave1.lineTo(x, y);
    }

    wavePaint.shader = LinearGradient(
      colors: [
        accent.withOpacity(0.6),
        accent2.withOpacity(0.4),
        accent.withOpacity(0.6)
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wave1, wavePaint);

    // Secondary wave
    final Path wave2 = Path();
    wave2.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 5) {
      final double y = size.height * 0.8 +
          sin((x / size.width * 3 * pi) - (waveProgress * 3 * pi)) * 12 +
          cos((x / size.width * 6 * pi) + (waveProgress * 2 * pi)) * 6;
      wave2.lineTo(x, y);
    }

    wavePaint.shader = LinearGradient(
      colors: [
        accent2.withOpacity(0.4),
        accent.withOpacity(0.3),
        accent2.withOpacity(0.4)
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wave2, wavePaint);
  }

  void _drawParticles(Canvas canvas, Size size, Color accent) {
    final Paint particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 8; i++) {
      final double angle = (i / 8) * 2 * pi + (particleProgress * 2 * pi);
      final double radius = 20 + sin(particleProgress * 4 * pi + i) * 10;
      final double x = size.width * 0.5 + cos(angle) * radius;
      final double y = size.height * 0.5 + sin(angle) * radius;

      final double opacity = 0.3 + 0.4 * sin(particleProgress * 3 * pi + i);
      particlePaint.color = accent.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), 2 + opacity * 3, particlePaint);
    }
  }

  void _drawDiagonalSweep(
      Canvas canvas, Size size, Color accent, Color accent2) {
    final Paint sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final double sweepWidth = size.width * 0.3;
    final double sweepHeight = size.height * 0.8;

    final Path sweepPath = Path();
    sweepPath.moveTo(
        size.width * 0.5 + (sweepProgress - 0.5) * size.width * 0.8,
        size.height * 0.1);
    sweepPath.lineTo(
        size.width * 0.5 +
            (sweepProgress - 0.5) * size.width * 0.8 +
            sweepWidth,
        size.height * 0.1);
    sweepPath.lineTo(
        size.width * 0.5 +
            (sweepProgress - 0.5) * size.width * 0.8 +
            sweepWidth +
            50,
        size.height * 0.9);
    sweepPath.lineTo(
        size.width * 0.5 + (sweepProgress - 0.5) * size.width * 0.8 + 50,
        size.height * 0.9);
    sweepPath.close();

    sweepPaint.shader = LinearGradient(
      colors: [
        accent.withOpacity(0.15),
        accent2.withOpacity(0.25),
        accent.withOpacity(0.15),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(sweepPath, sweepPaint);
  }

  void _drawPulsingGlow(Canvas canvas, Size size, Color accent, Color subtle) {
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    // Left glow
    final double leftGlowRadius = 60 + 20 * sin(pulseProgress * pi);
    glowPaint.shader = RadialGradient(
      colors: [accent.withOpacity(0.2), Colors.transparent],
      stops: [0.0, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.3),
      radius: leftGlowRadius,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      leftGlowRadius,
      glowPaint,
    );

    // Right glow
    final double rightGlowRadius = 50 + 15 * cos(pulseProgress * pi);
    glowPaint.shader = RadialGradient(
      colors: [accent.withOpacity(0.15), Colors.transparent],
      stops: [0.0, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.7),
      radius: rightGlowRadius,
    ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      rightGlowRadius,
      glowPaint,
    );
  }

  void _drawGeometricAccents(
      Canvas canvas, Size size, Color accent, Color accent2) {
    final Paint accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Top-left accent lines
    accentPaint.color = accent.withOpacity(0.4);
    canvas.drawLine(
      Offset(20, 20),
      Offset(80, 20),
      accentPaint,
    );
    canvas.drawLine(
      Offset(20, 20),
      Offset(20, 80),
      accentPaint,
    );

    // Bottom-right accent lines
    accentPaint.color = accent2.withOpacity(0.4);
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 80, size.height - 20),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20, size.height - 80),
      accentPaint,
    );

    // Floating accent dots
    accentPaint.style = PaintingStyle.fill;
    accentPaint.color = accent.withOpacity(0.3);

    final List<Offset> accentDots = [
      Offset(size.width * 0.15, size.height * 0.6),
      Offset(size.width * 0.85, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.85),
      Offset(size.width * 0.7, size.height * 0.15),
    ];

    for (int i = 0; i < accentDots.length; i++) {
      final double pulse = sin(pulseProgress * 2 * pi + i) * 0.5 + 0.5;
      canvas.drawCircle(accentDots[i], 3 * pulse, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ModernHeaderPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.particleProgress != particleProgress ||
        oldDelegate.sweepProgress != sweepProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isDark != isDark;
  }
}

class _AnimatedNavBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  const _AnimatedNavBackground({required this.child, required this.isDark});

  @override
  State<_AnimatedNavBackground> createState() => _AnimatedNavBackgroundState();
}

class _AnimatedNavBackgroundState extends State<_AnimatedNavBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _tween = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep original palette; only move their positions across the bar.
    const List<Color> baseColors = [
      Color(0xFFDAE952), // same lime
      Color(0xFFB8D43A),
      Color(0xFF9BC53D),
      Color(0xFF7FB139),
    ];

    return AnimatedBuilder(
      animation: _tween,
      builder: (context, child) {
        // Smooth gradient using many samples strictly between the four palette colors.
        final double t = _tween.value; // 0..1..0 loop

        // Order A: darkest -> lightest, Order B: lightest -> darkest
        const List<Color> orderA = [
          Color(0xFF7FB139),
          Color(0xFF9BC53D),
          Color(0xFFB8D43A),
          Color(0xFFDAE952),
        ];
        const List<Color> orderB = [
          Color(0xFFDAE952),
          Color(0xFFB8D43A),
          Color(0xFF9BC53D),
          Color(0xFF7FB139),
        ];

        Color sampleColor(double u, List<Color> seq) {
          final int segments = seq.length - 1;
          final double pos = (u * segments).clamp(0.0, segments.toDouble());
          final int i = pos.floor().clamp(0, segments - 1);
          final double f = pos - i;
          return Color.lerp(seq[i], seq[i + 1], f)!;
        }

        // Create many stops for a seamless blend
        const int samples = 24;
        final List<double> stops =
            List<double>.generate(samples, (k) => k / (samples - 1));
        final List<Color> animatedColors = stops
            .map((u) => Color.lerp(
                  sampleColor(u, orderA),
                  sampleColor(u, orderB),
                  t,
                )!)
            .toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: animatedColors,
              stops: stops,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              bottomLeft: Radius.circular(50),
              topRight: Radius.circular(50),
              bottomRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDAE952).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _underlineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _underlineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: themeProvider.isDarkMode
                          ? (widget.isActive 
                              ? Colors.white
                              : isHovered 
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7))
                          : (widget.isActive 
                              ? Colors.black
                              : isHovered 
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.7)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              AnimatedBuilder(
                animation: _underlineAnimation,
                builder: (context, child) {
                  return Container(
                    height: 2,
                    width: widget.label.length * 8.0 * _underlineAnimation.value,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onPressed;
  const _AuthButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = const Color(0xFFDAE952);
    final bool filled = isActive;
    final Color background = filled
        ? green
        : (isDark ? Colors.black : Colors.white);
    final Color textColor = filled
        ? Colors.black
        : (isDark ? Colors.white : Colors.black);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        side: BorderSide(color: green, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _LogoVideo extends StatefulWidget {
  final double width;
  final double height;
  final double scale; // zoom-in to crop any letterboxing
  const _LogoVideo({required this.width, required this.height, this.scale = 1.8});

  @override
  State<_LogoVideo> createState() => _LogoVideoState();
}

class _LogoVideoState extends State<_LogoVideo> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/logo/logoLV.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (mounted) {
          _controller.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Transform.scale(
            scale: widget.scale,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );
  }
}