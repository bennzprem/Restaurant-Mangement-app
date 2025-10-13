import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../ch/user_dashboard_page.dart';
import '../cart_provider.dart';
import '../cart_screen.dart';
import '../location_selection_popup.dart';
import 'dart:ui';
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
  final OrderMode orderMode;

  const HeaderWidget({
    super.key,
    this.active = HeaderActive.none,
    this.showBack = false,
    this.onBack,
    this.orderMode = OrderMode.delivery,
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
          clipBehavior: Clip.none,
          children: [
            // Left side - Logo and Brand Name (Logo now opens ByteBot)
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
                  // Make the logo and brand text clickable to invoke the voice assistant overlay
                  // Logo: opens ByteBot (overlay an InkWell above the video to ensure clicks work on web)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      width: 62,
                      height: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const _LogoVideo(width: 62, height: 60, scale: 1.6),
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () => _showVoiceOverlay(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Brand text: navigates home
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/'),
                      child: Text(
                        'ByteEat',
                        style: TextStyle(
                          fontFamily: 'StoryScript',
                          fontSize:
                              MediaQuery.of(context).size.width < 700 ? 20 : 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: theme.textTheme.displayLarge?.color,
                          fontVariations: const [
                            FontVariation('ital', 0),
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // (hint bubble moved below the header)
                ],
              ),
            ),

            // Center - The new Navigation Bar implementation
            Center(
              child: _DesktopNav(active: active),
            ),

            // Right side - Action Buttons (ByteBot icon removed)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cart Button (hidden on Home page)
                  if (active != HeaderActive.home)
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
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
                          child: Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CartScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                tooltip: 'Cart',
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              // Cart item count badge
                              if (cart.items.isNotEmpty)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '${cart.items.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  // Location Button (only for logged-in users)
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (!auth.isLoggedIn) {
                        return const SizedBox
                            .shrink(); // Hide the button if not logged in
                      }

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const LocationSelectionPopup();
                              },
                            );
                          },
                          icon: Icon(
                            Icons.location_on_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          tooltip: 'Add Location',
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
                  // Removed ByteBot icon (functionality moved to logo)
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
                  // Replace the code above with this new Consumer widget
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      // This logic now handles both logged-in and logged-out states
                      bool isLoggedIn = auth.isLoggedIn;
                      bool isOnSignupPage = active == HeaderActive.signup;
                      IconData iconData = isLoggedIn
                          ? Icons.person_outline
                          : Icons.person_add_alt_1_rounded;
                      String tooltip = isLoggedIn ? 'My Dashboard' : 'Sign Up';
                      VoidCallback onPressed = isLoggedIn
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const UserDashboardPage(),
                                ),
                              )
                          : () => Navigator.of(context)
                              .pushNamed('/signup'); // Navigates to signup page

                      return Container(
                        decoration: BoxDecoration(
                          color: isOnSignupPage
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : (themeProvider.isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: isOnSignupPage ? 3 : 2,
                          ),
                        ),
                        child: IconButton(
                          onPressed: onPressed,
                          tooltip: tooltip,
                          icon: Icon(
                            iconData,
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
            // Assistant hint bubble positioned under the logo on Home page
            if (active == HeaderActive.home)
              const Positioned(
                left: 20,
                top: 72,
                child: _AssistantHintBubble(),
              ),

            // Removed transparent overlay so the default back button works everywhere
          ],
        ),
      ),
    );
  }
}

// A small animated hint bubble placed under the logo on the Home page
class _AssistantHintBubble extends StatefulWidget {
  const _AssistantHintBubble();

  @override
  State<_AssistantHintBubble> createState() => _AssistantHintBubbleState();
}

class _AssistantHintBubbleState extends State<_AssistantHintBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main speech bubble drawn with a custom painter to mimic the reference border
                CustomPaint(
                  painter: _SpeechBubblePainter(
                    fillColor: isDark ? Colors.black : Colors.white,
                    strokeColor: Theme.of(context).primaryColor,
                    radius: 6,
                    strokeWidth: 1.6,
                    notchRadius: 8, // taller notch for a sharper tip
                    notchOffsetX: 22,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.android,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "Hey there! Click the ByteEat logo to chat with ByteBot.",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _dismissed = true),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Small notch elevated from the bubble's border (no base line)
                // Notch is now drawn as part of the speech bubble path itself
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Paints a small upward-pointing triangle with border to attach to the bubble
class _BubbleArrowPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  _BubbleArrowPainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BubbleArrowPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}

// Custom painter to render the speech bubble outline similar to the reference
class _SpeechBubblePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double radius;
  final double strokeWidth;
  final double notchRadius; // small rounded notch size
  final double notchOffsetX; // x offset from left edge

  _SpeechBubblePainter({
    required this.fillColor,
    required this.strokeColor,
    this.radius = 16,
    this.strokeWidth = 2.5,
    this.notchRadius = 0,
    this.notchOffsetX = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final Paint fill = Paint()..color = fillColor;
    final Paint stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    // Build path with top notch protruding from the border
    final Path bubblePath = Path();
    final double left = rect.left;
    final double right = rect.right;
    final double top = rect.top;
    final double bottom = rect.bottom;
    final double r = radius;

    // Start from top-left corner
    bubblePath.moveTo(left + r, top);

    // Top edge until notch start
    final double notchCenterX =
        (left + notchOffsetX).clamp(left + r + 6, right - r - 6);
    // Make the notch sharper by keeping it narrower than its height
    final double notchHalfWidth = notchRadius * 0.5;
    final double notchStartX = notchCenterX - notchHalfWidth;
    final double notchEndX = notchCenterX + notchHalfWidth;

    bubblePath.lineTo(notchStartX, top);
    if (notchRadius > 0) {
      // Draw small upward arc (notch) protruding above the top edge
      bubblePath.quadraticBezierTo(
        notchCenterX,
        top - notchRadius, // elevate
        notchEndX,
        top,
      );
    }
    bubblePath.lineTo(right - r, top);

    // Top-right corner
    bubblePath.arcToPoint(
      Offset(right, top + r),
      radius: Radius.circular(r),
    );

    // Right edge
    bubblePath.lineTo(right, bottom - r);

    // Bottom-right corner
    bubblePath.arcToPoint(
      Offset(right - r, bottom),
      radius: Radius.circular(r),
    );

    // Bottom edge
    bubblePath.lineTo(left + r, bottom);

    // Bottom-left corner
    bubblePath.arcToPoint(
      Offset(left, bottom - r),
      radius: Radius.circular(r),
    );

    // Left edge
    bubblePath.lineTo(left, top + r);

    // Top-left corner
    bubblePath.arcToPoint(
      Offset(left + r, top),
      radius: Radius.circular(r),
    );

    bubblePath.close();

    // Paint fill and stroke
    canvas.drawPath(bubblePath, fill);
    canvas.drawPath(bubblePath, stroke);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
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

class _DesktopNavState extends State<_DesktopNav>
    with TickerProviderStateMixin {
  int _activeIndex = 0;
  int? _hoverIndex;

  // GlobalKeys are used to find the position and size of each navigation item.
  final List<GlobalKey> _keys =
      List.generate(_navItems.length, (_) => GlobalKey());
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
    _activeIndex =
        _navItems.indexWhere((item) => item['active'] == widget.active);
    if (_activeIndex == -1) _activeIndex = -1; // No active navigation item

    _triangleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // A sequence animation to make the triangle dip and then bounce up.
    _triangleAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 15.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 15.0, end: 0.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 2),
    ]).animate(_triangleController);

    // Calculate item positions after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePositions();
      if (_activeIndex >= 0) {
        _moveLine(_activeIndex, isInitial: true);
        _triangleController.forward(
            from: 1.0); // Show triangle in final position initially
      }
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
        newRects[i] = Rect.fromLTWH(
            relativePos.dx, relativePos.dy, box.size.width, box.size.height);
      }
    }
    setState(() {
      _rects = newRects;
    });
  }

  // Animates the top line to the specified item index.
  void _moveLine(int? index, {bool isInitial = false}) {
    if (index == null ||
        index < 0 ||
        index >= _rects.length ||
        _rects[index] == Rect.zero) {
      // Hide the line if the mouse leaves the area
      if (_hoverIndex == null && _activeIndex >= 0) {
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
    final inactiveColor =
        themeProvider.isDarkMode ? Colors.white70 : Colors.black54;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Recalculate positions if the screen is resized
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePositions();
          if (_activeIndex >= 0) {
            _moveLine(_hoverIndex ?? _activeIndex, isInitial: true);
          }
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
                        color:
                            isActive || isHovered ? accentColor : inactiveColor,
                      ) ??
                      TextStyle(
                        color:
                            isActive || isHovered ? accentColor : inactiveColor,
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        child: textWidget,
                      ),
                    ),
                  );
                }),
              ),

              // 4. The animated triangle indicator below the active item
              if (_activeIndex >= 0 && _rects[_activeIndex] != Rect.zero)
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

class GlobalLoadingOverlay extends StatefulWidget {
  final Widget child;
  const GlobalLoadingOverlay({super.key, required this.child});

  @override
  State<GlobalLoadingOverlay> createState() => _GlobalLoadingOverlayState();
}

class _GlobalLoadingOverlayState extends State<GlobalLoadingOverlay>
    with RouteAware {
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteObserver<ModalRoute<void>>().subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteObserver<ModalRoute<void>>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    setState(() => _isLoading = true);
    _hideSoon();
  }

  @override
  void didPopNext() {
    setState(() => _isLoading = true);
    _hideSoon();
  }

  Future<void> _hideSoon() async {
    // Hide shortly after the new page is built
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.08),
              child: Center(
                child: Lottie.network(
                  'https://lottie.host/055193e9-9222-4e91-9cf4-d31c575d1b07/rCCyLAvHHK.lottie',
                  width: 160,
                  height: 160,
                  repeat: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
