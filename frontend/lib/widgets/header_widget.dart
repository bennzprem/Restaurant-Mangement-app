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

// A constant list to define navigation items, their routes, and corresponding enum.
// This makes the navigation bar easier to manage and update.
const _navItems = [
  {'label': 'Home', 'route': '/', 'active': HeaderActive.home},
  {'label': 'Menu', 'route': '/explore-menu', 'active': HeaderActive.menu},
  {'label': 'About', 'route': '/about', 'active': HeaderActive.about},
  {'label': 'Contact', 'route': '/contact', 'active': HeaderActive.contact},
];

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Container(
      // The main header container, now with a solid background color from the theme.
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 700 ? 16 : 36,
          vertical: 14),
      // Using a fixed-height SizedBox to ensure consistent header height.
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            // Left side - Logo and Brand Name (Unchanged)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (showBack)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        onPressed: onBack,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.iconTheme.color,
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                          shape: const CircleBorder(),
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.grey.shade900
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  const _LogoVideo(width: 62, height: 60, scale: 1.6),
                  const SizedBox(width: 10),
                  Text(
                    'ByteEat',
                    style: TextStyle(
                      fontFamily: 'StoryScript',
                      fontSize: MediaQuery.of(context).size.width < 700 ? 20 : 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: theme.textTheme.displayLarge?.color,
                      fontVariations: const [
                        FontVariation('ital', 0),
                        FontVariation('wght', 700),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Center - The new Navigation Bar implementation
            Center(
              child: _DesktopNav(active: active),
            ),

            // Right side - Action Buttons (Unchanged)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => _showVoiceOverlay(context),
                      icon: Icon(
                        Icons.android,
                        color: Theme.of(context).primaryColor,
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
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
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
                        color: Theme.of(context).primaryColor,
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
                            color: Theme.of(context).primaryColor,
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
                          icon: Icon(
                            Icons.person_outline,
                            color: Theme.of(context).primaryColor,
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
      ),
    );
  }
}

/// A stateful widget that builds the new desktop navigation bar.
/// It manages the hover and active states to drive the animations.
class _DesktopNav extends StatefulWidget {
  final HeaderActive active;
  const _DesktopNav({required this.active});

  @override
  State<_DesktopNav> createState() => _DesktopNavState();
}

class _DesktopNavState extends State<_DesktopNav> with TickerProviderStateMixin {
  int _activeIndex = 0;
  int? _hoverIndex;

  // GlobalKeys are used to find the position and size of each navigation item.
  final List<GlobalKey> _keys = List.generate(_navItems.length, (_) => GlobalKey());
  List<Rect> _rects = List.generate(_navItems.length, (_) => Rect.zero);

  // State for the animated top line.
  double _lineLeft = 0.0;
  double _lineWidth = 0.0;

  // Animation controller for the bouncing triangle indicator.
  late AnimationController _triangleController;
  late Animation<double> _triangleAnimation;

  @override
  void initState() {
    super.initState();
    _activeIndex = _navItems.indexWhere((item) => item['active'] == widget.active);
    if (_activeIndex == -1) _activeIndex = 0;

    _triangleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // A sequence animation to make the triangle dip and then bounce up.
    _triangleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 15.0).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 15.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 2),
    ]).animate(_triangleController);

    // Calculate item positions after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePositions();
      _moveLine(_activeIndex, isInitial: true);
      _triangleController.forward(from: 1.0); // Show triangle in final position initially
    });
  }
  
  // Recalculates the positions of nav items. This is crucial for responsiveness.
  void _calculatePositions() {
    if (!mounted) return;
    final navBarContext = context;
    if (navBarContext.findRenderObject() == null) return;
    
    final navBarBox = navBarContext.findRenderObject() as RenderBox;
    List<Rect> newRects = List.from(_rects);

    for (int i = 0; i < _keys.length; i++) {
      final context = _keys[i].currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final relativePos = navBarBox.globalToLocal(position);
        newRects[i] = Rect.fromLTWH(relativePos.dx, relativePos.dy, box.size.width, box.size.height);
      }
    }
    setState(() {
      _rects = newRects;
    });
  }

  // Animates the top line to the specified item index.
  void _moveLine(int? index, {bool isInitial = false}) {
    if (index == null || index < 0 || index >= _rects.length || _rects[index] == Rect.zero) {
        // Hide the line if the mouse leaves the area
        if(_hoverIndex == null) { 
           final activeRect = _rects[_activeIndex];
           setState(() {
             _lineLeft = activeRect.left;
             _lineWidth = activeRect.width;
           });
        }
        return;
    }
    final rect = _rects[index];
    if (isInitial) {
      _lineLeft = rect.left;
      _lineWidth = rect.width;
    } else {
      setState(() {
        _lineLeft = rect.left;
        _lineWidth = rect.width;
      });
    }
  }

  // Handles clicking a navigation item.
  void _setActiveIndex(int index) {
    if (_activeIndex != index) {
      setState(() {
        _activeIndex = index;
      });
      _moveLine(index);
      _triangleController.forward(from: 0.0);
    }
    Navigator.pushNamed(context, _navItems[index]['route'] as String);
  }

  @override
  void dispose() {
    _triangleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = theme.primaryColor;
    final inactiveColor = themeProvider.isDarkMode ? Colors.white70 : Colors.black54;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Recalculate positions if the screen is resized
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePositions();
          _moveLine(_hoverIndex ?? _activeIndex, isInitial: true);
        });

        return SizedBox(
          width: 750, // Fixed width to match the example design
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Top line track (the faint background line)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: accentColor.withOpacity(0.2),
                ),
              ),

              // 2. The animated top line that follows hover/active state
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                top: 0,
                left: _lineLeft,
                child: Container(
                  width: _lineWidth,
                  height: 2,
                  color: accentColor,
                ),
              ),

              // 3. The row of navigation items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = index == _activeIndex;
                  final isHovered = index == _hoverIndex;

                  final textStyle = theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.bold,
                    color: isActive || isHovered ? accentColor : inactiveColor,
                  ) ??
                  TextStyle(
                    color: isActive || isHovered ? accentColor : inactiveColor,
                    fontWeight: FontWeight.bold,
                  );
                  
                  Widget textWidget = Text(
                    (item['label'] as String).toUpperCase(),
                    style: textStyle,
                  );

                  // Apply a slight scale transform to the active item
                  if (isActive) {
                    textWidget = Transform.scale(scale: 1.1, child: textWidget);
                  }

                  return MouseRegion(
                    key: _keys[index],
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) {
                      setState(() => _hoverIndex = index);
                      _moveLine(index);
                    },
                    onExit: (_) {
                      setState(() => _hoverIndex = null);
                      _moveLine(_activeIndex);
                    },
                    child: GestureDetector(
                      onTap: () => _setActiveIndex(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        child: textWidget,
                      ),
                    ),
                  );
                }),
              ),
              
              // 4. The animated triangle indicator below the active item
              if (_rects[_activeIndex] != Rect.zero)
                AnimatedBuilder(
                  animation: _triangleAnimation,
                  builder: (context, child) {
                    return Positioned(
                      // Position the triangle based on the calculated position of the active item.
                      left: _rects[_activeIndex].center.dx - 10,
                      bottom: 0, // Positioned at the bottom of the nav bar
                      child: Transform.translate(
                        offset: Offset(0, _triangleAnimation.value),
                        child: child!,
                      ),
                    );
                  },
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _TrianglePainter(color: accentColor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A custom painter to draw the triangle indicator.
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
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
    final Color background =
        filled ? green : (isDark ? Colors.black : Colors.white);
    final Color textColor =
        filled ? Colors.black : (isDark ? Colors.white : Colors.black);

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
  final double scale;
  const _LogoVideo(
      {required this.width, required this.height, this.scale = 1.8});

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