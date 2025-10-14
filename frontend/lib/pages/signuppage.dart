//import 'package:byte_eat/phone_signup-page.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

import 'phone_signup-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../utils/theme.dart';
import '../widgets/header_widget.dart';

// Import the new animated background file
import '../backgrounds/signup-bg.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';

  // Animations to match login page
  late AnimationController _formAnimationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late AnimationController _visualAnimationController;
  late Animation<double> _sunRiseAnimation;
  late Animation<double> _cloudDriftAnimation;

  final Uri baseUrl = Uri.parse('http://localhost:5000');

  @override
  void initState() {
    super.initState();
    _checkAuthState();

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Visual (sun + clouds) animation
    _visualAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _sunRiseAnimation = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
          parent: _visualAnimationController, curve: Curves.easeInOutSine),
    );
    _cloudDriftAnimation = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(parent: _visualAnimationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });

    _passwordController.addListener(() {
      _evaluatePassword(_passwordController.text);
    });
  }

  void _checkAuthState() async {
    // Remove automatic redirect to prevent signup page from closing immediately
    // Users should be able to access signup page even if they have some auth state
    // Only redirect after successful signup or explicit login
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _visualAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _evaluatePassword(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) score++;

    setState(() {
      _passwordStrength = (score / 5).clamp(0, 1).toDouble();
      if (_passwordStrength <= 0.2) {
        _passwordStrengthLabel = 'Very weak';
      } else if (_passwordStrength <= 0.4) {
        _passwordStrengthLabel = 'Weak';
      } else if (_passwordStrength <= 0.6) {
        _passwordStrengthLabel = 'Fair';
      } else if (_passwordStrength <= 0.8) {
        _passwordStrengthLabel = 'Good';
      } else {
        _passwordStrengthLabel = 'Strong';
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Sign up failed'),
              backgroundColor: Colors.red.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final redirectUrl =
          kIsWeb ? html.window.location.origin : 'io.supabase.flutter://login';

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Define background colors based on theme - making animations more visible
    final Color particleColor = isDark
        ? Theme.of(context).primaryColor.withOpacity(0.8)
        : Theme.of(context).primaryColor.withOpacity(0.6);
    final Color backgroundColor =
        isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA);

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0),
        body: Stack(
          children: [
            // Add the AnimatedBackground widget here, behind the main content.
            AnimatedBackground(
              particleColor: particleColor,
              backgroundColor: backgroundColor,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    // Desktop layout
                    return Column(
                      children: [
                        HeaderWidget(
                          active: HeaderActive.signup,
                          showBack: true,
                          onBack: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                        ),
                        Expanded(child: _buildDesktopLayout()),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return Column(
                      children: [
                        HeaderWidget(
                          active: HeaderActive.signup,
                          showBack: true,
                          onBack: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                        ),
                        Expanded(child: _buildMobileLayout()),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 580),
        child: Material(
          elevation: 32,
          shadowColor: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent, // Make Material widget transparent
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              // Use a more opaque color for better glassmorphism effect.
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.88),
              child: _buildNoScrollFormSection(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 8 : 16),
          _buildCompactLogoSection(),
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 12 : 20),
          Expanded(child: _buildNoScrollFormSection()),
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 8 : 16),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotateAnimation.value,
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width < 600 ? 60 : 80,
                  height: MediaQuery.of(context).size.width < 600 ? 60 : 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, // Using theme color
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logoDP.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 12 : 16),
                Text(
                  'ByteEat',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, // Using theme color
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, // Using theme color
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedVisualSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C3E50),
            const Color(0xFF34495E),
            const Color(0xFF1A252F),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background elements
          _buildAnimatedBackground(),

          // Support button (top-right)
          Positioned(
            top: 20,
            right: 20,
            child: _buildSupportButton(),
          ),

          // Main content card
          Center(
            child: _buildMainContentCard(),
          ),

          // Bottom text
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildBottomText(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _visualAnimationController,
      builder: (context, _) {
        return Stack(
          children: [
            // Floating orbs
            Positioned(
              top:
                  60 + 20 * sin(_visualAnimationController.value * 2 * 3.14159),
              left:
                  40 + 15 * cos(_visualAnimationController.value * 2 * 3.14159),
              child: _buildFloatingOrb(
                  40, const Color(0xFFDAE952).withOpacity(0.3)),
            ),
            Positioned(
              top: 120 +
                  25 *
                      sin(_visualAnimationController.value * 1.5 * 3.14159 + 1),
              right: 60 +
                  20 *
                      cos(_visualAnimationController.value * 1.5 * 3.14159 + 1),
              child: _buildFloatingOrb(
                  30, const Color(0xFF4CAF50).withOpacity(0.2)),
            ),
            Positioned(
              bottom: 200 +
                  30 * sin(_visualAnimationController.value * 3 * 3.14159 + 2),
              left: 80 +
                  25 * cos(_visualAnimationController.value * 3 * 3.14159 + 2),
              child: _buildFloatingOrb(
                  35, const Color(0xFF81C784).withOpacity(0.25)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.headset_mic, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          const Text('Support',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMainContentCard() {
    return AnimatedBuilder(
      animation: _visualAnimationController,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(
              0, 10 * sin(_visualAnimationController.value * 2 * 3.14159)),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/food_background.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Join ByteEat today',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to start exploring delicious food options.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Learn more',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Join our community',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "Create an account to start your food journey with ByteEat.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildNoScrollFormSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subtle glow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to get started with ByteEat',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: isDark ? Colors.grey[300] : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 18),

              // Form fields (no scroll, fixed layout)
              Expanded(
                child: Column(
                  children: [
                    // Form fields in a grid-like layout
                    Expanded(
                      flex: 4,
                      child: _buildNoScrollFormFields(),
                    ),
                    const SizedBox(height: 6),

                    // Password strength (compact) - only show when password doesn't meet criteria
                    if (_passwordController.text.isNotEmpty &&
                        _passwordStrength < 1.0)
                      _buildCompactPasswordStrength(),
                    if (_passwordController.text.isNotEmpty &&
                        _passwordStrength < 1.0)
                      const SizedBox(height: 4),

                    // Terms row (compact)
                    _buildCompactTermsRow(),
                    const SizedBox(height: 8),

                    // Sign up button
                    _buildSignUpButton(),
                    const SizedBox(height: 6),

                    // Divider
                    _buildDivider(),
                    const SizedBox(height: 6),

                    // Social buttons (compact)
                    Expanded(
                      flex: 2,
                      child: _buildCompactSocialButtons(),
                    ),

                    // Login link
                    _buildLoginLink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotateAnimation.value,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logoDP.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ByteEat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoScrollFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // First row - Name and Email
          Row(
            children: [
              Expanded(
                child: _buildCompactInputField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInputField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Please enter an email address';
                    final emailRegex =
                        RegExp(r'^[\w\.-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
                    final allowedProviders = RegExp(
                        r'@(gmail\.com|yahoo\.com|hotmail\.com)$',
                        caseSensitive: false);
                    if (!emailRegex.hasMatch(v))
                      return 'Enter a valid email address';
                    if (!allowedProviders.hasMatch(v))
                      return 'Use a common provider (gmail, yahoo, hotmail)';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row - Password and Confirm Password
          Row(
            children: [
              Expanded(
                child: _buildCompactInputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    final v = value ?? '';
                    if (v.length < 8) return 'At least 8 characters required';
                    if (!RegExp(r'[A-Z]').hasMatch(v))
                      return 'Include at least one uppercase letter';
                    if (!RegExp(r'[0-9]').hasMatch(v))
                      return 'Include at least one number';
                    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v))
                      return 'Include at least one special character';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInputField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPasswordStrength() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barColor = _passwordStrength <= 0.4
        ? Colors.redAccent
        : _passwordStrength <= 0.7
            ? Colors.orange
            : Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[200]),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _passwordStrength,
              child: Container(color: barColor),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _passwordStrengthLabel.isEmpty
              ? 'Use 8+ chars with a mix of letters, numbers, and symbols'
              : 'Password strength: $_passwordStrengthLabel',
          style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCompactTermsRow() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          activeColor: Theme.of(context).primaryColor,
          checkColor: Colors.white,
          fillColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).primaryColor;
            }
            return isDark ? Colors.grey[600]! : Colors.grey[300]!;
          }),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 13),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSocialButtons() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Icons.g_mobiledata_outlined,
          label: 'Sign up with Google',
          backgroundColor: isDark ? Colors.grey[800]! : Colors.white,
          textColor: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
        SizedBox(height: isMobile ? 6 : 8),
        _buildSocialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhoneSignUpPage()),
            );
          },
          icon: Icons.phone_android_outlined,
          label: 'Sign up with Phone',
          backgroundColor: isDark ? Colors.grey[700]! : const Color(0xFFF8F9FA),
          textColor: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildCompactInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (controller == _confirmPasswordController
                  ? _obscureConfirmPassword
                  : _obscurePassword)
              : false,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (controller == _confirmPasswordController
                              ? _obscureConfirmPassword
                              : _obscurePassword)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                    onPressed: () => setState(() {
                      if (controller == _confirmPasswordController) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    }),
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF151515) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.red[300]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.red[300]!, width: 2),
            ),
            errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) =>
                value!.isEmpty ? 'Please enter your name' : null,
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter an email address';
              // Allow common providers or any well-formed email
              final emailRegex = RegExp(r'^[\w\.-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
              final allowedProviders = RegExp(
                  r'@(gmail\.com|yahoo\.com|hotmail\.com)$',
                  caseSensitive: false);
              if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
              if (!allowedProviders.hasMatch(v)) {
                return 'Use a common provider (gmail, yahoo, hotmail)';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              final v = value ?? '';
              if (v.length < 8) return 'At least 8 characters required';
              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                return 'Include at least one uppercase letter';
              }
              if (!RegExp(r'[0-9]').hasMatch(v)) {
                return 'Include at least one number';
              }
              if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) {
                return 'Include at least one special character';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (controller == _confirmPasswordController
                  ? _obscureConfirmPassword
                  : _obscurePassword)
              : false,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF212529),
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (controller == _confirmPasswordController
                              ? _obscureConfirmPassword
                              : _obscurePassword)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () => setState(() {
                      if (controller == _confirmPasswordController) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    }),
                  )
                : null,
            filled: true,
            fillColor:
                isDark ? const Color(0xFF151515) : const Color(0xFFF8F9FA),
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0,
              horizontal: 20.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor, // Using theme color
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 2,
              ),
            ),
            errorStyle: TextStyle(
              color: Colors.red[400],
              fontSize: 13,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 36 : 40,
      child: ElevatedButton(
        onPressed: _isLoading || !_acceptTerms ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        _buildSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Icons.g_mobiledata_outlined,
          label: 'Sign up with Google',
          backgroundColor: Colors.white,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: Colors.grey[300]!,
        ),
        SizedBox(height: isMobile ? 10 : 12),
        _buildSocialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhoneSignUpPage()),
            );
          },
          icon: Icons.phone_android_outlined,
          label: 'Sign up with Phone',
          backgroundColor: const Color(0xFFF8F9FA),
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 34 : 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: textColor, size: isMobile ? 16 : 18),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Simple cloud painter
  Widget _cloud({required double x, required double y, required double scale}) {
    return Positioned(
      left: x,
      top: y,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: 0.85,
          child: Row(
            children: [
              _cloudCircle(34),
              const SizedBox(width: 6),
              _cloudCircle(26),
              const SizedBox(width: 6),
              _cloudCircle(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cloudCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildLoginLink() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          children: <TextSpan>[
            const TextSpan(text: "Already have an account? "),
            TextSpan(
              text: 'Login',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/login');
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final Color barColor = _passwordStrength <= 0.4
        ? Colors.redAccent
        : _passwordStrength <= 0.7
            ? Colors.orange
            : const Color(0xFF4CAF50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _passwordStrength,
              child: Container(color: barColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _passwordStrengthLabel.isEmpty
              ? 'Use 8+ chars with a mix of letters, numbers, and symbols'
              : 'Password strength: $_passwordStrengthLabel',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor, // Using theme color
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor, // Using theme color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
