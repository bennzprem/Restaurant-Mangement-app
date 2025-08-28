import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';
import '../theme_provider.dart';
import '../auth_provider.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  child: Row(
                    children: [
                      // Logo
                      Icon(Icons.restaurant_menu_rounded,
                          color: Color(0xFFDAE952), size: 28),
                      const SizedBox(width: 14),
                      Text(
                        'Byte Eat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.85,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Spacer(),

                      // Admin Button (only visible to admin users)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.isAdmin) {
                            return Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/admin_dashboard');
                                },
                                icon: const Icon(Icons.admin_panel_settings,
                                    size: 18),
                                label: const Text('Admin'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Theme Toggle Button
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Container(
                            margin: const EdgeInsets.only(right: 16),
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
                          );
                        },
                      ),

                      // Authentication Buttons
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.isLoggedIn) {
                            // User is logged in - show profile/logout
                            return Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDAE952),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                                Text(
                                  authProvider.user?.name ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    authProvider.signOut();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // User is not logged in - show login and sign up buttons
                            return Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                    side: BorderSide(
                                      color: const Color(0xFFDAE952),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDAE952),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
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
