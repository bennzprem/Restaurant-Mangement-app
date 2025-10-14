import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  // Navigation links from your original file
  static const _navLinks = [
    _FooterLink(label: 'Home', route: '/'),
    _FooterLink(label: 'Menu', route: '/menu'),
    _FooterLink(label: 'About', route: '/about'),
    _FooterLink(label: 'Contact', route: '/contact'),
  ];

  // Social links for the new design
  static const _socialLinks = [
    _SocialLink(icon: FontAwesomeIcons.facebookF, url: '#'),
    _SocialLink(icon: FontAwesomeIcons.instagram, url: '#'),
    _SocialLink(icon: FontAwesomeIcons.twitter, url: '#'),
    _SocialLink(icon: FontAwesomeIcons.linkedinIn, url: '#'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final bool isDark = theme.isDarkMode;
        // Using theme-based green colors as requested
        final Color footerColor = isDark ? const Color(0xFF1E4620) : const Color(0xFF4CAF50);
        final Color textColor = Colors.white;
        final Color textMutedColor = Colors.white.withOpacity(0.75);

        return Container(
          color: footerColor,
          child: Stack(
            children: [
              // The animated waves are now drawn directly
              _AnimatedWave(color: Colors.black.withOpacity(0.08), duration: const Duration(milliseconds: 5000)),
              _AnimatedWave(color: Colors.black.withOpacity(0.1), duration: const Duration(milliseconds: 4000), offset: 0.5),
              _AnimatedWave(color: Colors.black.withOpacity(0.12), duration: const Duration(milliseconds: 3000), offset: 0.8),
              
              // The main footer content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), // Padding to clear the waves
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Social Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _socialLinks.map((link) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: IconButton(
                            icon: FaIcon(link.icon, color: textColor, size: 24),
                            onPressed: () { /* Handle URL launch if needed */ },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    
                    // Navigation Menu
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 25,
                      runSpacing: 10,
                      children: _navLinks.map((link) {
                        return InkWell(
                          onTap: () => Navigator.pushNamed(context, link.route),
                          child: Text(
                            link.label,
                            style: TextStyle(
                              color: textMutedColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    
                    // Copyright Text
                    Text(
                      '© 2024 ByteEat | All Rights Reserved',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// A new stateful widget to create the looping wave animation
class _AnimatedWave extends StatefulWidget {
  final Color color;
  final Duration duration;
  final double offset;

  const _AnimatedWave({required this.color, required this.duration, this.offset = 0.0});

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // Apply the initial offset and start the looping animation
    _controller.value = widget.offset;
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: 0,
      child: ClipPath(
        clipper: _WaveClipper(animationValue: _animation.value),
        child: Container(color: widget.color),
      ),
    );
  }
}

// A custom clipper to draw the wave shape using a sine curve
class _WaveClipper extends CustomClipper<Path> {
  final double animationValue;

  _WaveClipper({required this.animationValue});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Move to the bottom left corner to start drawing
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    // Move to the top right to start the wave
    path.lineTo(size.width, 80);

    // Draw the sine wave across the top
    for (double i = size.width; i >= 0; i--) {
      path.lineTo(
        i,
        // Formula for the sine wave
        80 + math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 15,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => animationValue != oldClipper.animationValue;
}

// Helper classes to hold link data (unchanged)
class _FooterLink {
  final String label;
  final String route;
  const _FooterLink({required this.label, required this.route});
}

class _SocialLink {
  final IconData icon;
  final String url;
  const _SocialLink({required this.icon, required this.url});
}